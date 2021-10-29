; first box
; (33*20) + 1 bytes of information

; tile index of the completely black and completely white tiles, used for the frame
BLACK_SQUARE = $54
WHITE_FRAME  = $55

; memory address for stored pokémon data
BOX_DATA = $da96

; this isn't really necessary, but I like it here
    org $d901

; these few lines will be for preparation
    ld hl,$ff41
    ld a,$63
VBlankCheck:
    bit 0,(hl) 			; check if we're in VBlank
    jr nz,VBlankCheck 		; if not, repeat the loop
    ldh ($40),a			; this is the "LCD Settings" address. by loading $63 into it we're turning the screen off and disabling sprites
				; it's necessary because of some weird GameBoy mechanic called VBlank

    ld a,0
    ldh ($d7),a			; block tile animations by loading 0 in $ffd7. otherwise tiles like flowers would constantly change, breaking our image
;END OF PREPARATION

; this will overwrite the current map data to show on screen a frame (black and white) containing different tiles
; "hl" will hold the VRAM address containing current tile data, so we can overwrite the map at our likings
; "a" is the tile number we want to write next
; "b" and "d" are used as counters
fillScreen:
    ld hl,$9800
    ld b,$64
    ld a,BLACK_SQUARE
fs_loop1:						; start by adding black squares to make the frame
    ldi (hl),a
    dec b
    jr nz,fs_loop1
    ld a,WHITE_FRAME
    ld b,$0c
fs_loop2:
    ldi (hl),a             		; draws one line of white frame
    dec b
    jr nz,fs_loop2

    ld a,0                       ; initialise a to 0, this is where the tiling starts
    ld d,8                       ; we have 8 lines in the code
dataLoop:
    ld b,20
fs_loop3:                        ; new line, by writing black squares until we're in the right position
    ld (hl),BLACK_SQUARE
    inc hl
    dec b
    jr nz,fs_loop3
    ld (hl),WHITE_FRAME          ; white tile for frame
    inc hl

    ld b,10                      ; there's 10 data tiles per line
fs_loop4:
    ldi (hl),a                   ; we write the tile number to VRAM, then increase VRAM pointer to go to next tile
    inc a						 ; increase tile number
    dec b						 ; decrease line tile counter
    jr nz,fs_loop4 				 ; repeated 10 times, drawing 10 tiles in current row
	
    ld (hl),WHITE_FRAME          ; one white tile for right frame
    inc hl

    dec d
    jr nz,dataLoop				 ; makes it so we repeat "d" (number of lines) times

    ; the last line is different, having only 4 tiles we need to show. for this reason it has a separate part of the function
    ld b,20
fs_loop6:
    ld (hl),BLACK_SQUARE
    inc hl                       ; new line
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
fs_loop7:                        ; since we only have 4 data tiles, we fill the other 6 tiles in the line with white frame tiles
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
; overwrites white and black tiles to be actually white or black
    ld hl,$9540			; writes to the black tile
    ld a,$ff
overwrite_5455:
    ld b,$10
loop1:                          ; write 16 times ff to create black tile, then adds one to write 00, which creates white tile. this way i don't have to rewrite the function
    ldi (hl),a
    dec b
    jr nz,loop1			; write all 16 bytes as a sprite is 16 bytes long
    
    ; adds one, and jumps back to the start if there was an overflow. this way we only jump the first time (as "a" contains ff), AND we get the correct value for "a" to write
    ; O P T I M I S A T I O N S
    add a,1                     ; we use "add 1" and not "inc" because "inc" does not set the overflow flag
    jr c,overwrite_5455         ; se posso, penso che sia una soluzione piuttosto intelligente

; here "d" is used as a counter for the tiles we still have to overwrite
; "bc" contains the VRAM address containing sprite data, the one we'll need to overwrite
; "hl" contains the address containing box data
; "e" is also used as a counter simply because otherwise the number to load in "d" would be too large. it counts the number of bytes in each tile (8)
; this overwrites the tile data with our data
overwriteStuff:
    ld d,$53       		; we do this for 0x53 (84, since we count 0) tiles
    ld bc,$9000   		; that's where VRAM for tiles starts
    ld hl,BOX_DATA
overwriteStuffLoop2:
    ld e,8 			; every tile has 8 bytes
overwriteStuffLoop:
    ldi a,(hl)  		; write our byte and increase the pointer to go to the next one
    ld (bc),a			; load the data in VRAM
    inc bc			; increase VRAM pointer
    ld a,$ff  			; i found out by writing any byte and then "ff" a black-on-white binary representation of that byte will be shown on the sprite
    ld (bc),a			; write ff to VRAM and increase
    inc bc
    dec e
    jr nz,overwriteStuffLoop 	; will loop for all bytes in the tile
    dec d
    jr nz,overwriteStuffLoop2	; will loop for every tile in the code

; last twelve bytes are useless except the last one which contains the number of valid pokémon in the box, this way we don't decode invalid data
writeMonNumber:
    ld hl, $da79 ; starts 7 bytes before the "number of pokémon in box" byte, this way it gets written as the last one
    ld e,8
wmnLoop:
    ldi a,(hl)
    ld (bc),a
    inc bc
    ld a,$ff
    ld (bc),a
    inc bc
    dec e
    jr nz, wmnLoop
; END OF OVERWRITE 

    ld a,$e1     ; loading $e1 in the LCD settings will cause them to turn the screen back on, but not the sprites. this way the player sprite doesn't cover the image
    ldh ($40),a
   
    ret   ; end of the program. return to avoid catastrophes when executing
