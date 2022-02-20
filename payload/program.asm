; first box
; (33*20) + 1 bytes of information

; index of the tile in memory used for black and white squares
BLACK_SQUARE = $54
WHITE_FRAME	= $55

; memory address for stored pokémon data
BOX_DATA = $da96

; preparation before changing stuff
	di
VBlankCheck:
	ldh a,($44)	 	; vertical position of scanline
	cp a, $91			; when it's $91 we just entered VBlank
	jr nz,VBlankCheck
	ld a,$63			; turn off the screen
	ldh ($40),a
	; now the screen is off and we can do stuff

	ld a,0
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
	ld hl,$9800
	ld b,$64			; to make the code centered in the screen, and to compensate for off-screen tiles
	ld a,BLACK_SQUARE
fs_loop1:				; start by adding black squares to make the frame
	ldi (hl),a
	dec b
	jr nz,fs_loop1
	; draws top line of frame
	ld a,WHITE_FRAME
	ld b,$0c
fs_loop2:
	ldi (hl),a
	dec b
	jr nz,fs_loop2

	ld a,0		; initialise a to 0, this is where the tiling starts
	ld d,8		; number of lines in the code
dataLoop:	; repeated for each line
	ld b,20
fs_loop3:						; new line, by writing black squares until we're in the right position
	ld (hl),BLACK_SQUARE
	inc hl
	dec b
	jr nz,fs_loop3
	ld (hl),WHITE_FRAME			; white tile for frame
	inc hl

	; for 10 data tiles in the line
	ld b,10
fs_loop4:
	ldi (hl),a
	inc a						 ; next tile
	dec b						 ; decrease line tile counter
	jr nz,fs_loop4
	
	ld (hl),WHITE_FRAME			; one white tile for right frame
	inc hl

	dec d
	jr nz,dataLoop

	; the last line is different, having only 4 tiles we need to show. for this reason it has a separate part of the function
	ld b,20
fs_loop6:
	ld (hl),BLACK_SQUARE
	inc hl						; new line
	dec b
	jr nz,fs_loop6

	ld (hl),WHITE_FRAME
	inc hl

	ldi (hl),a
	inc a
	ldi (hl),a
	inc a						; 4 tiles, then a white tile
	ldi (hl),a
	inc a
	ldi (hl),a
	ld a,WHITE_FRAME
	ld b,7
fs_loop7:						; since we only have 4 data tiles, we fill the other 6 tiles in the line with white frame tiles
	ldi (hl),a
	dec b
	jr nz,fs_loop7

	; last new line
	ld b,20
	ld a,BLACK_SQUARE
fs_loop8:
	ldi (hl),a
	dec b
	jr nz,fs_loop8
	
	; bottom row of the frame
	ld b,12
	ld a,WHITE_FRAME
fs_loop69:
	ldi (hl),a
	dec b
	jr nz,fs_loop69
	; after the white frame, we cover the rest of the screen with black tiles
	ld b,$84
	ld a,BLACK_SQUARE
final_loop:
	ldi (hl),a
	dec b
	jr nz,final_loop
end_fs:
;END OF FILLSCREEN
	
	

; probably can be optimised if I put it after the rest of the data, but it's fine for now
; ; overwrites white and black tiles to be actually white or black
; 	ld hl,$9540			; writes to the black tile
; 	ld a,$ff
; overwrite_5455:
; 	ld b,$10
; loop1:							; write 16 times ff to create black tile, then adds one to write 00, which creates white tile. this way i don't have to rewrite the function
; 	ldi (hl),a
; 	dec b
; 	jr nz,loop1			; write all 16 bytes as a sprite is 16 bytes long
	
; 	; adds one, and jumps back to the start if there was an overflow. this way we only jump the first time (as "a" contains ff), AND we get the correct value for "a" to write
; 	; O P T I M I S A T I O N S
; 	add a,1					 ; we use "add 1" and not "inc" because "inc" does not set the overflow flag
; 	jr c,overwrite_5455		 ; se posso, penso che sia una soluzione piuttosto intelligente

; here "d" is used as a counter for the tiles we still have to overwrite
; "bc" contains the VRAM address containing sprite data, the one we'll need to overwrite
; "hl" contains the address containing box data
; "e" is also used as a counter simply because otherwise the number to load in "d" would be too large. it counts the number of bytes in each tile (8)
; this overwrites the tile data with our data
overwriteStuff:
	ld d,$53				; we do this for 0x53 (84, since we count 0) tiles
	ld hl,$9000			; that's where VRAM for tiles starts
	ld bc,BOX_DATA
overwriteStuffLoop2:
	ld e,8 			; every tile has 8 bytes
overwriteStuffLoop:
	ld a,(bc)
	inc bc
	ldi (hl),a
	ld a,$ff				; i found out by writing any byte and then "ff" a black-on-white binary representation of that byte will be shown on the sprite
	ldi (hl),a			; write ff to VRAM and increase
	dec e
	jr nz,overwriteStuffLoop 	; will loop for all bytes in the tile
	dec d
	jr nz,overwriteStuffLoop2	; will loop for every tile in the code

; last twelve bytes are useless except the last one which contains the number of valid pokémon in the box, this way we don't decode invalid data
writeMonNumber:
	ld bc, $da79 ; starts 7 bytes before the "number of pokémon in box" byte, this way it gets written as the last one
	ld e,8
wmnLoop:
	ld a,(bc)
	inc bc
	ldi (hl),a
	ld a,$ff
	ldi (hl),a
	dec e
	jr nz, wmnLoop

; overwrites white and black tiles to be actually white or black
	ld a,$ff
overwrite_5455:
	ld b,$10
loop1:							; write 16 times ff to create black tile, then adds one to write 00, which creates white tile. this way i don't have to rewrite the function
	ldi (hl),a
	dec b
	jr nz,loop1			; write all 16 bytes as a sprite is 16 bytes long
	
	; adds one, and jumps back to the start if there was an overflow. this way we only jump the first time (as "a" contains ff), AND we get the correct value for "a" to write
	; O P T I M I S A T I O N S
	add a,1					 ; we use "add 1" and not "inc" because "inc" does not set the overflow flag
	jr c,overwrite_5455		 ; se posso, penso che sia una soluzione piuttosto intelligente

; END OF OVERWRITE 

	; turn the screen back on but keep sprites disabled
	ld a,$e1
	ldh ($40),a
	
	reti
