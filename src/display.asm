;; display
;; Interface
;;   * Display_init
;;   * Display_drawBuffer0
;;   * Display_showBuffer0	
;;   * Display_drawBuffer1
;;   * Display_showBuffer1	
;;   * Display_scrollColors
;; Functionality:
;;   * init display
;;   * fill buffer 0 (screen memory and color ram)
;;   * indicate interrupt to show buffer 0 in next screen update
;;   * fill buffer 1 (screen memory and color ram)
;;   * indicate interrupt to show buffer 1 in next screen update
;;   * color ram scrolling

;; since upper/lower border is open the inner frame color has
;; to be set artificially during raster interrupts ->
;; the color can be different than the black color in the upper/lower border 
;; (black is needed in upper border to hide the linecrunch, in lower border
;; to hide the additional char line 25)
DISPLAY_COLOR_BACKGROUND_INNER_FRAME        = $0b ; dark grey
DISPLAY_COLOR_BACKGROUND_UPPER_LOWER_BORDER = $00 ; black
DISPLAY_COLOR_BACKGROUND_LEFT_RIGHT_BORDER  = $0e ; light blue
DISPLAY_COLOR_BACKGROUND_01                 = $0f ; light grey
DISPLAY_COLOR_BACKGROUND_10                 = $0c ; middle grey 

Display_init
  lda #DISPLAY_COLOR_BACKGROUND_LEFT_RIGHT_BORDER
  sta $d020
  ;; Background color ($d021) is set by interrupt depending on the rasterline:
  ;; inner frame color:        DISPLAY_COLOR_BACKGROUND_INNER_FRAME
  ;; upper/lower border color: DISPLAY_COLOR_BACKGROUND_UPPER_LOWER_BORDER
  lda #DISPLAY_COLOR_BACKGROUND_01
  sta $d022 ;; "01": Background color ($d022)       
  lda #DISPLAY_COLOR_BACKGROUND_10
  sta $d023 ;; "10": Background color ($d023)       

  lda $DD00
  and #%11111100
  ora #%00000011 ; VIC bank to $0000-$3FFF
  sta $DD00
  lda $d016  
  ora #%00010000 ; set multicolor mode bit 4
  sta $d016
  lda $d018
  and #%00001111 
  ora #%00010000 ; $D018 = %0011xxxx -> screenmem is at $0400
  sta $d018
  rts

;; char and color double buffer 0
;; fill 12 lines [0,2,4,...,22]
Display_drawBuffer0
  jsr Display_drawBuffer0Chars
  jsr Display_drawBuffer0Colors
  rts
  	
Display_drawBuffer0Chars
  ldy #39
  lda #$00	
Display_drawBuffer0CharsLoop
  sta $0400,y	
  sta $0450,y	
  sta $04a0,y	
  sta $04f0,y	
  sta $0540,y	
  sta $0590,y	
  sta $05e0,y	
  sta $0630,y	
  sta $0680,y	
  sta $06d0,y	
  sta $0720,y	
  sta $0770,y	
  dey
  bpl Display_drawBuffer0CharsLoop
  rts	

Display_drawBuffer0Colors
  lda Display_colorStartValue
  sta Display_colorCurrentValue
  ldy #39
Display_drawBuffer0ColorsLoop
  sta $d800,y
  sta $d850,y
  sta $d8a0,y
  sta $d8f0,y
  sta $d940,y
  sta $d990,y
  sta $d9e0,y
  sta $da30,y
  sta $da80,y
  sta $dad0,y
  sta $db20,y
  sta $db70,y
  inc Display_colorCurrentValue
  lda Display_colorCurrentValue
  cmp #DISPLAY_COLOR_MAX_VALUE
  bne Display_drawBuffer0ColorsNoColorOverflow
  lda #DISPLAY_COLOR_RESET_VALUE
  sta Display_colorCurrentValue
Display_drawBuffer0ColorsNoColorOverflow
  dey
  bpl Display_drawBuffer0ColorsLoop
  rts	

Display_showBuffer0
  lda #0
  sta interrupt_bufferIndex
  rts
	
;; char and color double buffer 1
;; fill 12 lines [1,3,5,...,23]
Display_drawBuffer1
  jsr Display_drawBuffer1Chars
  jsr Display_drawBuffer1Colors
  rts
	
Display_drawBuffer1Chars
  ldy #39
  lda #$01
Display_drawBuffer1CharsLoop
  sta $0428,y	
  sta $0478,y	
  sta $04c8,y
  sta $0518,y	
  sta $0568,y	
  sta $05b8,y	
  sta $0608,y	
  sta $0658,y	
  sta $06a8,y	
  sta $06f8,y	
  sta $0748,y	
  sta $0798,y	
  dey
  bpl Display_drawBuffer1CharsLoop
  rts

Display_drawBuffer1Colors
  lda Display_colorStartValue
  sta Display_colorCurrentValue
  ldy #39
Display_drawBuffer1ColorsLoop
  lda Display_colorCurrentValue
  sta $d828,y
  sta $d878,y
  sta $d8c8,y
  sta $d918,y
  sta $d968,y
  sta $d9b8,y
  sta $da08,y
  sta $da58,y
  sta $daa8,y
  sta $daf8,y
  sta $db48,y
  sta $db98,y
  inc Display_colorCurrentValue
  lda Display_colorCurrentValue
  cmp #DISPLAY_COLOR_MAX_VALUE
  bne Display_drawBuffer1ColorsNoColorOverflow
  lda #DISPLAY_COLOR_RESET_VALUE
  sta Display_colorCurrentValue
Display_drawBuffer1ColorsNoColorOverflow
  dey
  bpl Display_drawBuffer1ColorsLoop
  rts	
	
Display_showBuffer1
  lda #1	
  sta interrupt_bufferIndex
  rts
	
DISPLAY_COLOR_RESET_VALUE = 8
DISPLAY_COLOR_MAX_VALUE = 16
Display_colorStartValue
!byte DISPLAY_COLOR_RESET_VALUE
Display_colorCurrentValue
!byte 0

Display_scrollColors
  inc Display_colorStartValue
  lda Display_colorStartValue	
  cmp #DISPLAY_COLOR_MAX_VALUE
  bne Display_scrollColorsNoOverflow
  lda #DISPLAY_COLOR_RESET_VALUE
  sta Display_colorStartValue	
Display_scrollColorsNoOverflow
  rts
