;;;;;;;;;;;;;;;;;;;
;; LOOKUP TABLES ;;
;;;;;;;;;;;;;;;;;;;

; Random lookup tables that don't fit anywhere else:

; Sinusoidal move sequence:
moveSinus:
  .byte $00, $04
  .byte $02, $04
  .byte $03, $04
  .byte $02, $04
  .byte $00, $04
  .byte $FE, $04
  .byte $FD, $04
  .byte $FE, $04

; HP/XP bar tiles lookup:
bar_lookup_0:
  .byte BAR_0_4, BAR_0_4, BAR_0_4, BAR_0_4, BAR_0_4, BAR_1_4, BAR_2_4, BAR_3_4, BAR_4_4 

bar_lookup_1:
  .byte BAR_0_4, BAR_1_4, BAR_2_4, BAR_3_4, BAR_4_4, BAR_4_4, BAR_4_4, BAR_4_4, BAR_4_4

; Password screen selector movement and position:
movementUp:
 .byte $12, $13, $14, $15, $16, $17, $18, $19, $11
 .byte $00, $01, $02, $03, $04, $05, $06, $07, $08
 .byte $09, $0A, $0B, $0C, $0D, $0E, $0F, $10

movementDown:
 .byte $09, $0A, $0B, $0C, $0D, $0E, $0F, $10, $11
 .byte $12, $13, $14, $15, $16, $17, $18, $19, $08
 .byte $00, $01, $02, $03, $04, $05, $06, $07
 
movementLeft:
 .byte $08, $00, $01, $02, $03, $04, $05, $06, $07
 .byte $11, $09, $0A, $0B, $0C, $0D, $0E, $0F, $10
 .byte $19, $12, $13, $14, $15, $16, $17, $18

movementRight:
  .byte $01, $02, $03, $04, $05, $06, $07, $08, $00
  .byte $0A, $0B, $0C, $0D, $0E, $0F, $10, $11, $09
  .byte $13, $14, $15, $16, $17, $18, $19, $12
  
selectorX:
  .byte $30, $40, $50, $60, $70, $80, $90, $A0, $B0
  .byte $30, $40, $50, $60, $70, $80, $90, $A0, $B0
  .byte $30, $40, $50, $60, $70, $80, $90, $A0
  
selectorY:
  .byte $67, $67, $67, $67, $67, $67, $67, $67, $67
  .byte $77, $77, $77, $77, $77, $77, $77, $77, $77
  .byte $87, $87, $87, $87, $87, $87, $87, $87
