;;;;;;;;;;;
;; STAGE ;;
;;;;;;;;;;;

; responsible for processing the stage # screen

;;;;;;;;;;;;;;;;;
;; SUBROUTINES ;;
;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                                       ;;
;;   StageFrame                                                ;;
;;                                                             ;;
;; Description:                                                ;;
;;   Called once each frame when game is in the "stage" state  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StageFrame:
    
  LDA controllerPressed  
  AND #CONTROLLER_START
  BNE .startPressed
  
  INC blinkTimer
  LDA blinkTimer
  CMP #PS_TIMER_FREQ
  BEQ .blink                         ; check if it's timer for a blink
  JMP StageFrameDone
    
  .blink:    
    LDA #$00                         ; time for a blink
    STA blinkTimer                   ; reset timer
    LDA showingString                
    EOR #$01                         ; invert the showing string value
    STA showingString                
    BEQ .hideString                  
                                       
    .showString:                     ; must show the string
      LDA #HIGH(strPressStart)          
      STA stringHigh                 
      LDA #LOW(strPressStart)           
      STA stringLow                  
      JMP .updateString              
                                     
    .hideString:                     ; must hide the string
      LDA #HIGH(strPressStartBlank)
      STA stringHigh
      LDA #LOW(strPressStartBlank)
      STA stringLow
      
    .updateString:
      JSR PrintString                ; update the string
      INC needDraw                   ; data needs to be drawn
      INC needPpuReg                 ; this will fix the scroll
      JMP StageFrameDone
      
  .startPressed:
      JSR ButtonSound
      JSR FadeOut
      JSR LoadGame
      JMP TitleFrameDone

StageFrameDone:
  RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                                      ;;
;;   LoadStageScreen                                          ;;
;;                                                            ;;
;; Description:                                               ;;
;;   Loads the stage screen based on the "current level" var  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadStageScreen:

  .disablePPU:

    LDA #$00
    STA scroll
    LDA #%00000110                ; disable sprites and background
    STA soft2001                  
    INC needPpuReg                
    JSR WaitForFrame              
                                  
  .disablePPUDone:                
        
  .clearSprites:
  
    JSR ClearSprites
    INC needDma
  
  .clearSpritesDone:              
                                 
  .sleep:                        
                                 
    LDX #$20                     
    JSR SleepForXFrames          
                                 
  .sleepDone:
                                 
  .loadBackground:               
                                 
    LDA #CLEAR_BG_ATT            
    STA clearAtts                
    JSR ClearBackground          ; load a clear background
    
  .loadBackgroundDone:
  
  .printStrings:
  
    LDA #HIGH(strPressStart)
    STA stringHigh          
    LDA #LOW(strPressStart) 
    STA stringLow           
    JSR PrintString              ; press start string
  
    LDA #HIGH(strLevel)
    STA stringHigh
    LDA #LOW(strLevel)
    STA stringLow
    JSR PrintString              ; level string
    
    LDA #HIGH(strStage)
    STA stringHigh
    LDA #LOW(strStage)
    STA stringLow
    JSR PrintString              ; stage string
    
    LDA #HIGH(strStagePassword)
    STA stringHigh
    LDA #LOW(strStagePassword)
    STA stringLow
    JSR PrintString              ; password string
    
    LDA currentLevel
    ASL A
    ASL A
    ASL A                        ; A *= 8 (8 bytes per level in the lookup table)
    TAX
    
    LDA levelStages, x
    STA stringHigh
    INX
    LDA levelStages, x
    STA stringLow
    STX placeholder1
    JSR PrintString              ; level number
    LDX placeholder1
    INX

    LDA levelStages, x
    STA stringHigh
    INX
    LDA levelStages, x
    STA stringLow
    STX placeholder1
    JSR PrintString              ; stage number
    LDX placeholder1
    INX
    
    LDA levelStages, x
    STA stringHigh
    INX
    LDA levelStages, x
    STA stringLow
    JSR PrintString              ; password
    
    INC needDraw
  
  .printStringsDone:
  
  .loadPalettes:
  
    LDA #LOW(palette_text)
    STA paletteLow
    LDA #HIGH(palette_text)
    STA paletteHigh
    JSR LoadBgPalette            ; load the background palette           
                                 
  .loadPalettesDone:             
                                 
  .enablePPU:                    
                                 
    LDA #%10010000               ; sprites from PT 0, bg from PT 1, display NT 0
    STA soft2000                 
    LDA #%00011110               ; enable sprites and background
    STA soft2001
    INC needPpuReg
    
  .enablePPUDone:
  
  .initVars:
  
    LDA #GAMESTATE_STAGE
    STA gameState
    
    LDA #$00
    STA blinkTimer
    
    LDA #$01
    STA showingString            ; we're showing the "press start" string initially
                                                                  
  .initVarsDone:                 
                                 
  .stopMusic:

    ;JSR sound_stop  
    LDA #SONG_NONE
    STA currentSong
      
  .stopMusicDone:
  
  JSR WaitForFrame               ; wait for everything to get loaded
  RTS