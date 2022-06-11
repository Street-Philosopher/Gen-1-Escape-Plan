; TODO: this could be maybe potentially be optimised by removing all the 0xFF when writing to VRAM which would also double the information density, which would require a rewrite of the program
; i don't know if you can notice the slow realisation that the idea is not that easy after all, in the comment above

; first box
; (33*20) + 1 bytes of information

; index of the tile in memory used for black and white squares
BLACK_SQUARE = $54
WHITE_FRAME	= $55

; memory addresses
TILE_DATA = $9000
MAP_DATA  = $9800
BOX_DATA  = $DA96
MON_NUMBER= $DA80

;TODO: is vblankcheck really necessary? do some research abt it

; preparation before changing stuff
	di
VBlankCheck:
	ldh a,($44)	 	; vertical position of scanline
	cp a, $91			; when it's $91 we just entered VBlank
	jr nz,VBlankCheck
	ld a,$63			; turn off the screen
	ldh ($40),a
	; now the screen is off and we can do stuff
	
	xor a,a		; initialise a to 0, this is where the tiling starts
	ldh ($d7),a			; block tile animations by loading 0 in $ffd7. otherwise tiles like flowers would constantly change, breaking our image
; end of prep

; this will overwrite the current map data to show on screen a frame (black and white) containing all different tiles
; "hl" will hold the VRAM address containing current tile data, so we can overwrite the map at our likings
; "a" is the tile number we want to write next
; "b" and "d" are used as counters
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
	ld hl,MAP_DATA
	ld bc,$640C
	; ld b,$64			; to make the code centered in the screen, and to compensate for off-screen tiles
	; ld c,$0c
	ld a,BLACK_SQUARE
fs_loop1:				; start by adding black squares to make the frame
	ldi (hl),a
	dec b
	jr nz,fs_loop1
	; draws top line of frame
	inc A ; equivalent to "ld a,WHITE_FRAME", bc WHITE_FRAME is BLACK_SQUARE + 1
fs_loop2:
	ldi (hl),a
	dec c
	jr nz,fs_loop2

	ld d,8		; number of lines in the code
	; "ld C,0" not necessary because C is already zero
dataLoop:	; repeated for each line
	ld b,20
	dec A		; does "ld A,BLACK_SQUARE"
fs_loop3:						; new line, by writing black squares until we're in the right position
	ldi (hl),a
	dec b
	jr nz,fs_loop3
	inc A		; ld A,WHITE_FRAME
	ldi (hl),a			; white tile for frame

	; for 10 data tiles in the line
	ld b,10
fs_loop4:
	ld (hl),c
	inc hl
	inc c							; next tile
	dec b							; decrease line tile counter
	jr nz,fs_loop4
	
	ldi (hl),a			; one white tile for right frame

	dec d
	jr nz,dataLoop

	dec A
	; the last line is different, having only 4 tiles we need to show. for this reason it has a separate part of the function
	ld b,20
fs_loop6:
	ldi (hl),a
	dec b
	jr nz,fs_loop6

	inc a
	ldi (hl),a

	ld a,c

	ldi (hl),a
	inc a
	ldi (hl),a
	inc a						; 4 tiles, then a white tile
	ldi (hl),a
	inc a
	ldi (hl),a
	ld a,WHITE_FRAME
	ld bc,$0714		; load 7 in B and 20 in C, this way we save a load later
	; ld B,7
	; ld C,20
fs_loop7:						; since we only have 4 data tiles, we fill the other 6 tiles in the line with white frame tiles
	ldi (hl),a
	dec b
	jr nz,fs_loop7

	; last new line
	ld a,BLACK_SQUARE
fs_loop8:
	ldi (hl),a
	dec c
	jr nz,fs_loop8
	
	; bottom row of the frame
	ld bc,$0C84
	; ld B,12
	; ld C,$84
	ld a,WHITE_FRAME
fs_loop69:
	ldi (hl),a
	dec b
	jr nz,fs_loop69
	; after the white frame, we cover the rest of the screen with black tiles
	ld a,BLACK_SQUARE
final_loop:
	ldi (hl),a
	dec c
	jr nz,final_loop
end_fs:
;END OF FILLSCREEN


; here "d" is used as a counter for the tiles we still have to overwrite
; "hl" contains the VRAM address containing sprite data, the one we'll need to overwrite
; "bc" contains the address containing box data
; "e" is also used as a counter simply because otherwise the number to load in "d" would be too large. it counts the number of bytes in each tile (8)
; this overwrites the tile data with our data
overwriteStuff:
	ld d,$53				; we do this for 0x53 (84, since we count 0) tiles
	ld hl,TILE_DATA
	ld bc,BOX_DATA
overwriteStuffLoop2:
	ld e,8			; every tile has 8 bytes
overwriteStuffLoop:
	ld a,(bc)
	inc bc
	ldi (hl),a
	ld a,$ff				; i found out by writing any byte and then "ff" a black-on-white binary representation of that byte will be shown on the sprite
	ldi (hl),a			; write ff to VRAM and increase
	dec e
	jr nz,overwriteStuffLoop	; will loop for all bytes in the tile
	dec d
	jr nz,overwriteStuffLoop2	; will loop for every tile in the code
	

	; an entire column will be just for the number. this saves three bytes
	writeMonNumber:
	ld b,8
	wmn_black_loop:
	ld a,(MON_NUMBER)
	ldi (hl),a
	ld a,$ff
	ldi (hl),a
	dec b
	jr nz,wmn_black_loop


; overwrites white and black tiles to be actually white or black
	; ld a,$ff is not needed because we loaded above
overwrite_5455:
	ld b,$10
loop1:							; write 16 times ff to create black tile, then adds one to write 00, which creates white tile. this way i don't have to rewrite the function
	ldi (hl),a
	dec b
	jr nz,loop1			; write all 16 bytes as a sprite is 16 bytes long
	
	; adds one, and jumps back to the start if there was an overflow. this way we only jump the first time (as "a" contains ff), AND we get the correct value for "a" to write
	; O P T I M I S A T I O N S
	inc a
	jr z,overwrite_5455			; tbh this is pretty smart

; END OF OVERWRITE 

	; turn the screen back on but keep sprites disabled
	ld a,$e1
	ldh ($40),a
	
	reti
