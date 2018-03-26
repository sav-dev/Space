;;;;;;;;;;;;;
;; LEVEL 1 ;;
;;;;;;;;;;;;;

level_0_bg:                                    ; background data
  .byte HIGH(palette_bg0),  LOW(palette_bg0)   ; pointer to bg. palette
  .byte HIGH(palette_spr0), LOW(palette_spr0)  ; pointer to sprite palette
  .byte $01                                    ; scroll speed
  .byte $06                                    ; number of screens
  .byte HIGH(space_0),      LOW(space_0)       ; list of screens
  .byte HIGH(space_1),      LOW(space_1)
  .byte HIGH(space_0),      LOW(space_0)
  .byte HIGH(space_1),      LOW(space_1)
  .byte HIGH(space_0),      LOW(space_0)
  .byte HIGH(space_1),      LOW(space_1)

level_0_en:                                        ; enemies per screen data
  .byte HIGH(level_0_00_en),   LOW(level_0_00_en)  ; list of screens  
  .byte HIGH(level_0_01_en),   LOW(level_0_01_en)
  .byte HIGH(level_0_02_en),   LOW(level_0_02_en)
  .byte HIGH(level_0_03_en),   LOW(level_0_03_en)
  .byte HIGH(level_0_04_en),   LOW(level_0_04_en)
  .byte HIGH(level_0_05_en),   LOW(level_0_05_en)

level_0_00_en:
  .byte $FF

level_0_01_en:

  ; eight spiders
  .byte $C0, SPIDER_ID, $30, $00
  .byte $B8, SPIDER_ID, $44, $00
  .byte $B0, SPIDER_ID, $58, $00
  .byte $A8, SPIDER_ID, $6C, $00
  .byte $A0, SPIDER_ID, $80, $00
  .byte $98, SPIDER_ID, $94, $00
  .byte $90, SPIDER_ID, $A8, $00
  .byte $88, SPIDER_ID, $BC, $00
  
  ; eight spiders
  .byte $68, SPIDER_ID, $BC, $00
  .byte $60, SPIDER_ID, $A8, $00
  .byte $58, SPIDER_ID, $94, $00
  .byte $50, SPIDER_ID, $80, $00
  .byte $48, SPIDER_ID, $6C, $00
  .byte $40, SPIDER_ID, $58, $00
  .byte $38, SPIDER_ID, $44, $00
  .byte $30, SPIDER_ID, $30, $00

  ; two gunships
  .byte $10, GUNSHIP_ID, $20, $00
  .byte $08, GUNSHIP_ID, $D0, $00
  
  .byte $FF

level_0_02_en:

  ; two sweepers going right
  .byte $E8, SWEEPER_R_ID, $00, $20
  .byte $A8, SWEEPER_R_ID, $00, $20  
  
  ; four spiders
  .byte $A0, SPIDER_ID, $54, $00
  .byte $98, SPIDER_ID, $6C, $00
  .byte $90, SPIDER_ID, $80, $00
  .byte $88, SPIDER_ID, $94, $00
 
  ; two of sweepers going left
  .byte $78, SWEEPER_L_ID, $EF, $40
  .byte $38, SWEEPER_L_ID, $EF, $40
 
  .byte $FF
  
level_0_03_en:  
  
  ; two gunships
  .byte $D8, GUNSHIP_ID, $20, $00
  .byte $D0, GUNSHIP_ID, $50, $00
  .byte $C8, GUNSHIP_ID, $A0, $00
  .byte $C0, GUNSHIP_ID, $D0, $00
  
  .byte $FF
  
level_0_04_en:

  ; four of drones
  .byte $E8, DRONE_ID, $30, $00
  .byte $E0, DRONE_ID, $58, $00
  .byte $D8, DRONE_ID, $80, $00
  .byte $D0, DRONE_ID, $BC, $00

  ; two gunships
  .byte $C8, GUNSHIP_ID, $20, $00
  .byte $C0, GUNSHIP_ID, $D0, $00
  
  ; two sweepers going right
  .byte $A8, SWEEPER_R_ID, $00, $20
  .byte $A0, SWEEPER_L_ID, $EF, $34  
  
  ; six drones
  .byte $40, DRONE_ID, $94, $00
  .byte $38, DRONE_ID, $80, $00
  .byte $30, DRONE_ID, $6C, $00
  .byte $28, DRONE_ID, $44, $00
  .byte $20, DRONE_ID, $58, $00
  .byte $18, DRONE_ID, $A8, $00
  
  .byte $FF
  
level_0_05_en:
  .byte $FF