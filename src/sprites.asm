;; sprites
;; Interface
;;   * Sprites_init     (called by main routine)
;;   * Sprites_cycle    (called by interrupt)
;;   * Sprites_setUpper (called by interrupt)
;;   * Sprites_setLower (called by interrupt)
;; Functionality:
;;   * init sprites
;;   * animate sprites (turn left/right)
;;   * (re)set sprite positions in upper/lower border
	
Sprites_init
  lda #0
  sta $d01b 			; sprites before background
  sta $d017 			; sprites normal size vertical
  sta $d01d 			; sprites normal size horizontal
  lda #%11111111                ; all sprites 
  sta $d01c 			; sprites multi color mode
  lda #15			; light grey
  sta $d025			; set shared color 01
  lda #12			; middle grey
  sta $d026			; set shared color 11
  lda #02			; red
  sta $d027	                ; set color sprite 0
  lda #06			; blue
  sta $d028	                ; set color sprite 1
  lda #05			; green
  sta $d029	                ; set color sprite 2
  lda #07			; yellow
  sta $d02a	                ; set color sprite 3
  lda #03			; cyan
  sta $d02b	                ; set color sprite 4
  lda #04			; purple
  sta $d02c	                ; set color sprite 5
  lda #10			; light red
  sta $d02d	                ; set color sprite 6
  lda #13			; light green
  sta $d02e	                ; set color sprite 7
  lda #%00000001                ; select sprite 0 
  sta $d010	                ; set sprites with x pos > 255
  lda #1
  sta $d000                     ; sprite 0 x pos
  lda #233
  sta $d002                     ; sprite 1 x pos
  lda #209
  sta $d004                     ; sprite 2 x pos
  lda #185
  sta $d006                     ; sprite 3 x pos
  lda #161
  sta $d008                     ; sprite 4 x pos
  lda #137
  sta $d00a                     ; sprite 5 x pos
  lda #113
  sta $d00c                     ; sprite 6 x pos
  lda #89
  sta $d00e                     ; sprite 7 x pos
  lda #%11111111                ; all sprites
  sta $D015                     ; switch on sprites
  rts


SPRITES_POINTER_FIRST = ($3000/64)
SPRITES_POINTER_LAST = ($3000/64)+15

sprites_pointerUpper
!byte SPRITES_POINTER_FIRST
	
sprites_pointerLower
!byte SPRITES_POINTER_FIRST
	
Sprites_cycle
  ;; turn upper sprites left
  ldy sprites_pointerUpper
  iny
  cpy #SPRITES_POINTER_LAST+1
  bne Sprites_cycleStoreUpper
  ldy #SPRITES_POINTER_FIRST	
Sprites_cycleStoreUpper
  sty sprites_pointerUpper	
  ;; turn lower sprites right
  ldy sprites_pointerLower
  dey
  cpy #SPRITES_POINTER_FIRST-1
  bne Sprites_cycleStoreLower
  ldy #SPRITES_POINTER_LAST	
Sprites_cycleStoreLower
  sty sprites_pointerLower	
  rts

Sprites_setUpper
  lda sprites_pointerUpper
  sta $07f8                     ; set sprite pointer 0
  sta $07f9                     ; set sprite pointer 1
  sta $07fa                     ; set sprite pointer 2
  sta $07fb                     ; set sprite pointer 3
  sta $07fc                     ; set sprite pointer 4
  sta $07fd                     ; set sprite pointer 5
  sta $07fe                     ; set sprite pointer 6
  sta $07ff                     ; set sprite pointer 7
  lda #27
  sta $d001			; sprite 0 y pos
  sta $d003			; sprite 1 y pos
  sta $d005			; sprite 2 y pos
  sta $d007			; sprite 3 y pos
  sta $d009			; sprite 4 y pos
  sta $d00b			; sprite 5 y pos
  sta $d00d			; sprite 6 y pos
  sta $d00f			; sprite 7 y pos
  rts
	
Sprites_setLower
  lda sprites_pointerLower
  sta $07f8                     ; set sprite pointer 0
  sta $07f9                     ; set sprite pointer 1
  sta $07fa                     ; set sprite pointer 2
  sta $07fb                     ; set sprite pointer 3
  sta $07fc                     ; set sprite pointer 4
  sta $07fd                     ; set sprite pointer 5
  sta $07fe                     ; set sprite pointer 6
  sta $07ff                     ; set sprite pointer 7
  lda #249
  sta $d001			; sprite 0 y pos
  sta $d003			; sprite 1 y pos
  sta $d005			; sprite 2 y pos
  sta $d007			; sprite 3 y pos
  sta $d009			; sprite 4 y pos
  sta $d00b			; sprite 5 y pos
  sta $d00d			; sprite 6 y pos
  sta $d00f			; sprite 7 y pos
  rts
