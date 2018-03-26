;;;;;;;;;;;;
;; LEVELS ;;
;;;;;;;;;;;;

; Contains string data

; Format:
;   Length
;   Position in nametable (high)
;   Position in nametable (low)
;   Tiles

strPressStart:
  .byte $0C        
  .byte $22, $EA   
  .byte CHAR_P
  .byte CHAR_R
  .byte CHAR_E
  .byte CHAR_S
  .byte CHAR_S
  .byte CHAR_SPACE
  .byte CHAR_SPACE
  .byte CHAR_S
  .byte CHAR_T
  .byte CHAR_A
  .byte CHAR_R
  .byte CHAR_T
  
strPressStartBlank:
  .byte $0C        
  .byte $22, $EA   
  .byte CHAR_SPACE
  .byte CHAR_SPACE
  .byte CHAR_SPACE
  .byte CHAR_SPACE
  .byte CHAR_SPACE
  .byte CHAR_SPACE
  .byte CHAR_SPACE
  .byte CHAR_SPACE
  .byte CHAR_SPACE
  .byte CHAR_SPACE
  .byte CHAR_SPACE
  .byte CHAR_SPACE
  
strNewGame:
  .byte $08        
  .byte $22, $CD   
  .byte CHAR_N
  .byte CHAR_E
  .byte CHAR_W
  .byte CHAR_SPACE
  .byte CHAR_G
  .byte CHAR_A
  .byte CHAR_M
  .byte CHAR_E
  
strPassword:
  .byte $08        
  .byte $23, $0D   
  .byte CHAR_P
  .byte CHAR_A
  .byte CHAR_S
  .byte CHAR_S
  .byte CHAR_W
  .byte CHAR_O
  .byte CHAR_R
  .byte CHAR_D
  
strLevel:
  .byte $05        
  .byte $21, $4C   
  .byte CHAR_L
  .byte CHAR_E
  .byte CHAR_V
  .byte CHAR_E
  .byte CHAR_L
  
strStage:
  .byte $05        
  .byte $21, $8C   
  .byte CHAR_S
  .byte CHAR_T
  .byte CHAR_A
  .byte CHAR_G
  .byte CHAR_E
  
strLevel1:
  .byte $01        
  .byte $21, $53   
  .byte CHAR_1
  
strStage1:
  .byte $01
  .byte $21, $93   
  .byte CHAR_1

strLevel2:
  .byte $01        
  .byte $21, $53   
  .byte CHAR_2
  
strStage2:
  .byte $01
  .byte $21, $93   
  .byte CHAR_2
  
strLevel3:
  .byte $01        
  .byte $21, $53   
  .byte CHAR_3
  
strStage3:
  .byte $01
  .byte $21, $93   
  .byte CHAR_3
  
strLevel4:
  .byte $01        
  .byte $21, $53   
  .byte CHAR_4
  
strStage4:
  .byte $01
  .byte $21, $93   
  .byte CHAR_4
  
strStagePassword:
  .byte $08        
  .byte $22, $09   
  .byte CHAR_P
  .byte CHAR_A
  .byte CHAR_S
  .byte CHAR_S
  .byte CHAR_W
  .byte CHAR_O
  .byte CHAR_R
  .byte CHAR_D
  
strStagePasswordBSRW:
  .byte $04        
  .byte $22, $13   
  .byte CHAR_B
  .byte CHAR_S
  .byte CHAR_R
  .byte CHAR_W
  
strStagePasswordMJTD:
  .byte $04        
  .byte $22, $13   
  .byte CHAR_M
  .byte CHAR_J
  .byte CHAR_T
  .byte CHAR_D
  
strContinue:
  .byte $09
  .byte $21, $8B
  .byte CHAR_C
  .byte CHAR_O
  .byte CHAR_N
  .byte CHAR_T
  .byte CHAR_I
  .byte CHAR_N
  .byte CHAR_U
  .byte CHAR_E
  .byte CHAR_COLON

strYes:
  .byte $03
  .byte $21, $CF
  .byte CHAR_Y
  .byte CHAR_E
  .byte CHAR_S

strNo:
  .byte $02
  .byte $22, $0F
  .byte CHAR_N
  .byte CHAR_O
  
strConglaturations:
  .byte $12     
  .byte $21, $27   
  .byte CHAR_C
  .byte CHAR_O
  .byte CHAR_N
  .byte CHAR_G
  .byte CHAR_L
  .byte CHAR_A
  .byte CHAR_T
  .byte CHAR_U
  .byte CHAR_R
  .byte CHAR_A
  .byte CHAR_T
  .byte CHAR_I
  .byte CHAR_O
  .byte CHAR_N
  .byte CHAR_S
  .byte CHAR_EXCLAMATION
  .byte CHAR_EXCLAMATION
  .byte CHAR_EXCLAMATION
  
strBeatTheGame:
  .byte $14     
  .byte $21, $66   
  .byte CHAR_Y
  .byte CHAR_O
  .byte CHAR_U
  .byte CHAR_APOSTROPHE
  .byte CHAR_V
  .byte CHAR_E
  .byte CHAR_SPACE
  .byte CHAR_B
  .byte CHAR_E
  .byte CHAR_A
  .byte CHAR_T
  .byte CHAR_SPACE
  .byte CHAR_T
  .byte CHAR_H
  .byte CHAR_E
  .byte CHAR_SPACE
  .byte CHAR_G
  .byte CHAR_A
  .byte CHAR_M
  .byte CHAR_E