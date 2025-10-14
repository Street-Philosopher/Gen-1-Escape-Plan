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
def random_addr_to_overwrite = $D887 ; this is actually the encounter table. have fun

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
	ld b, 1
	ld hl,\1
	call BankSwitch
ENDM

; we don't have push with 8b regs so here's a simple workaround (we push the 16bit equivalent, then go back by one)
; not actually used but felt like leaving it here bc i like it for some reason
MACRO pusha
	push af
	inc sp
ENDM
MACRO popa
	dec sp
	pop af
ENDM



; alr dumb idea time
; we don't have any direct way to interact with PC, so we can't really store its value for later use
; we can't CALL other parts of the program either, as that would require us to have an _absolute jump_ and we'd thus need to know where we are placing the program in memory
; this is bad bc my guiding principle is that you should be able to use this payload regardless of setup (and thus regardless of memory address)
; the RST vectors aren't useful either as they just call themselves without ever returning
; BUT there's a single interrupt in the header which simply RETurns as soon as it is called. thus we can push the PC on the stack this way
; (could've just as well JPed to any RET in ROM, but i prefer this tbh)
BEGINNING::
call $0060
dec sp
dec sp

; a pkmn is made of 33B. we have 64 possible characters => 6b of info => need to print ceil(33 * 8 / 6) = 44 characters
; B1: aaaaaabb
; B2: bbbbcccc
; B3: ccdddddd
; => a = (B1 >> 2) & 0b0011_1111
; => b = (B1 & 0b0000_0011 << 4) + (B2 & 0b1111_0000 >> 4)
; => c = (B2 & 0b0000_1111 << 2) + (B3 & 0b1100_0000 >> 6)
; => d = (B3 & 0b0011_1111)
; repeat 11 times
GENERATE_STRING_ON_STACK::
; init
ld hl,wBoxMons
ld c,11+1			; the +2 is for easier alignment later. this way we end up PUSHing 48 chars (=> 96 bytes)

charloop:
; first char
ld a,[hl]
rra					; remember to not put a space, otherwise it becomes `RR A` and takes up twice as much space
rra
and a,%0011_1111
push af				; since the characters are being PUSHed, when decoding we'll have to read them backwards (TODO: how bad can PUSHing be?)
; second char
ld a,[hli]			; \
rla					; |
rla					; |__ last two bits of B1 get shifted left by 4
rla					; |
rla					; |
and a,%0011_0000	; /
ld b,a				; we're going to add it later to the other part of the char code
ld a,[hl]			; \
rra					; |
rra					; |__ first half of B2 shifted right (TODO: possibility for optimisation?)
rra					; |
rra					; |
and a,%0000_1111	; /
add a,b				; add it to the first part computed earlier
push af
; third char
ld a, [hli]			; \
rla					; |__ first part (second half of B2)
rla					; |
and a,%0011_1100	; /
ld b,a				; store for later computation
ld a,[hl]			; \
rra					; |
rra					; |
rra					; |__ two most significat digits of B3. repeats 6 times RR A
rra					; |
rra					; |
rra					; |
and a,%0000_0011	; /
add a,b
push af
; last char
ld a,[hli]
and a,%0011_1111
push af
dec c
jr nz, charloop

; format of string is:
; 00 (first characters)
; 4F (next characters)		; we skip this line. looks ugly but works
; 55 (next characters, repeat this last line as needed)
; 57 (string terminator that asks for button press)
PRINT_STRING::
ld hl, random_addr_to_overwrite
xor a							; \__ string initiator
ld [hli], a						; /

ld b,3							; \
printloop_pt2:					; |---- 3 lines, 16 chars each
ld c,16							; /

printloop:
pop af							; \
add a,letter_a					; |--- get the char off the stack, convert it to a printable, and put it on the string
ld [hli],a						; /
dec c
jr nz,printloop

ld a, newline_char
ld [hli],a
dec b
jr nz, printloop_pt2

ld a,terminator_char					; TODO: maybe just change the last newline_char to this by addition
ld [hli],a


ENGINE_CALLS::
ld a,1
ldh [hTextID],a						; FF8C
farcall DisplayTextIDInit			; call a function outside of the current ROM bank (need to check argument (0 is ID for start menu))
ld hl,random_addr_to_overwrite
call PrintText						; 3C49

; ask for next pokemon
call YesNoChoice
ld a, [wCurrentMenuItem]

; get back the PC we PUSHed on the stack at the beginning of the program
; do it here so that we do it regardless of outcome of yes/no
; if outcome is no we can just not use it and return it, if it is yea we use it
pop hl

; if YesNoChoice == 0 return
and a
ret nz

; if YesNoChoice == 1
; ahhh self-modifying code. what could go wrong?
; first, calculate the address of the byte to modify into HL. then 16bit-add 33 (size of one mon in the box) to it
ld bc, (GENERATE_STRING_ON_STACK - BEGINNING) - 2		; \___ HL (= start of the program) += (difference between start of the program and address of mon data, that we luckily only use once)
add hl, bc												; /

ld a,33					; 
ld b, [hl]				; word x = *HL
add a,b					; low(x) += 33 (number of bytes for one pokemon in the box)
ld [hli],a				; store changed value of HL
ret nc					; if there wasn't an overflow we dont need to do any further operations
inc [hl]				; if there _was_ an overflow, we increment the most significant byte by one to account for that. we already moved the pointer to it with the LD [hli], a

ret

