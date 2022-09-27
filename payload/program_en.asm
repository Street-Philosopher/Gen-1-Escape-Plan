; TODO: this could be maybe potentially be optimised by removing all the 0xFF when writing to VRAM which would also double the information density, which would require a rewrite of the program
; i don't know if you can notice the slow realisation that the idea is not that easy after all, in the comment above

; i'm sorry to whoever wants to read this code

; first box
; (33*20) + 1 bytes of information

; tiles stuff
TILES_TO_WRITE = 0x53
BLACK_SQUARE = TILES_TO_WRITE + 1 ; index in memory of the full black tile
WHITE_SQUARE = BLACK_SQUARE + 1   ; index in memory of the full white tile

; memory addresses
TILE_DATA = 0x9000
MAP_DATA  = 0x9800
BOX_DATA  = 0xDA96
MON_NUMBER= 0xDA80

VLANK_START = 0x91

; preparation before changing stuff
	di
VBlankCheck:
	ldh A,(0x44)	 	; vertical position of scanline
	; CP is just SUB, except it doesn't store a result. we are checking when A-0x91 == 0.
	; since we need to set A to zero afterwards anyways we can use SUB, which does the same AND stores the result (zero)
	sub A, VLANK_START
	jr nz,VBlankCheck

	; xor A,A not needed
	ldh (0x40),A			; turn off LCD
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
	ld BC,0x640C
	; ld B,0x64			; to make the code centered in the screen, and to compensate for off-screen tiles
	; ld C,0x0c
	ld A,BLACK_SQUARE
fs_loop1:				; start by adding black squares to make the frame
	ldi (HL),A
	dec B
	jr nz,fs_loop1
	; draws top line of frame
	inc A	; equivalent to "ld A,WHITE_SQUARE", bc WHITE_SQUARE is BLACK_SQUARE + 1
fs_loop2:
	ldi (HL),A
	dec C
	jr nz,fs_loop2

	ld B,8		; number of lines in the code
	; "ld C,0" not necessary because C is already zero
	; C will contain the current tile, so it will get increased whenever we need to place a new one
dataLoop:	; repeated for each line
	ld DE,0x140A
	; ld D,20
	; ld E,10
	dec A		; does "ld A,BLACK_SQUARE"
fs_loop3:						; new line, by writing black squares until we're in the right position
	ldi (HL),A
	dec D
	jr nz,fs_loop3
	inc A				; ld A,WHITE_SQUARE
	ldi (HL),A			; white tile for frame

	; for 10 data tiles in the line
fs_loop4:
	ld (HL),C
	inc HL
	inc C							; next tile
	dec E							; decrease line tile counter
	jr nz,fs_loop4
	
	ldi (HL),A			; one white tile for right frame

	dec B
	jr nz,dataLoop

	dec A				; ld A,BLACK_SQUARE
	; the last line is different, having only 4 tiles we need to show. for this reason it has a separate part of the function
	ld B,20
fs_loop6:
	ldi (HL),A
	dec B
	jr nz,fs_loop6

	inc A
	ldi (HL),A

	ld A,C

	ldi (HL),A
	inc A
	ldi (HL),A
	inc A						; 4 tiles, then a white tile
	ldi (HL),A
	inc A
	ldi (HL),A

	ld A,WHITE_SQUARE
	ld BC,0x0714		; load 7 in B and 20 in C, by pairing two registers we save a load
	; ld B,7
	; ld C,20
fs_loop7:						; since we only have 4 data tiles, we fill the other 6 tiles in the line with white frame tiles
	ldi (HL),A
	dec B
	jr nz,fs_loop7

	; last new line
	dec A		; ld A,BLACK_SQUARE
fs_loop8:
	ldi (hl),a
	dec c
	jr nz,fs_loop8
	
	; bottom row of the frame
	ld bc,0x0C84
	; ld B,12
	; ld C,0x84
	inc A; ld a,WHITE_SQUARE
fs_loop69:
	ldi (HL),A
	dec B
	jr nz,fs_loop69
	; after the white frame, we cover the rest of the screen with black tiles
	dec A;ld A,BLACK_SQUARE
final_loop:
	ldi (HL),A
	dec C
	jr nz,final_loop
end_fs:


; here "D" is used as a counter for the tiles we still have to overwrite
; "HL" contains the VRAM address containing sprite data, the one we'll need to overwrite
; "BC" contains the address containing box data
; "E" is also used as a counter. it counts the number of bytes in each tile (8)
; this overwrites the tile data with our data
overwriteStuff:
	ld D,TILES_TO_WRITE			; including 0
	ld HL,TILE_DATA
	ld BC,BOX_DATA
overwriteStuffLoop2:
	ld E,8			; every tile has 8 bytes
overwriteStuffLoop:
	ld A,(BC)			;
	inc BC				; current_byte = *(data_to_read++)
	ldi (HL),A			; *(graphics_ptr++) = current_byte
	ld A,0xFF			; *(graphics_ptr++) = 0xFF          // writing a byte and then 0xFF will creeate a line with the binary representation of that first byte
	ldi (HL),A			;
	dec E
	jr nz,overwriteStuffLoop	; will loop for all bytes in the tile
	dec D
	jr nz,overwriteStuffLoop2	; will loop for every tile in the code

	; an entire column will be just for the number. this saves three bytes
	writeMonNumber:
	ld BC,0x0810
	; ld B,8
	wmn_black_loop:
	ld A,(MON_NUMBER)	; TODO: this is an immediate. maybe moving it before everything else and adding instead of loading will do something
	ldi (HL),A
	ld A,0xFF
	ldi (HL),A
	dec B
	jr nz,wmn_black_loop

; overwrites the white and black tiles of the frame to be full-white or full-black
	; ld A,0xFF is not needed because we loaded above
overwrite_5455:
	; ld C,0x10 is done with the paired loop above. the second time we write 0x100 bytes but its ok because we overwrite unused tiles
loop1:				; write 16 (size in bytes of a tile) times ff to create black tile, then adds one to write 00, which creates white tile. this way i don't have to rewrite the function
	ldi (HL),A
	dec C
	jr nz,loop1
	
	; adds one, and jumps back to the start if there was an overflow (a=0). this way we only jump the first time (a=0xFF), AND we get the correct value for "a" to write
	; O P T I M I S A T I O N S
	inc A
	jr z,overwrite_5455
end_overwrite:


	; turn the screen back on but keep sprites disabled
	ld A,0xE1
	ldh (0x40),A
	
	reti
