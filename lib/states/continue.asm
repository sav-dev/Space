;;;;;;;;;;;;;;
;; CONTINUE ;;
;;;;;;;;;;;;;;

; responsible for showing the continue screen
 
;;;;;;;;;;;;;;;;;
;; SUBROUTINES ;;
;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                                          ;;
;;   ContinueFrame                                                ;;
;;                                                                ;;
;; Description:                                                   ;;
;;   Called once each frame when game is in the "continue" state  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ContinueFrame:

  .processSelection:
    LDA controllerPressed
    AND #CONTROLLER_SEL
    BNE .changeSelection               ; check if select was pressed
                                       
    LDA controllerPressed              
    AND #CONTROLLER_START              
    BEQ ContinueFrameDone              ; check if start was pressed
    
    JSR ButtonSound  
    JSR FadeOut
    
    LDA selection
    BEQ .yes
    
    .no:
      JSR LoadTitleScreen
      JMP ContinueFrameDone
      
    .yes:
      JSR LoadStageScreen
      JMP ContinueFrameDone
  
  .changeSelection:
  
    JSR ButtonSound  
    LDA selection
    EOR #$01
    STA selection                      ; invert selection
                                       
    .drawSelection:                    
      JSR DrawSelectionContinue
      INC needDraw                     ; data needs to be drawn
      INC needPpuReg                   ; this will fix the scroll

ContinueFrameDone:
  RTS
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                          ;;
;;   LoadContinueScreen           ;;
;;                                ;;
;; Description:                   ;;
;;   Loads the "continue" screen  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadContinueScreen:

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

  .updateAttributes:
  
    LDA $2002
    LDA #C_SEL_ATT_0_HIGH 
    STA $2006
    LDA #C_SEL_ATT_0_LOW
    STA $2006
    LDA #C_SEL_ATT_0
    STA $2007
    
    LDA $2002
    LDA #C_SEL_ATT_1_HIGH 
    STA $2006
    LDA #C_SEL_ATT_1_LOW
    STA $2006
    LDA #C_SEL_ATT_1
    STA $2007
  
  .updateAttributesDone:
  
  .drawSelection:
  
    JSR DrawSelectionContinue
  
  .drawSelectionDone:
  
  .printStrings:
  
    LDA #HIGH(strContinue)
    STA stringHigh          
    LDA #LOW(strContinue) 
    STA stringLow           
    JSR PrintString              ; continue string

    LDA #HIGH(strYes)
    STA stringHigh          
    LDA #LOW(strYes) 
    STA stringLow           
    JSR PrintString              ; yes string
    
    LDA #HIGH(strNo)
    STA stringHigh          
    LDA #LOW(strNo) 
    STA stringLow           
    JSR PrintString              ; no string
    
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
  
    LDA #GAMESTATE_CONTINUE
    STA gameState

    LDA #$00
    STA selection
    
  .initVarsDone:                 
          
  .stopMusic:

    ;JSR sound_stop  
    LDA #SONG_NONE
    STA currentSong
      
  .stopMusicDone:
          
  JSR WaitForFrame               ; wait for everything to get loaded
  RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                         ;;
;;   DrawSelectionContinue       ;;
;;                               ;;
;; Description:                  ;;
;;   Draws the selection picker  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DrawSelectionContinue:

  DrawNewSelectionContinue:        ; draw new selection
                                   
    .setLength:                    
      LDY #$00                     ; Y = 0
      LDA #$01                     ; we'll draw one byte
      STA [bufferLow], y           ; store it in the buffer
      TAX                          ; move the length to X
                                   
    .setTarget:                    
      LDA selection                
      BNE .sel1                    
                                   
      .sel0:                       
        INY                        ; Y = 1
        LDA #C_SEL_0_HIGH          ; load the high byte of the destination
        STA [bufferLow], y         ; store it in the buffer
        INY                        ; Y = 2
        LDA #C_SEL_0_LOW           ; load the low byte of the destination
        STA [bufferLow], y         ; store it in the buffer
        JMP .setTile               
                                   
      .sel1:                       
        INY                        ; Y = 1
        LDA #C_SEL_1_HIGH          ; load the high byte of the destination
        STA [bufferLow], y         ; store it in the buffer
        INY                        ; Y = 2
        LDA #C_SEL_1_LOW           ; load the low byte of the destination
        STA [bufferLow], y         ; store it in the buffer
                                   
    .setTile:                      
      INY                          
      INY                          ; Y = 4
      LDA #SEL_TILE                
      STA [bufferLow], y           ; set the tile to update
    
    .advancePointer:
      LDA #$05
      CLC                      
      ADC bufferLow            
      STA bufferLow 
      LDA bufferHigh
      ADC #$00      
      STA bufferHigh

  ClearPreviousSelectionContinue:  ; clear previous selection

    .setLength:
      LDY #$00                     ; Y = 0
      LDA #$01                     ; we'll draw one byte
      STA [bufferLow], y           ; store it in the buffer
      TAX                          ; move the length to X
                                   
    .setTarget:                    
      LDA selection                
      BEQ .sel1                    
                                   
      .sel0:                       
        INY                        ; Y = 1
        LDA #C_SEL_0_HIGH          ; load the high byte of the destination
        STA [bufferLow], y         ; store it in the buffer
        INY                        ; Y = 2
        LDA #C_SEL_0_LOW           ; load the low byte of the destination
        STA [bufferLow], y         ; store it in the buffer
        JMP .setTile               
                                   
      .sel1:                       
        INY                        ; Y = 1
        LDA #C_SEL_1_HIGH          ; load the high byte of the destination
        STA [bufferLow], y         ; store it in the buffer
        INY                        ; Y = 2
        LDA #C_SEL_1_LOW           ; load the low byte of the destination
        STA [bufferLow], y         ; store it in the buffer
                                   
    .setTile:                      
      INY                          
      INY                          ; Y = 4
      LDA #CLEAR_TILE              
      STA [bufferLow], y           ; set the tile to update
    
    .advancePointer:
      LDA #$05
      CLC                        
      ADC bufferLow              
      STA bufferLow 
      LDA bufferHigh
      ADC #$00      
      STA bufferHigh
    
  RTS