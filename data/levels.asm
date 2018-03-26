;;;;;;;;;;;;
;; LEVELS ;;
;;;;;;;;;;;;

; Information about levels

;;;;;;;;;;;;;;
;; PALETTES ;;
;;;;;;;;;;;;;;

palette_text:
  .incbin "SpaceGraphics\palettes\text.pal"
  
palette_spr0:
  .incbin "SpaceGraphics\palettes\spr0.pal"
  
palette_bg0
  .incbin "SpaceGraphics\palettes\bg0.pal"
  
palette_bg1
  .incbin "SpaceGraphics\palettes\bg1.pal"
  
;;;;;;;;;;;;;;;;
;; NAMETABLES ;;
;;;;;;;;;;;;;;;;
  
ntTitle:
  .incbin "SpaceGraphics\backgrounds\title.nam"

ntPassword:
  .incbin "SpaceGraphics\backgrounds\password.nam"
  
space_0:
  .incbin "SpaceGraphics\backgrounds\space_0.nam"

space_1:
  .incbin "SpaceGraphics\backgrounds\space_1.nam"
  
big_island:
  .incbin "SpaceGraphics\backgrounds\big_island.nam"

two_islands
  .incbin "SpaceGraphics\backgrounds\two_islands.nam"
  
;;;;;;;;;;;;;;;;;
;; BACKGROUNDS ;;
;;;;;;;;;;;;;;;;;

; Holds information about levels backgrounds

; Level backgrounds lookup table
  
levelBackgrounds:
  .byte HIGH(level_0_bg), LOW(level_0_bg)
  .byte HIGH(level_1_bg), LOW(level_1_bg)

; Layout of the level background information:
;
; pointer to the bg. palette
; pointer to the sprite palette
; scroll speed
; number of screens
; pointers to nametables
    
;;;;;;;;;;;;;
;; ENEMIES ;;
;;;;;;;;;;;;;

; Holds information about enemies on each level

; Main lookup table: level number => enemies on screens

levelEnemies:
  .byte HIGH(level_0_en), LOW(level_0_en)
  .byte HIGH(level_1_en), LOW(level_1_en)
  
; Then there's a lookup table to per-screen data, something like:
;
;level_0_en:
;  .byte HIGH(level_0_00_en),   LOW(level_0_00_en)
;  .byte HIGH(level_0_01_en),   LOW(level_0_01_en)
;  .byte HIGH(level_0_02_en),   LOW(level_0_02_en)
;  .byte HIGH(level_0_03_en),   LOW(level_0_03_en)

; Finally there's the per screen data:
;
; line number (239 being earliest and 8 latest)
; enemy to spawn (index)
; initial X
; initial Y
;
; FF as line number means EOD

;;;;;;;;;;;;
;; STAGES ;;
;;;;;;;;;;;;

; Information about which level is which level/stage #
; It's a lookup table, 8 bytes per level:
;   - level number string address
;   - stage number string address
;   - password string address
;   - two zeros for padding

levelStages:
  .byte HIGH(strLevel1), LOW(strLevel1), HIGH(strStage1), LOW(strStage1), HIGH(strStagePasswordBSRW), LOW(strStagePasswordBSRW), $00, $00
  .byte HIGH(strLevel1), LOW(strLevel1), HIGH(strStage2), LOW(strStage2), HIGH(strStagePasswordMJTD), LOW(strStagePasswordMJTD), $00, $00

;;;;;;;;;;;;;;;;
;; LEVEL DATA ;;
;;;;;;;;;;;;;;;;

  .include "data\levels\level1.asm"
  .include "data\levels\level2.asm"