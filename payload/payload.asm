; the idea of the second payload is writing a letter code on the screen instead of whatever the fuck i had tried to do previously
; obviously this has to be done for a single pokemon at a time but eh who cares

; version numbers (used for conditional compiling)
DEF RB_EN = 1
DEF RB_EU = 2

; fail if no version is specified
IF DEF(VERSION) == 0
FAIL "No build specified"
ENDC

IF   VERSION == RB_EN
	
ELIF VERSION == RB_EU
	FAIL "not implemented yet"
ELSE
	FAIL "invalid build version"
ENDC

INCLUDE "./payload/hardware.asm"

SECTION "", ROM0
; LOAD "main", WRAMX[$D901]

; did you know i'm an expert in computer security? i advise you change all your password to be the same. this way it's statistically less likely for one of them to be guessed
def random_addr_to_overwrite = $D888 ; this is actually the encounter table. have fun

; magic numbers
def hTextID = $8c
def letter_a = $80
def newline_char = $55
def terminator_char = $57

; addresses
def wBoxMons = $DA96
def PrintText = $3C49
def BankSwitch = $35D6
def YesNoChoice = $35EC
def wCurrentMenuItem = $CC26
def DisplayTextIDInit = $7096


; simplified version since we don't have the full symbol table
MACRO farcall
	ld B, 1
	ld HL,\1
	call BankSwitch
ENDM

; we don't have push with 8b regs so here's a simple workaround (we push the 16bit equivalent, then go back by one)
; not actually used but felt like leaving it here bc i like it for some reason
MACRO pusha
	push AF
	inc sp
ENDM
MACRO popa
	dec sp
	pop AF
ENDM



; alr dumb idea time
; we don't have any direct way to interact with PC, so we can't really store its value for later use
; we can't CALL other parts of the program either, as that would require us to have an _absolute jump_ and we'd thus need to know where we are placing the program in memory
; this is bad bc my guiding principle is that you should be able to use this payload regardless of setup (and thus regardless of memory address)
; the RST vectors aren't useful either as they just call themselves without ever returning
; BUT there's a single interrupt in the header which simply RETurns as soon as it is called. thus we can push the PC on the stack this way
; (could've just as well JPed to any RET in ROM, but i prefer this tbh)
; TODO: we do some calls later in the code. we can just reuse those i guess
BEGINNING::
call $0060
dec sp
dec sp

; TODO: instead of PUSHing we could write directly in memory maybe. freeing the stack would allow for some other optimisations

; a pkmn is made of 33B. we have 64 possible characters => 6b of info => need to print ceil(33 * 8 / 6) = 44 characters
; B1: aaaaaabb
; B2: bbbbcccc
; B3: ccdddddd
; => q = (B1 >> 2) & 0b0011_1111
; => b = (B1 & 0b0000_0011 << 4) + (B2 & 0b1111_0000 >> 4)
; => c = (B2 & 0b0000_1111 << 2) + (B3 & 0b1100_0000 >> 6)
; => d = (B3 & 0b0011_1111)
; repeat 11 times
GENERATE_STRING_ON_STACK::
; init
ld HL,wBoxMons
; paired register load
ld DE,(12 << 8)+3
; ld D,11+1			; the +2 is for easier alignment later. this way we end up PUSHing 48 chars (=> 96 bytes)

charloop:
; first char
ld A,[HL]
rra					; remember to not put a space, otherwise it becomes `RR A` and takes up twice as much space
rra
and A,%0011_1111
push AF				; since the characters are being PUSHed, when decoding we'll have to read them backwards (TODO: how bad can PUSHing be?)
; second char
ld A,[HL+]			; \
rla					; |
rla					; |__ last two bits of B1 get shifted left by 4
rla					; |
rla					; |
and A,%0011_0000	; /
ld B,A				; we're going to add it later to the other part of the char code
ld A,[HL]			; \
rra					; |
rra					; |__ first half of B2 shifted right (TODO: possibility for optimisation?)
rra					; |
rra					; |
and A,%0000_1111	; /
add A,B				; add it to the first part computed earlier
push AF
; third char
ld A, [HL+]			; \
rla					; |__ first part (second half of B2)
rla					; |
and A,%0011_1100	; /
ld B,A				; store for later computation
ld A,[HL]			; \
rra					; |
rra					; |
rra					; |__ two most significat digits of B3. repeats 6 times RR A
rra					; |
rra					; |
rra					; |
and A,%0000_0011	; /
add A,B
push AF
; last char
ld A,[HL+]
and A,%0011_1111
push AF
dec D
jr nz, charloop

; format of string is:
; 00 (first characters)
; 4F (next characters)		; we skip this line. looks ugly but works
; 55 (next characters, repeat this last line as needed)
; 57 (string terminator that asks for button press)
PRINT_STRING::
ld HL, random_addr_to_overwrite	; TODO: this load is done twice, is there really no way of optimising it?
xor A							; \__ string initiator
ld [HL+], A						; /

; ld E,3						; \			; this is unnecessary as it's done with the paired load above
printloop_pt2:					; |---- 3 lines, 16 chars each
ld B,16							; /

printloop:
pop AF							; \
add A,letter_a					; |--- get the char off the stack, convert it to a printable, and put it on the string
ld [HL+],A						; /
dec B
jr nz,printloop

ld A, newline_char
ld [HL+],A
dec E
jr nz, printloop_pt2

; 
; if HL wasn't increased above we could just INC [HL] twice and that would save a byte. life is evil sometimes
ld A,terminator_char					; TODO: maybe just change the last newline_char to this by addition
ld [HL+],A


ENGINE_CALLS::
; TODO: maybe this value in RAM is already one? idk
ld A,1
ldh [hTextID],A						; FF8C
; farcall DisplayTextIDInit: call DisplayTextIDInit which is outside of the current ROM bank (need to check argument (0 is ID for start menu))
inc b								; equivalent to `ld B, 1` as B was zero before
ld HL,DisplayTextIDInit
call BankSwitch

ld HL,random_addr_to_overwrite
call PrintText						; 3C49

; ask for next pokemon
call YesNoChoice
ld A, [wCurrentMenuItem]
; BC is always zero after this call. this info allows us to save one byte later on by loading to C instead of BC
; call stack for YesNoChoice goes something like:
; call YesNoChoice
;   jr DisplayYesNoChoice
;     jp LoadScreenTilesFromBuffer1
;       call CopyData
;         A, B, C = 0
;       A = 1
;       ret

; get back the PC we PUSHed on the stack at the beginning of the program
; do it here so that we do it regardless of outcome of yes/no
; if outcome is no we can just not use it and return it, if it is yea we use it
; also if it wasn't POPped here the RET would go back to the start which is kinda catastrophic
pop HL

; if YesNoChoice == 0 return
and A
ret nz

; if YesNoChoice == 1:
; ahhh self-modifying code. what could go wrong?
; first, calculate the address of the byte to modify into HL. then 16bit-add 33 (size of one mon in the box) to it
DEF codediff = ((GENERATE_STRING_ON_STACK - BEGINNING) - 2) 
ASSERT codediff <= 0xFF
ld C, codediff				; \___ HL (= start of the program) += (difference between start of the program and address of mon data, that we luckily only use once)
add HL, BC					; /

ld A,[HL]				; word x = *HL
add A,33				; low(x) += 33 (number of bytes for one pokemon in the box)
ld [HL+],A				; store changed value of HL
ret nc					; if there wasn't an overflow we dont need to do any further operations
inc [HL]				; if there _was_ an overflow, we increment the most significant byte by one to account for that. we already moved the pointer to it with the LD [HL+], A

ret

