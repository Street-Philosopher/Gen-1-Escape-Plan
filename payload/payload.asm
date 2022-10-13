; i'm sorry to whoever wants to read this code

RB_EN = 1
RB_EU = 2
GS_EN = 3

; fail if no version is specified
IF DEF(VERSION) == 0
	FAIL "No build specified"
ENDC

SECTION "", ROM0	; RGBASM doesn't let me do cool things so I have to put this here
LOAD "main", WRAMX[$D901]

; TODO: this could be maybe potentially be optimised by removing all the $FF when writing to VRAM which would also double the information density, which would require a rewrite of the program
; i don't know if you can notice the slow realisation that the idea is not that easy after all, in the comment above

; first box
; (33*20) + 1 bytes of information

; program constants
TILES_TO_WRITE = $53
BLACK_SQUARE   = TILES_TO_WRITE + 1 ; index in memory of the full black tile
WHITE_SQUARE   = BLACK_SQUARE + 1   ; index in memory of the full white tile

; other constants
VBLANK_START = $91

; memory addresses
TILE_DATA = $9000
MAP_DATA  = $9800
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

; preparation before changing stuff
	di
VBlankCheck:
	ldh A,[$44]	 	; vertical position of scanline
	; CP is just SUB, except it doesn't store a result. we are checking when A-$91 == 0.
	; since we need to set A to zero afterwards anyways we can use SUB, which does the same AND stores the result (zero)
	sub A, VBLANK_START
	jr nz,VBlankCheck

	; xor A,A not needed
	ldh [$40],A		; turn off LCD
; end of prep

; this will overwrite the current map data to show on screen a frame (black and white) containing all different tiles
; "HL" will hold the VRAM address containing current tile data, so we can overwrite the map at our likings
; "C" is the tile number we want to write next
; "A" contains either the white frame or the black square tile numbers
; "B" and "D" are used as counters
;
; drawing (W means white, D means data):
;	WWWWWWWWWWWW
;	WDDDDDDDDDDW
;	WDDDDDDDDDDW
;	WDDDDDDDDDDW
;	WDDDDDDDDDDW
;	WDDDDDDDDDDW
;	WDDDDDDDDDDW
;	WDDDDDDDDDDW
;	WDDDDDDDDDDW
;	WDDDDWWWWWWW
;	WWWWWWWWWWWW
;
fillScreen:
	ld HL,MAP_DATA
IF VERSION == RB_EN || VERSION == RB_EU
	ld BC,$640C
	; ld B,$64			; to make the code centered in the screen, and to compensate for off-screen tiles
	; ld C,$0C
ELIF VERSION == GS_EN
	ld BC,$840C
	; ld B,$84
	; ld C,$0C
ENDC
	ld A,BLACK_SQUARE
fs_loop1:				; start by adding black squares to make the frame
	ldi [HL],A
	dec B
	jr nz,fs_loop1
	; draws top line of frame
	inc A	; equivalent to "ld A,WHITE_SQUARE", bc WHITE_SQUARE is BLACK_SQUARE + 1
fs_loop2:
	ldi [HL],A
	dec C
	jr nz,fs_loop2

	ld B,8		; number of lines in the code
	; "ld C,0" not necessary because C is already zero
	; C will contain the current tile, so it will get increased whenever we need to place a new one
dataLoop:	; repeated for each line
	ld DE,$140A
	; ld D,20
	; ld E,10
	dec A		; does "ld A,BLACK_SQUARE"
fs_loop3:						; new line, by writing black squares until we're in the right position
	ldi [HL],A
	dec D
	jr nz,fs_loop3
	inc A				; ld A,WHITE_SQUARE
	ldi [HL],A			; white tile for frame

	; for 10 data tiles in the line
fs_loop4:
	ld [HL],C
	inc HL
	inc C							; next tile
	dec E							; decrease line tile counter
	jr nz,fs_loop4
	
	ldi [HL],A			; one white tile for right frame

	dec B
	jr nz,dataLoop

	dec A				; ld A,BLACK_SQUARE

IF VERSION == RB_EN || VERSION == RB_EU
	; the last line is different, having only 4 tiles we need to show. for this reason it has a separate part of the function
	ld B,20
fs_loop6:
	ldi [HL],A
	dec B
	jr nz,fs_loop6

	inc A
	ldi [HL],A

	ld A,C

	ldi [HL],A
	inc A
	ldi [HL],A
	inc A						; 4 tiles, then a white tile
	ldi [HL],A
	inc A
	ldi [HL],A

	ld A,WHITE_SQUARE
	ld BC,$0714		; load 7 in B and 20 in C, by pairing two registers we save a load
	; ld B,7
	; ld C,20
fs_loop7:						; since we only have 4 data tiles, we fill the other 6 tiles in the line with white frame tiles
	ldi [HL],A
	dec B
	jr nz,fs_loop7

	; last new line
	dec A		; ld A,BLACK_SQUARE
fs_loop8:
	ldi [hl],a
	dec c
	jr nz,fs_loop8
	
	; bottom row of the frame
	ld bc,$0C84
	; ld B,12
	; ld C,$84
	inc A; ld a,WHITE_SQUARE
fs_loop69:
	ldi [HL],A
	dec B
	jr nz,fs_loop69
	; after the white frame, we cover the rest of the screen with black tiles

ELIF VERSION == GS_EN
	ld bc,$1484
	; ld B,14
	; ld C,0x84
fs_loop69:
	ldi [HL],A
	dec B
	jr nz,fs_loop69

	ld b,12
	inc A;ld A,WHITE_SQUARE
fs_loop_idk:
	ldi [hl],a
	dec b
	jr nz,fs_loop_idk
ENDC
	
	; after the white frame, we cover the rest of the screen with black tiles
	dec A;ld A,BLACK_SQUARE
final_loop:
	ldi [HL],A
	dec C
	jr nz,final_loop
end_fs:


; here "D" is used as a counter for the tiles we still have to overwrite
; "HL" contains the VRAM address containing sprite data, the one we'll need to overwrite
; "BC" contains the address containing box data
; "E" is also used as a counter. it counts the number of bytes in each tile (8)
; this overwrites the tile data with our data
overwriteStuff:
IF VERSION == GS_EN
	; turn on SRAM, because in GSC box data is stored there
	ld a,1
	ld [$6000],a
	ld a,$0A
	ld [$0000],a
	ld a,1
	ld [$4000],a
ENDC

	ld D,TILES_TO_WRITE			; including 0
	ld HL,TILE_DATA
	ld BC,BOX_DATA
overwriteStuffLoop2:
	ld E,8			; every tile has 8 bytes
overwriteStuffLoop:
	ld A,[BC]			;
	inc BC				; current_byte = *(data_to_read++)
	ldi [HL],A			; *(graphics_ptr++) = current_byte
	ld A,$FF			; *(graphics_ptr++) = $FF          // writing a byte and then $FF will creeate a line with the binary representation of that first byte
	ldi [HL],A			;
	dec E
	jr nz,overwriteStuffLoop	; will loop for all bytes in the tile
	dec D
	jr nz,overwriteStuffLoop2	; will loop for every tile in the code

	; an entire column will be just for the number. this saves three bytes
	writeMonNumber:
	ld BC,$0810
	; ld B,8
	wmn_black_loop:
	ld A,[MON_NUMBER]	; TODO: this is an immediate. maybe moving it before everything else and adding instead of loading will do something
	ldi [HL],A
	ld A,$FF
	ldi [HL],A
	dec B
	jr nz,wmn_black_loop

; overwrites the white and black tiles of the frame to be full-white or full-black
	; ld A,$FF is not needed because we loaded above
overwrite_5455:
	; ld C,$10 is done with the paired loop above. the second time we write $100 bytes but its ok because we overwrite unused tiles
loop1:				; write 16 (size in bytes of a tile) times ff to create black tile, then adds one to write 00, which creates white tile. this way i don't have to rewrite the function
	ldi [HL],A
	dec C
	jr nz,loop1
	
	; adds one, and jumps back to the start if there was an overflow (a=0). this way we only jump the first time (a=$FF), AND we get the correct value for "a" to write
	; O P T I M I S A T I O N S
	inc A
	jr z,overwrite_5455
end_overwrite:


IF VERSION == RB_EN || VERSION == RB_EU
	; turn the screen back on but keep sprites disabled
	ld A,$E1
	ldh [$40],A
ELIF VERSION == GS_EN
	; turn SRAM back off and re-enable LCD with no sprites. uses different LCD settings 
	; A is already zero, so 'xor A,A' is not necessary
	ld [$0000],A
	ld A,$E3
	ldh [$40],A
ENDC
	
	reti
