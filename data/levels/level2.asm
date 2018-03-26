;;;;;;;;;;;;;
;; LEVEL 1 ;;
;;;;;;;;;;;;;

level_1_bg:                                    ; background data
  .byte HIGH(palette_bg1),  LOW(palette_bg1)   ; pointer to bg. palette
  .byte HIGH(palette_spr0), LOW(palette_spr0)  ; pointer to sprite palette
  .byte $01                                    ; scroll speed
  .byte $06                                    ; number of screens
  .byte HIGH(space_0),      LOW(space_0)       ; list of screens
  .byte HIGH(space_1),      LOW(space_1)
  .byte HIGH(space_0),      LOW(space_0)
  .byte HIGH(space_1),      LOW(space_1)
  .byte HIGH(space_0),      LOW(space_0)
  .byte HIGH(space_1),      LOW(space_1)
  ;.byte HIGH(space_0),      LOW(space_0)
  ;.byte HIGH(space_1),      LOW(space_1)
  ;.byte HIGH(space_0),      LOW(space_0)
  ;.byte HIGH(space_1),      LOW(space_1)
  ;.byte HIGH(space_0),      LOW(space_0)
  ;.byte HIGH(space_1),      LOW(space_1)
  ;.byte HIGH(space_0),      LOW(space_0)
  ;.byte HIGH(space_1),      LOW(space_1)
  ;.byte HIGH(space_0),      LOW(space_0)
  ;.byte HIGH(space_1),      LOW(space_1)  

level_1_en:                                        ; enemies per screen data
  .byte HIGH(level_1_00_en),   LOW(level_1_00_en)  ; list of screens  
  .byte HIGH(level_1_01_en),   LOW(level_1_01_en)
  .byte HIGH(level_1_02_en),   LOW(level_1_02_en)
  .byte HIGH(level_1_03_en),   LOW(level_1_03_en)
  .byte HIGH(level_1_04_en),   LOW(level_1_04_en)
  .byte HIGH(level_1_05_en),   LOW(level_1_05_en)
  ;.byte HIGH(level_1_06_en),   LOW(level_1_06_en)
  ;.byte HIGH(level_1_07_en),   LOW(level_1_07_en)
  ;.byte HIGH(level_1_08_en),   LOW(level_1_08_en)
  ;.byte HIGH(level_1_09_en),   LOW(level_1_09_en)
  ;.byte HIGH(level_1_10_en),   LOW(level_1_10_en)
  ;.byte HIGH(level_1_11_en),   LOW(level_1_11_en)
  ;.byte HIGH(level_1_12_en),   LOW(level_1_12_en)
  ;.byte HIGH(level_1_13_en),   LOW(level_1_13_en)
  ;.byte HIGH(level_1_14_en),   LOW(level_1_14_en)
  ;.byte HIGH(level_1_15_en),   LOW(level_1_15_en)

level_1_00_en:
  .byte $FF

level_1_01_en:

  ; wave of spiders
  .byte $C0, SPIDER_ID, $30, $00
  .byte $B8, SPIDER_ID, $44, $00
  .byte $B0, SPIDER_ID, $58, $00
  .byte $A8, SPIDER_ID, $6C, $00
  .byte $A0, SPIDER_ID, $80, $00
  .byte $98, SPIDER_ID, $94, $00
  .byte $90, SPIDER_ID, $A8, $00
  .byte $88, SPIDER_ID, $BC, $00
  
  ; 2nd wave of spiders
  .byte $48, SPIDER_ID, $BC, $00
  .byte $40, SPIDER_ID, $A8, $00
  .byte $38, SPIDER_ID, $94, $00
  .byte $30, SPIDER_ID, $80, $00
  .byte $28, SPIDER_ID, $6C, $00
  .byte $20, SPIDER_ID, $58, $00
  .byte $18, SPIDER_ID, $44, $00
  .byte $10, SPIDER_ID, $30, $00

  .byte $FF
  
level_1_02_en:

  ; wave of spiders
  .byte $C0, SPIDER_ID, $30, $00
  .byte $B8, SPIDER_ID, $44, $00
  .byte $B0, SPIDER_ID, $58, $00
  .byte $A8, SPIDER_ID, $6C, $00
  .byte $A0, SPIDER_ID, $80, $00
  .byte $98, SPIDER_ID, $94, $00
  .byte $90, SPIDER_ID, $A8, $00
  .byte $88, SPIDER_ID, $BC, $00
  
  ; 2nd wave of spiders
  .byte $48, SPIDER_ID, $BC, $00
  .byte $40, SPIDER_ID, $A8, $00
  .byte $38, SPIDER_ID, $94, $00
  .byte $30, SPIDER_ID, $80, $00
  .byte $28, SPIDER_ID, $6C, $00
  .byte $20, SPIDER_ID, $58, $00
  .byte $18, SPIDER_ID, $44, $00
  .byte $10, SPIDER_ID, $30, $00

  .byte $FF
  
level_1_03_en:

  ; two sweepers going right
  .byte $E8, SWEEPER_R_ID, $00, $20
  .byte $98, SWEEPER_R_ID, $00, $20  
  .byte $FF
 
level_1_04_en:

  ; two of sweepers going left
  .byte $78, SWEEPER_L_ID, $EF, $20
  .byte $28, SWEEPER_L_ID, $EF, $20  
  .byte $FF

level_1_05_en:
  .byte $FF

;level_1_06_en:
;  .byte $FF

;level_1_07_en:
;  .byte $FF
;
;level_1_08_en:
;  .byte $FF
;
;level_1_09_en:
;  .byte $FF
;
;level_1_10_en:
;  .byte $FF
;
;level_1_11_en:
;  .byte $FF
;
;level_1_12_en:
;  .byte $FF
;
;level_1_13_en:
;  .byte $FF
;
;level_1_14_en:
;  .byte $FF
;
;level_1_15_en:
;  .byte $FF