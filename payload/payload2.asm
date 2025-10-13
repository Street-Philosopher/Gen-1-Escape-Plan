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

; other constants
DEF VBLANK_START = $91

; did you know i'm an expert in computer security? i advise you change all your password to be the same. this way it's statistically less likely for one of them to be guessed
def RANDOM_ADDRESS_TO_OVERWRITE = "lol"

; memory addresses
DEF TILE_DATA = $9000
DEF MAP_DATA  = $9800
IF   VERSION == RB_EN
	def BOX_DATA   = $DA96
	def MON_NUMBER = $DA80
ELIF VERSION == RB_EU
	def BOX_DATA   = $DA9B
	def MON_NUMBER = $DA85
ELIF VERSION == GS_EN
	def BOX_DATA   = $AD82
	def MON_NUMBER = $AD6C
ELSE
	FAIL "Invalid build version"
ENDC

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

; format of string has to be:
; 00 (first characters)
; 4F (next characters)
; 55 (next characters, repeat this last line as needed)
; 57 (string terminator that asks for button press)



; si può fare che se premi A ti manda al codice successivo (oppure: sovrascrivi automaticamente un byte che ti mandi al pkmn successivo)
;
; charset starts at tile 80 (addr 8800) and end at BF (addr 8BF0)
; le stringhe iniziano con 00 e finiscono con 57
; sovrascrivi ultimi 6 tile con i numeri (inizia a F7)
; un pkmn sono 33B. abbiamo 64 caratteri => 6b di info => servono ceil(33 * 8 / 6) = 44 caratteri
; schermo GB sono 13x11 (X/Y) tile
; BBBBBBBBBBBBB
; BBBBBBBBBBBBB
; BBBBBBBBBBBBB
; BBCCCCCCCCCBB
; BBCCCCCCCCCBB
; BBCCCCCCCCCBB
; BBCCCCCCCCCBB
; BBCCCCCCCC/BB
; BBBBBBBBBBBBB
; BBBBBBBBBBBBB
; BBBBBBBBBBBBB
;
; due bitmask
; b1 = 0b1111_1100
; b2 = 0b0000_0011
; si muovono di volta in volta per farti vedere il byte da leggere e il byte successivo da leggere
; fai AND con il byte di dati da stampare, e poi rimanda al tile
; sono pur sempre solo 4 i carattero da leggere prima che le mask tornino allo stato iniziale (6-12-18-24, quindi 3B), quindi magari conviene dscriverli direttamente cosi

; METODO 1
; B1: aaaaaabb
; B2: bbbbcccc
; B3: ccdddddd
; => a = (B1 >> 2) & 0b0011_1111
; => b = (B1 & 0b0000_0011 << 4) + (B2 & 0b1111_0000 >> 4)
; => c = (B2 & 0b0000_1111 << 2) + (B3 & 0b1100_0000 >> 6)
; => d = (B3 & 0b0011_1111)
; ripeti 11 volte

; init
ld hl,BOX_DATA
ld c,11+1			; the +2 is for easier alignment later. this way we end up PUSHing 48 chars (=> 96 bytes)

charloop:
; first char
ld a,[hl]
rr a
rr a
and a,%0011_1111
push af				; since the characters are being PUSHed, when decoding we'll have to read them backwards (TODO: how bad can PUSHing be?)
; second char
ld a,[hli]			; \
rl a				; |
rl a				; |__ last two bits of B1 get shifted left by 4
rl a				; |
rl a				; |
and a,%0011_0000	; /
ld b,a				; we're going to add it later to the other part of the char code
ld a,[hl]			; \
rr a				; |
rr a				; |__ first half of B2 shifted right (TODO: possibility for optimisation?)
rr a				; |
rr a				; |
and a,%0000_1111	; /
add a,b				; add it to the first part computed earlier
push af
; third char
ld a, [hli]			; \
rl a				; |__ first part (second half of B2)
rl a				; |
and a,%0011_1100	; /
ld b,a				; store for later computation
ld a,[hl]			; \
rr a				; |
rr a				; |
rr a				; |__ two most significat digits of B3. TODO: can this be optimised with a loop?
rr a				; |
rr a				; |
rr a				; |
and a,%0000_0011	; /
add a,b
push af
; last char
ld a,[hli]
and a,%0011_1111
push af
dec c
jr nz, charloop

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
jr nz printloop_pt2

ld a,TEXT_END					; TODO: maybe just change the last NEWLINE to this by addition
ld [hli],a

; assembled instructions (placed at d901) 3E01E08C0601219670CDD6352114D9CD493CC9
ldh [hTextID],x					; FF8C
farcall DisplayTextIDInit		; ld b,1; ld hl,$7096; call 35D6 (need to check argument (0 is ID for start menu))
ld hl,RANDOM_ADDRESS_TO_OVERWRITE
call PrintText
ret


; METODO 1,5: fare tutto in HL? (o in un altro regsitro 16b)
; DE <- primo byte /\ secondo byte
; char = D & 0b1111_1100
; now DE is equal to aaaaaabb_bbbbcccc
; DE << 2
; E = byte successivo
; DE << 4
; ripeti da assegnazione a char


; METODO 2
; la roba delle bismask non mi convince


























CLEANUP:
; reset any important states and return
IF VERSION == RB_EN || VERSION == RB_EU
	; turn the screen back on but keep sprites disabled, so the only thing we see is the background we turned into the code
	ld A,$E1
	ldh [rLCDC],A
ELIF VERSION == GS_EN
	; turn SRAM back off and re-enable LCD with no sprites. this version uses slightly different LCD settings than the one above
	; A is already zero from the previous operation, so 'xor A,A' is not necessary
	ld [rRAMG],A
	ld A,$E3
	ldh [rLCDC],A
ENDC
	; re-enable interrupts and return
	reti


END_PROGRAM:
txt:
db $00, $80, $83, $82, $85, $87, $57, $50
