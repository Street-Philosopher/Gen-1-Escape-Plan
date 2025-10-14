; the idea of the second payload is writing a letter code on the screen instead of whatever the fuck i had tried to do previously
; obviously this has to be done for a single pokemon at a time but eh who cares

; version numbers (used for conditional compiling)
DEF RB_EN = 1
DEF RB_EU = 2
DEF GS_EN = 3

; fail if no version is specified
IF DEF(VERSION) == 0
FAIL "No build specified"
ENDC

INCLUDE "./payload/hardware.asm"

; needed for it to compile. this section will be placed in WRAM at address 0xD901
; we don't really care since we only use relative jumps, but still
SECTION "", ROM0
LOAD "main", WRAMX[$D901]

; did you know i'm an expert in computer security? i advise you change all your password to be the same. this way it's statistically less likely for one of them to be guessed
def RANDOM_ADDRESS_TO_OVERWRITE = $D887 ; this is actually the encounter table. have fun

def hTextID = $8c
def NEWLINE = $55
def TEXT_END = $57
def BOX_DATA = $da96		; check this address i wrote it from memory
def PrintText = $3c49
def BankSwitch = $35d6
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



; TODO: by PUSHing the PC we could see where we are and thus change the starting address of the copied data to go to the next pkmn, regardless of implementation

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
ld hl,BOX_DATA
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
ld e,6				; |
.repeat_rra:		; |
rra					; |__ two most significat digits of B3. repeats 6 times RR A
dec e				; |
jr nz, .repeat_rra	; |
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
print_string:
ld hl, RANDOM_ADDRESS_TO_OVERWRITE
xor a							; \__ string initiator
ld [hli], a						; /

ld b,3							; \
printloop_pt2:					; |---- 3 lines, 16 chars each
ld c,16							; /

printloop:
pop af							; \
add a,$80						; |--- get the char off the stack, convert it to a printable, and put it on the string
ld [hli],a						; /
dec c
jr nz,printloop

ld a, NEWLINE
ld [hli],a
dec b
jr nz, printloop_pt2

ld a,TEXT_END					; TODO: maybe just change the last NEWLINE to this by addition
ld [hli],a



; engine calls
ld a,1
ldh [hTextID],a						; FF8C
farcall DisplayTextIDInit			; ld b,1; ld hl,$7096; call 35D6 (need to check argument (0 is ID for start menu))
ld hl,RANDOM_ADDRESS_TO_OVERWRITE
call PrintText						; 3C49
ret


; METODO 1,5: fare tutto in HL? (o in un altro regsitro 16b)
; DE <- primo byte /\ secondo byte
; char = D & 0b1111_1100
; now DE is equal to aaaaaabb_bbbbcccc
; DE << 2
; E = byte successivo
; DE << 4
; ripeti da assegnazione a char


