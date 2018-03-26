;;;;;;;;;
;; END ;;
;;;;;;;;;

; responsible for showing the end game screen
 
;;;;;;;;;;;;;;;;;
;; SUBROUTINES ;;
;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                                     ;;
;;   EndFrame                                                ;;
;;                                                           ;;
;; Description:                                              ;;
;;   Called once each frame when game is in the "end" state  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EndFrame:

  LDA controllerPressed  
  AND #CONTROLLER_START
  BNE .startPressed
  
  INC blinkTimer
  LDA blinkTimer
  CMP #PS_TIMER_FREQ
  BEQ .blink                         ; check if it's timer for a blink
  JMP EndFrameDone
    
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
      JMP EndFrameDone
      
  .startPressed:
    JSR ButtonSound  
    JSR FadeOut
    JSR LoadTitleScreen
    JMP EndFrameDone

EndFrameDone:
  RTS
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                     ;;
;;   LoadEndScreen           ;;
;;                           ;;
;; Description:              ;;
;;   Loads the "end" screen  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadEndScreen:

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

    LDA #HIGH(strConglaturations)
    STA stringHigh          
    LDA #LOW(strConglaturations) 
    STA stringLow           
    JSR PrintString              ; "conglaturations" string  
    
    LDA #HIGH(strBeatTheGame)
    STA stringHigh          
    LDA #LOW(strBeatTheGame) 
    STA stringLow           
    JSR PrintString              ; "you've beat the game" string  
    
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
  
    LDA #GAMESTATE_END
    STA gameState
    
    LDA #$00
    STA blinkTimer
    
    LDA #$01
    STA showingString            ; we're showing the "press start" string initially
                                                            
  .initVarsDone:                 
                                 
  JSR WaitForFrame               ; wait for everything to get loaded
  RTS