; first box
; (33*20) + 1 bytes of information

; tile index of the completely black and completely white tiles, used for the frame
BLACK_SQUARE = $54
WHITE_FRAME  = $55

    org $d901

    ld hl,$ff41
    ld a,$63
vb:
	bit 0,(hl)                                      ; turn off screen
	jr nz,vb
    ldh ($40),a

    ld a,0
	ldh ($d7),a					; block tile animations

fillScreen:
	ld hl,$9800
	ld b,$64
	ld a,BLACK_SQUARE
fs_loop1:
	ldi (hl),a
	dec b
	jr nz,fs_loop1               ; black background
	ld a,WHITE_FRAME
	ld b,$0c
fs_loop2:
	ldi (hl),a                   ; white frame
	dec b
	jr nz,fs_loop2

    ld a,0                       ; go from tile 0 to tile (decimal)82
    ld d,8                       ; we have 8 rows
dataLoop:
    ld b,20
fs_loop3:                        ; new row
    ld (hl),BLACK_SQUARE
    inc hl
    dec b
    jr nz,fs_loop3
    ld (hl),WHITE_FRAME          ; white tile in the beginning of the row
    inc hl

    ld b,10                      ; 10 dati per riga max
fs_loop4:
    ldi (hl),a                   ; tile numero "a", aumenta "a" e "hl"
    inc a
    dec b
    jr nz,fs_loop4
    ld (hl),WHITE_FRAME          ; one white tile for end data
    inc hl

    dec d
    jr nz,dataLoop

    ; ultima riga
    ld b,20
fs_loop6:
    ld (hl),BLACK_SQUARE
    inc hl                       ; nuova riga
    dec b
    jr nz,fs_loop6

    ld (hl),WHITE_FRAME
    inc hl                       ; tile bianco

    ldi (hl),a
    inc a
    ldi (hl),a
    inc a
    ldi (hl),a
    inc a
    ldi (hl),a
    ld a,WHITE_FRAME
    ld b,7
fs_loop7:                        ; cornice lunga fine ultima riga
    ldi (hl),a
    dec b
    jr nz,fs_loop7

    ; nuova riga, prima di finire la cornice
    ld b,20
    ld a,BLACK_SQUARE
fs_loop8:
    ldi (hl),a
    dec b
    jr nz,fs_loop8
    
    ; fondo della cornice
    ld b,12
    ld a,WHITE_FRAME
fs_loop69:
    ldi (hl),a
    dec b
    jr nz,fs_loop69
    ; tile neri per coprire lo schermo intero
    ld b,$84
    ld a,BLACK_SQUARE
final_loop:
    ldi (hl),a
    dec b
    jr nz,final_loop
end_fs:
    ; fine di fillscreen. this is where the fun begins
	
    ; probabilmente si puo ottimizzare mettendolo dopo ilr esto dei dati, ma fa nulla
    ld hl,$9540
    ld a,$ff
overwrite_5455:
    ld b,$10
loop1:                          ; prima scrive 16 volte 0, poi sottrae 1 da A e se il risultato � FF allora ripete sottraendo FF
    ldi (hl),a
    dec b
    jr nz,loop1
    add a,1                     ; in questo modo il prossimo jump verrà eserguito solo la prima volta. devo usare "add" perche "inc" non imposta l'overflow
    jr c,overwrite_5455         ; se posso, penso che sia una soluzione piuttosto intelligente

overwriteStuff:
    ld d,$53
    ld bc,$9000
    ld hl,$da96
overwriteStuffLoop2:
    ld e,8
overwriteStuffLoop:
    ldi a,(hl)
    ld (bc),a
    inc bc
    ld a,$ff
    ld (bc),a
    inc bc
    dec e
    jr nz,overwriteStuffLoop
    dec d
    jr nz,overwriteStuffLoop2

; gli ultimi 12 byte, a parte l'ultimo, sono spazzatura: l'ultimo contiene il numero di pokémon validi nel box, così l'interprete non fa uscire pokémon invalidi
writeMonNumber:
    ld hl, $da79
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

    ld a,$e1
    ldh ($40),a

    ret
