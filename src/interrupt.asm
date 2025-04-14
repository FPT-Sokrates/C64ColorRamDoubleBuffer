;; Interrupt Handling
;; Interface:
;;   * "Interrupt_init" to initialise interrupt
;;   * "Interrupt_start" to start interrupt
;;   * "interrupt_bufferIndex" indicates double buffer shown in next frame:
;;     0: show buffer 0 in next frame
;;     1: show buffer 1 in next frame

;; Functionality:	
;;   * implement color ram double buffer with char size 8x16
;;     (instead of usual 8x8) and two charsets instead of one
;;   * use fast unstable interrupts when possible and stable interrupts when needed
;;   * works for all VIC-II types
;;   * open top/bottom border
;;   * set Background color for inner frame since the normal inner frame
;;     does not exist any more due to opened upper/lower border
;;   * naming convention:
;;     "db0":  routines/variables for double buffer 0 
;;     "db1":  routines/variables for double buffer 1 
;;     "db01": routines/variables for double buffer 0 and 1 

;;;;;;;;;;;;;;;;;;;;;;;;
;; Interrupt sequence ;;
;;;;;;;;;;;;;;;;;;;;;;;;

;; Interrupt_db01_FirstLine (unstable)
;;   * set charset 0
;;   * reset loop index for double text line and charset switch interrupts (see loop below)
;;   * switch to invalid text mode to hide pixels until the first charline and
;;     reset y position (which was manipulated by open upper/lower border)
;;   * call sprite animation (upper/lower sprites animation)
;;   * set upper sprite positions
;;   * check buffer index
;;     * if buffer index = 0
;;       set next interrupt to Interrupt_db0_SetBackgroundColor
;;     * if buffer index = 1
;;       set next interrupt to Interrupt_db1_LineCrunch

;; Continue with interrupt in case buffer 0:
;; Interrupt_db0_SetBackgroundColor (unstable)
;;   * switch to valid text mode for first line
;;   * set background color for inner frame
;;   * set next interrupt to Interrupt_db01_DoubleLine (see loop below)

;; Continue with interrupt in case buffer 1:
;; Interrupt_db1_LineCrunch (stable)
;;   * line crunch for line 0 (so start screen with line 1)
;;   * switch on invalid text mode to hide last raster line pixels from crunched char line
;;   * set background color for inner frame
;;   * switch back to valid text mode to show line 1
;;   * set next interrupt to Interrupt_db01_DoubleLine (see loop below)

;; Continue with interrupts in case buffer 0 and 1:
;; Loop 12 times:
;;   Interrupt_db01_DoubleLine (stable)
;;     * repeat char-line (double line)
;;     * set charset 1 for next line
;;     * set yscroll to standard value
;;     * set next interrupt to Interrupt_db01_ChangeCharset
;;   Interrupt_db01_ChangeCharset (stable)
;;     * set charset 0 for next line
;;     * loop not done:
;;       * set next interrupt to Interrupt_db01_DoubleLine 
;;     * loop done:
;;       * set background color for outer frame
;;       * switch to invalid text mode to hide additional char line pixels 
;;       * set Interrupt_db01_openBorder as next interrupt
;; Interrupt_db01_openBorder (unstable)	
;;   * open top/bottom border by setting yscroll register
;;   * set lower sprite positions
;;   * set next interrupt to Interrupt_db01_FirstLine

	
INTERRUPT_DB01_FIRST_SCANLINE = $0d
INTERRUPT_DB01_FIRST_SCANLINE_DOUBLE = $39
INTERRUPT_DB01_FIRST_SCANLINE_CHANGE_CHARSET = $41
INTERRUPT_DB0_LINE_SET_BACKGROUND_COLOR = $31
INTERRUPT_DB0_FIRST_VISIBLE_LINE = $33
INTERRUPT_DB1_LINE_CRUNCH = $30
INTERRUPT_DB01_LINE_OPEN_BORDER = $F8
	
;; 0: show buffer 0 when next frame is started
;; 1: show buffer 1 when next frame is started
interrupt_bufferIndex
!byte 0
	
;; Standard-Value y-scroll:               %00011011
INTERRUPT_DB01_YSCROLL_ROWS24           = %01010011 ; 24 lines and invalid text mode
;;                                                   (ECM/BMM/MCM=1/0/1)
INTERRUPT_DB01_YSCROLL                  = %00011011
INTERRUPT_DB01_YSCROLL_REPEAT           = %00011010
INTERRUPT_DB1_YSCROLL_INVALID_TEXT_MODE = %01011011 ; Invalid text mode (ECM/BMM/MCM=1/0/1) 

INTERRUPT_DB01_INDEX_RESET_VALUE = 23
interrupt_db01_index
!byte INTERRUPT_DB01_INDEX_RESET_VALUE

interrupt_db01_rasterlines
!byte INTERRUPT_DB01_FIRST_SCANLINE_CHANGE_CHARSET+(22*8), INTERRUPT_DB01_FIRST_SCANLINE_DOUBLE+(22*8), INTERRUPT_DB01_FIRST_SCANLINE_CHANGE_CHARSET+(20*8), INTERRUPT_DB01_FIRST_SCANLINE_DOUBLE+(20*8), INTERRUPT_DB01_FIRST_SCANLINE_CHANGE_CHARSET+(18*8), INTERRUPT_DB01_FIRST_SCANLINE_DOUBLE+(18*8), INTERRUPT_DB01_FIRST_SCANLINE_CHANGE_CHARSET+(16*8), INTERRUPT_DB01_FIRST_SCANLINE_DOUBLE+(16*8), INTERRUPT_DB01_FIRST_SCANLINE_CHANGE_CHARSET+(14*8), INTERRUPT_DB01_FIRST_SCANLINE_DOUBLE+(14*8), INTERRUPT_DB01_FIRST_SCANLINE_CHANGE_CHARSET+(12*8), INTERRUPT_DB01_FIRST_SCANLINE_DOUBLE+(12*8), INTERRUPT_DB01_FIRST_SCANLINE_CHANGE_CHARSET+(10*8), INTERRUPT_DB01_FIRST_SCANLINE_DOUBLE+(10*8), INTERRUPT_DB01_FIRST_SCANLINE_CHANGE_CHARSET+(8*8), INTERRUPT_DB01_FIRST_SCANLINE_DOUBLE+(8*8), INTERRUPT_DB01_FIRST_SCANLINE_CHANGE_CHARSET+(6*8), INTERRUPT_DB01_FIRST_SCANLINE_DOUBLE+(6*8), INTERRUPT_DB01_FIRST_SCANLINE_CHANGE_CHARSET+(4*8), INTERRUPT_DB01_FIRST_SCANLINE_DOUBLE+(4*8), INTERRUPT_DB01_FIRST_SCANLINE_CHANGE_CHARSET+(2*8), INTERRUPT_DB01_FIRST_SCANLINE_DOUBLE+(2*8), INTERRUPT_DB01_FIRST_SCANLINE_CHANGE_CHARSET+(0*8), INTERRUPT_DB01_FIRST_SCANLINE_DOUBLE+(0*8)
	
Interrupt_nmiRoutine
  rti ;; exit interrupt not acknowledged

Interrupt_init
  sei  ;; switch off interrupt

  ;disable both CIA timer interrupts 	
  lda #$7f			
  sta $dc0d  
  sta $dd0d  

  ;cancel any pending CIA interrupts
  lda $dc0d  
  lda $dd0d  

  ;; set PLA to all RAM except D000-Dfff 
  lda #%00110101
  sta $01 

  ; set nmi vector to nmiRoutine
  lda #<Interrupt_nmiRoutine 
  sta $FFFA		     	
  lda #>Interrupt_nmiRoutine
  sta $FFFB

  lda #$00  ;; stop timer A
  sta $DD0E 
  sta $DD04 ;; set timer A to 0
  sta $DD05 ;; nmi will occur immediately
  lda #$81  
  sta $DD0D ;; set timer A as source for NMI 
  lda #$01  
  sta $DD0E ;; start timer A -> NMI
  ;; from here on NMI is disabled

  asl $d019 ;; acknowledge VIC interrupts
  cli ;; enable interrupt
  rts

Interrupt_start
  sei       ;; switch off interrupt
  ldx #$01
  stx $d01a ;; Turn on raster interrupts

  lda $d011 
  and #%01111111
  sta $d011 ;; Clear high bit of interrupt rasterline

;;   lda #INTERRUPT_DB01_INDEX_RESET_VALUE ; reset loop index for double text line
;;   sta interrupt_db01_index		; and charset switch interrupts

  ldy #INTERRUPT_DB01_FIRST_SCANLINE
  lda #<Interrupt_db01_FirstLine ;; low part of address of interrupt code
  ldx #>Interrupt_db01_FirstLine ;; high part of address of interrupt code
  sta $fffe ;; store in interrupt vector
  stx $ffff
  sty $d012

  cli ;; enable interrupt
  rts

Interrupt_cycle
  pha ;; store registers in stack
  txa
  pha
  tya
  pha

  ;; Set up interrupt vector
  lda #<Interrupt_unstable
  sta $fffe
  lda #>Interrupt_unstable
  sta $ffff

  tsx ;; Store current Stack Pointer since it is modified in next interrupt
   
  inc $d012 ;; trigger interrupt in next raster line
  asl $d019 ;; acknowledge interrupt 
  cli ;; allow interrupt 

  ;; Execute nop untill the raster line changes and the raster interrupt is triggered
  ;; to have a predictable state when interrupt happens
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  ;; add extra nops for 65 cycle ntsc machines
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop

Interrupt_unstable:	
  ;; Here the jitter is maximal 1 cycle.
  txs ; restore stack pointer since it was modified by the interrupt

  ;; Check if $d012 is incremented and rectify with an aditional cycle if neccessary
  lda $d012  ; check if $d012 is incremented 
  cmp $d012  ; zero-flag indicates jitter=0 or jitter=1

  ; the next beq-jump must not be a jump to the next page to avoid an extra cycle! 
  beq Interrupt_Stable ; add one cycle for jitter=0
  ; now jitter is 0 cycles 
Interrupt_Stable
  ;; Stable code

Interrupt_StableJmp
  jmp $0000 ; the jump address is set by other interrupts before stable interrupt is called

Interrupt_db01_FirstLine
  pha ;; store registers in stack
  txa
  pha
  tya
  pha

  lda $d018
  and #%11110001 
  ora #%00001000 ; $D018 = %xxxx010x -> charmem is at $2000
  sta $d018

  ldy #INTERRUPT_DB1_YSCROLL_INVALID_TEXT_MODE ; Invalid text mode (ECM/BMM/MCM=1/0/1)
                                               ; and reset yscroll register for opening border
  sty $d011
	
  lda #INTERRUPT_DB01_INDEX_RESET_VALUE ; reset double line/switch charset loop index
  sta interrupt_db01_index

  jsr Sprites_cycle		; animate upper/lower sprites
  jsr Sprites_setUpper		; set upper sprite positions
	
  lda interrupt_bufferIndex
  beq Interrupt_db01_FirstLineNextInterruptBuffer0 ; show buffer 0 or 1?

;; set next interrupt for buffer 1
  lda #<Interrupt_db1_LineCrunch ;; low part of address of interrupt code
  ldx #>Interrupt_db1_LineCrunch ;; high part of address of interrupt code
  sta Interrupt_StableJmp+1
  stx Interrupt_StableJmp+2
  ldy #INTERRUPT_DB1_LINE_CRUNCH 
  lda #<Interrupt_cycle ;; low part of address of interrupt handler code
  ldx #>Interrupt_cycle ;; high part of address of interrupt handler code
  sta $fffe ;; store in interrupt vector
  stx $ffff
  sty $d012

  asl $d019 ;; acknowledge interrupt (to re-enable it)
  pla ;; restore stack
  tay
  pla
  tax
  pla
  rti ;; return from interrupt
	
;; set next interrupt for buffer 0
Interrupt_db01_FirstLineNextInterruptBuffer0
  lda #<Interrupt_db0_SetBackgroundColor ;; low part of address of interrupt code
  ldx #>Interrupt_db0_SetBackgroundColor ;; high part of address of interrupt code
  ldy #INTERRUPT_DB0_LINE_SET_BACKGROUND_COLOR
  sta $fffe ;; store in interrupt vector
  stx $ffff
  sty $d012

  asl $d019 ;; acknowledge interrupt (to re-enable it)
  pla ;; restore stack
  tay
  pla
  tax
  pla
  rti ;; return from interrupt

Interrupt_db0_SetBackgroundColor
  pha ;; store registers in stack
  txa
  pha
  tya
  pha

  lda #INTERRUPT_DB01_YSCROLL	; switch to valid text mode to show first line
  sta $d011

  ;; wait for the needed position in rasterline
  ;; use wait time for useful things... 
  lda #<Interrupt_db01_DoubleLine ;; low part of address of interrupt code
  sta Interrupt_StableJmp+1
  ldy #>Interrupt_db01_DoubleLine ;; high part of address of interrupt code
  ;; wait done
  lda #DISPLAY_COLOR_BACKGROUND_INNER_FRAME
  ldx #INTERRUPT_DB0_FIRST_VISIBLE_LINE-1
Interrupt_db0_SetBackgroundColorLoop
  cpx $d012
  bne Interrupt_db0_SetBackgroundColorLoop
  ;; wait for the needed position in rasterline
  ;; use wait time for useful things... 
  sty Interrupt_StableJmp+2	
  ldx interrupt_db01_index	
  ldy interrupt_db01_rasterlines,x	
  sty $d012 
  ldx #<Interrupt_cycle ;; low part of address of interrupt handler code
  ldy #>Interrupt_cycle ;; high part of address of interrupt handler code
  stx $fffe ;; store interrupt vector
  sty $ffff 
  ;; wait: nop can be replaced by useful code
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  ;;  wait done
  sta $d021 ;; set inner frame background color

  asl $d019 ;; acknowledge interrupt (to re-enable it)
  pla ;; restore stack
  tay
  pla
  tax
  pla
  rti ;; return from interrupt

Interrupt_db1_LineCrunch
  ;; wait for the needed position in rasterline
  ;; use wait time for useful things... 
  ldx $d012 ; remember current rasterline 
  inx
  nop	
  nop	
  nop
  nop
  nop
  nop
  nop
  nop
  ;;  wait done

  ;; do one linecrunch and switch on invalid text mode
  ;; to get black pixels in crunched line
  lda $d012 ; 
  and #%00000111
  ora #%01011000		; line crunch and invalid text mode (ECM/BMM/MCM=1/0/1) 
  sta $d011
Interrupt_db1_LineCrunchInvalidTextModeLoop
  cpx $d012
  bne Interrupt_db1_LineCrunchInvalidTextModeLoop
  lda #DISPLAY_COLOR_BACKGROUND_INNER_FRAME
  ;; wait for the needed position in rasterline
  ;; use wait time for useful things... 
  ldy #<Interrupt_db01_DoubleLine ;; low part of address of interrupt code 
  ldx #>Interrupt_db01_DoubleLine ;; high part of address of interrupt code 
  sty Interrupt_StableJmp+1	  
  stx Interrupt_StableJmp+2	  
  ldx interrupt_db01_index	  
  ldy interrupt_db01_rasterlines,x	  
  sty $d012 
  ldy #<Interrupt_cycle ;; low part of address of interrupt handler code
  ldx #>Interrupt_cycle ;; high part of address of interrupt handler code
  sty $fffe ;; store in interrupt vector
  stx $ffff 
  ;; nop can be replaced by useful code
  nop
  nop
  nop	
  nop	
  nop	
  nop	
  nop	
  nop	
  ;;  wait done

  sta $d021
  lda #INTERRUPT_DB01_YSCROLL	; set back to original value to show next line
  sta $d011

  asl $d019 ;; acknowledge interrupt (to re-enable it)
  pla ;; restore stack
  tay
  pla
  tax
  pla
  rti ;; return from interrupt
	
Interrupt_db01_DoubleLine
  ;; wait for the needed position in rasterline
  ;; use wait time for useful things... 

  lda #<Interrupt_db01_ChangeCharset ;; low part of address of interrupt code
  ldx #>Interrupt_db01_ChangeCharset ;; high part of address of interrupt code
  sta Interrupt_StableJmp+1
  stx Interrupt_StableJmp+2
	
  lda #<Interrupt_cycle ;; low part of address of interrupt handler code
  ldx #>Interrupt_cycle ;; high part of address of interrupt handler code
  sta $fffe ;; store in interrupt vector
  stx $ffff
  ;;  wait done

  ;; repeat char-line
  lda #INTERRUPT_DB01_YSCROLL_REPEAT
  sta $d011

  ;; wait for the needed position in rasterline
  ;; use wait time for useful things... 
  lda $d018
  and #%11110001 
  ora #%00001010 ; $D018 = %xxxx011x -> charmem is at $2800
  sta $d018

  dec interrupt_db01_index
  ldx interrupt_db01_index
  ldy interrupt_db01_rasterlines,x
  sty $d012
  asl $d019 ;; acknowledge interrupt (to re-enable it)

  pla ;; restore stack
  tay
  pla
  tax
 
  ;; wait a few more cycles, can be replaced by useful code
  nop
  nop
  nop
  nop
  nop
  nop
  ;; wait done
  lda #INTERRUPT_DB01_YSCROLL  ; set back to original value
  sta $d011
	
  pla
  rti ;; return from interrupt

Interrupt_db01_ChangeCharset
  ;; wait for the needed position in rasterline
  ;; use wait time for useful things... 
  lda #<Interrupt_db01_DoubleLine ;; low part of address of interrupt code
  ldx #>Interrupt_db01_DoubleLine ;; high part of address of interrupt code
  sta Interrupt_StableJmp+1
  stx Interrupt_StableJmp+2
  lda #<Interrupt_cycle ;; low part of address of interrupt handler code
  sta $fffe ;; store in interrupt vector
  ;; wait done
  lda $d018
  and #%11110001 
  ora #%00001000 ; $D018 = %xxxx010x -> charmem is at $2000
  sta $d018
  lda interrupt_db01_index
  bne Interrupt_db01_ChangeCharsetSetNextInterruptToDoubleLine
  ;; last line in inner boder was drawn, set invalid text mode 
  ;; to hide last line with arbitrary data in it 
  ;; this has to be done at this position due to timing issues
  lda #INTERRUPT_DB1_YSCROLL_INVALID_TEXT_MODE ; Invalid text mode (ECM/BMM/MCM=1/0/1)
  sta $d011
  ;; inner border is done, so set background color for upper/lower border
  lda #DISPLAY_COLOR_BACKGROUND_UPPER_LOWER_BORDER
  sta $d021

Interrupt_db01_ChangeCharsetSetNextInterruptToDoubleLine
  dec interrupt_db01_index
  bmi Interrupt_db01_ChangeCharsetIndexNegative ; double line/switch charset loop done?
  ldx #>Interrupt_cycle ;; high part of address of interrupt handler code
  stx $ffff
  ldx interrupt_db01_index
  ldy interrupt_db01_rasterlines,x
  sty $d012
  asl $d019 ;; acknowledge interrupt (to re-enable it)
  pla ;; restore stack
  tay
  pla
  tax
  pla
  rti ;; return from interrupt
  ;;  negative: double line/switch charset loop done!
Interrupt_db01_ChangeCharsetIndexNegative
  ldy #INTERRUPT_DB01_LINE_OPEN_BORDER
  lda #<Interrupt_db01_openBorder ;; low part of address of interrupt code
  ldx #>Interrupt_db01_openBorder ;; high part of address of interrupt code
  sta $fffe ;; store in interrupt vector
  stx $ffff
  sty $d012
  asl $d019 ;; acknowledge interrupt (to re-enable it)
  pla ;; restore stack
  tay
  pla
  tax
  pla
  rti ;; return from interrupt

Interrupt_db01_openBorder
  pha ;; store registers in stack
  txa
  pha
  tya
  pha

  lda #INTERRUPT_DB01_YSCROLL_ROWS24	; set scroll register to open border
  sta $d011

  jsr Sprites_setLower		; set lower sprite positions

  ldy #INTERRUPT_DB01_FIRST_SCANLINE
  lda #<Interrupt_db01_FirstLine ;; low part of address of interrupt code
  ldx #>Interrupt_db01_FirstLine ;; high part of address of interrupt code
  sta $fffe ;; store in interrupt vector
  stx $ffff
  sty $d012
  asl $d019 ;; acknowledge interrupt (to re-enable it)
  pla ;; restore stack
  tay
  pla
  tax
  pla
  rti ;; return from interrupt
