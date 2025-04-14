BASIC_START = $0801		
CODE_START = $1000
	
* = BASIC_START
!byte 12,8,0,0,158
!if CODE_START >= 10000 {!byte 48+((CODE_START/10000)%10)}
!if CODE_START >= 1000 {!byte 48+((CODE_START/1000)%10)}
!if CODE_START >= 100 {!byte 48+((CODE_START/100)%10)}
!if CODE_START >= 10 {!byte 48+((CODE_START/10)%10)}
!byte 48+(CODE_START % 10),0,0,0

;; ensure the time critical rasterline routines are always
;; at the same memory position to avoid different timing
;; due to extra page-fault cycles for conditional branches
!src "interrupt.asm"
!src "display.asm"
!src "sprites.asm"			

* = CODE_START
  jsr Interrupt_init
  jsr Display_init
  jsr Sprites_init
  jsr Interrupt_start
	
EndlessLoop
WaitForInterruptBit8IsOne
  lda $d011
  bpl WaitForInterruptBit8IsOne
WaitForInterruptBit8IsZero
  lda $d011
  bmi WaitForInterruptBit8IsZero
  lda #60
WaitForRasterLine
  cmp $d012
  bcs WaitForRasterLine
	
  lda interrupt_bufferIndex	; get current buffer index
  beq SetBuffer1		; current buffer=0 -> draw and set buffer 1
  jsr Display_drawBuffer0	; draw and show buffer 0
  jsr Display_showBuffer0
  jmp EndlessLoop
SetBuffer1
  jsr Display_drawBuffer1	; draw and show buffer 1
  jsr Display_showBuffer1
  jsr Display_scrollColors      ; color scrolling
  jmp EndlessLoop
	
;; charset0
;; define chars 0 and 1
* = $2000
charset0char0	
!byte $55,$6A,$6A,$6C,$6C,$6C,$6C,$6C
charset0char1	
!byte $55,$6A,$6A,$63,$63,$63,$63,$63
	
;; charset1
;; define chars 0 and 1
* = $2800
charset1char0	
!byte $6C,$6C,$6C,$6C,$6C,$6C,$6C,$55
charset1char1
!byte $63,$63,$63,$63,$63,$63,$63,$55
	
;; sprites
;; 16 rotated car sprites
* = $3000
carAnimation0
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0f,$00,$00,$0f
!byte $00,$00,$0a,$a3,$c0,$0a,$a3,$c0,$19,$fa,$60,$19,$fa,$60,$1a,$7d
!byte $a8,$1a,$7d,$a8,$19,$fa,$60,$19,$fa,$60,$0a,$a3,$c0,$0a,$a3,$c0
!byte $0f,$00,$00,$0f,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$85
carAnimation1
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$00
!byte $0f,$20,$0c,$0d,$a8,$3c,$89,$a8,$3a,$a9,$a0,$2a,$fd,$a0,$09,$fd
!byte $60,$19,$7e,$70,$1a,$7a,$f0,$1a,$b8,$c0,$16,$78,$00,$06,$68,$00
!byte $06,$a0,$00,$02,$b0,$00,$00,$f0,$00,$00,$c0,$00,$00,$00,$00,$85
carAnimation2
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0c,$20,$00,$0e,$a0,$00
!byte $3d,$80,$00,$39,$a0,$00,$89,$a0,$0c,$a9,$40,$0e,$ae,$70,$3e,$fe
!byte $f0,$39,$fa,$c0,$39,$78,$c0,$0a,$78,$00,$0a,$ba,$00,$06,$9a,$00
!byte $06,$98,$00,$05,$ac,$00,$01,$ac,$00,$01,$3c,$00,$00,$30,$00,$85
carAnimation3
!byte $00,$00,$80,$00,$00,$80,$00,$0a,$80,$00,$3a,$80,$00,$36,$80,$00
!byte $f6,$80,$00,$e6,$40,$00,$25,$f0,$00,$2e,$f0,$00,$ae,$c0,$02,$be
!byte $00,$02,$fe,$00,$0e,$de,$00,$3e,$5e,$00,$3e,$6e,$00,$3a,$a6,$00
!byte $02,$a6,$c0,$01,$ab,$c0,$01,$5b,$c0,$00,$53,$00,$00,$10,$00,$85
carAnimation4
!byte $00,$08,$00,$00,$08,$00,$00,$2a,$00,$00,$2a,$00,$00,$d9,$c0,$00
!byte $d9,$c0,$00,$e6,$c0,$00,$e6,$c0,$00,$2e,$00,$00,$2e,$00,$00,$bf
!byte $80,$00,$bf,$80,$00,$b7,$80,$00,$b7,$80,$03,$99,$b0,$03,$99,$b0
!byte $03,$aa,$b0,$03,$aa,$b0,$00,$15,$00,$00,$15,$00,$00,$00,$00,$85
carAnimation5
!byte $02,$00,$00,$02,$00,$00,$02,$a0,$00,$02,$ac,$00,$02,$9c,$00,$02
!byte $9f,$00,$01,$9b,$00,$0f,$58,$00,$0f,$b8,$00,$03,$ba,$00,$00,$be
!byte $80,$00,$bf,$80,$00,$b7,$b0,$00,$b5,$bc,$00,$b9,$bc,$00,$9a,$ac
!byte $03,$9a,$80,$03,$ea,$40,$03,$e5,$40,$00,$c5,$00,$00,$04,$00,$85
carAnimation6
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$08,$30,$00,$0a,$b0,$00,$02
!byte $7c,$00,$0a,$6c,$00,$0a,$62,$00,$01,$6a,$30,$0d,$ba,$b0,$0f,$bf
!byte $bc,$03,$af,$6c,$03,$2d,$6c,$00,$2d,$a0,$00,$ae,$a0,$00,$a6,$90
!byte $00,$26,$90,$00,$3a,$50,$00,$3a,$40,$00,$3c,$40,$00,$0c,$00,$85
carAnimation7
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$c0,$00,$08
!byte $f0,$00,$2a,$70,$30,$2a,$62,$3c,$0a,$6a,$ac,$0a,$7f,$a8,$09,$7f
!byte $60,$0d,$bd,$64,$0f,$ad,$a4,$03,$2e,$a4,$00,$2d,$94,$00,$29,$90
!byte $00,$0a,$90,$00,$0e,$80,$00,$0f,$00,$00,$03,$00,$00,$00,$00,$85
carAnimation8
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$f0,$00,$00,$f0,$03
!byte $ca,$a0,$03,$ca,$a0,$09,$af,$64,$09,$af,$64,$2a,$7d,$a4,$2a,$7d
!byte $a4,$09,$af,$64,$09,$af,$64,$03,$ca,$a0,$03,$ca,$a0,$00,$00,$f0
!byte $00,$00,$f0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$85
carAnimation9
!byte $00,$00,$00,$00,$03,$00,$00,$0f,$00,$00,$0e,$80,$00,$0a,$90,$00
!byte $29,$90,$00,$2d,$94,$03,$2e,$a4,$0f,$ad,$a4,$0d,$bd,$64,$09,$7f
!byte $60,$0a,$7f,$a8,$0a,$6a,$ac,$2a,$62,$3c,$2a,$70,$30,$08,$f0,$00
!byte $00,$c0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$85
carAnimation10
!byte $00,$0c,$00,$00,$3c,$40,$00,$3a,$40,$00,$3a,$50,$00,$26,$90,$00
!byte $a6,$90,$00,$ae,$a0,$00,$2d,$a0,$03,$2d,$6c,$03,$af,$6c,$0f,$bf
!byte $bc,$0d,$ba,$b0,$01,$6a,$30,$0a,$62,$00,$0a,$6c,$00,$02,$7c,$00
!byte $0a,$b0,$00,$08,$30,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$85
carAnimation11
!byte $00,$04,$00,$00,$c5,$00,$03,$e5,$40,$03,$ea,$40,$03,$9a,$80,$00
!byte $9a,$ac,$00,$b9,$bc,$00,$b5,$bc,$00,$b7,$b0,$00,$bf,$80,$00,$be
!byte $80,$03,$ba,$00,$0f,$b8,$00,$0f,$58,$00,$01,$9b,$00,$02,$9f,$00
!byte $02,$9c,$00,$02,$ac,$00,$02,$a0,$00,$02,$00,$00,$02,$00,$00,$85
carAnimation12
!byte $00,$00,$00,$00,$15,$00,$00,$15,$00,$03,$aa,$b0,$03,$aa,$b0,$03
!byte $99,$b0,$03,$99,$b0,$00,$b7,$80,$00,$b7,$80,$00,$bf,$80,$00,$bf
!byte $80,$00,$2e,$00,$00,$2e,$00,$00,$e6,$c0,$00,$e6,$c0,$00,$d9,$c0
!byte $00,$d9,$c0,$00,$2a,$00,$00,$2a,$00,$00,$08,$00,$00,$08,$00,$85
carAnimation13
!byte $00,$10,$00,$00,$53,$00,$01,$5b,$c0,$01,$ab,$c0,$02,$a6,$c0,$3a
!byte $a6,$00,$3e,$6e,$00,$3e,$5e,$00,$0e,$de,$00,$02,$fe,$00,$02,$be
!byte $00,$00,$ae,$c0,$00,$2e,$f0,$00,$25,$f0,$00,$e6,$40,$00,$f6,$80
!byte $00,$36,$80,$00,$3a,$80,$00,$0a,$80,$00,$00,$80,$00,$00,$80,$85
carAnimation14
!byte $00,$30,$00,$01,$3c,$00,$01,$ac,$00,$05,$ac,$00,$06,$98,$00,$06
!byte $9a,$00,$0a,$ba,$00,$0a,$78,$00,$39,$78,$c0,$39,$fa,$c0,$3e,$fe
!byte $f0,$0e,$ae,$70,$0c,$a9,$40,$00,$89,$a0,$00,$39,$a0,$00,$3d,$80
!byte $00,$0e,$a0,$00,$0c,$20,$00,$00,$00,$00,$00,$00,$00,$00,$00,$85
carAnimation15
!byte $00,$00,$00,$00,$c0,$00,$00,$f0,$00,$02,$b0,$00,$06,$a0,$00,$06
!byte $68,$00,$16,$78,$00,$1a,$b8,$c0,$1a,$7a,$f0,$19,$7e,$70,$09,$fd
!byte $60,$2a,$fd,$a0,$3a,$a9,$a0,$3c,$89,$a8,$0c,$0d,$a8,$00,$0f,$20
!byte $00,$03,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$85
