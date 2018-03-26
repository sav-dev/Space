;;;;;;;;;;;
;; TITLE ;;
;;;;;;;;;;;

; responsible for processing the title screen

;;;;;;;;;;;;;;;;;
;; SUBROUTINES ;;
;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                                       ;;
;;   TitleFrame                                                ;;
;;                                                             ;;
;; Description:                                                ;;
;;   Called once each frame when game is in the "title" state  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TitleFrame:

  LDA startPressed
  BNE .processSelection

  .waitForStart:
    LDA controllerPressed
    AND #CONTROLLER_START
    BNE .startPressed
  
    INC blinkTimer
    LDA blinkTimer
    CMP #PS_TIMER_FREQ
    BEQ .blink                         ; check if it's timer for a blink
    JMP TitleFrameDone
    
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
        JMP TitleFrameDone
      
      .startPressed:
        JSR ButtonSound
        INC startPressed
        
        LDA #HIGH(strNewGame)
        STA stringHigh
        LDA #LOW(strNewGame)
        STA stringLow
        JSR PrintString                ; draw the "New Game" string
        
        LDA #HIGH(strPressStartBlank)
        STA stringHigh
        LDA #LOW(strPressStartBlank)
        STA stringLow
        JSR PrintString                ; hide the "Press Start" string in case it's still visible
        
        LDA #HIGH(strPassword)
        STA stringHigh
        LDA #LOW(strPassword)
        STA stringLow
        JSR PrintString                ; draw the "Password" string
        
        JSR UpdateAttributes           ; attributes must be updated
        
        JMP .drawSelection             ; draw the selection picker
  
  .processSelection:
    LDA controllerPressed
    AND #CONTROLLER_SEL
    BNE .changeSelection               ; check if select was pressed
                                       
    LDA controllerPressed              
    AND #CONTROLLER_START              
    BEQ TitleFrameDone                 ; check if start was pressed
    
    JSR ButtonSound
    JSR FadeOut
    
    LDA selection
    BEQ .newGame
    
    .password:
      JSR LoadPasswordScreen
      JMP TitleFrameDone
      
    .newGame:
      JSR LoadStageScreen
      JMP TitleFrameDone
  
  .changeSelection:
  
    JSR ButtonSound
    LDA selection
    EOR #$01
    STA selection                      ; invert selection
                                       
    .drawSelection:                    
      JSR DrawSelectionTitle
      INC needDraw                     ; data needs to be drawn
      INC needPpuReg                   ; this will fix the scroll
  
TitleFrameDone:
  RTS
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                     ;;
;;   LoadTitleScreen         ;;
;;                           ;;
;; Description:              ;;
;;   Loads the title screen  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadTitleScreen:

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
  
    LDA #LOW(ntTitle)
    STA ntLow
    LDA #HIGH(ntTitle)
    STA ntHigh
    JSR LoadBackground        ; load background directly to PPU
    
  .loadBackgroundDone:
  
  .loadPalettes:
  
    LDA #LOW(palette_text)
    STA paletteLow
    LDA #HIGH(palette_text)
    STA paletteHigh
    JSR LoadBgPalette         ; load the background palette           
    
  .loadPalettesDone:
  
  .printString:
  
    LDA #HIGH(strPressStart)
    STA stringHigh          
    LDA #LOW(strPressStart) 
    STA stringLow           
    JSR PrintString           ; print the string
    INC needDraw              ; inc the needDraw flag as we've buffered the palette and the string
  
  .printStringDone:
  
  .enablePPU:
  
    LDA #%10010000            ; sprites from PT 0, bg from PT 1, display NT 0
    STA soft2000
    LDA #%00011110            ; enable sprites and background
    STA soft2001
    INC needPpuReg
    
  .enablePPUDone:
  
  .initVars:
  
    LDA #GAMESTATE_TITLE
    STA gameState
  
    LDA #$00
    STA startPressed
    STA blinkTimer  
    STA selection    
    STA currentLevel
   
    LDA #$01
    STA showingString         ; we're showing the string initially
   
  .initVarsDone:

  .playSong:
  
    ;LDA currentSong
    ;CMP #SONG_TITLE
    ;BEQ .playSongDone
    ;
    ;LDA #SONG_TITLE
    ;STA currentSong
    ;LDA #song_index_antagonist
    ;STA sound_param_byte_0
    ;JSR play_song
  
  .playSongDone:
  
  JSR WaitForFrame            ; wait for everything to get loaded
  RTS
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                         ;;
;;   DrawSelectionTitle          ;;
;;                               ;;
;; Description:                  ;;
;;   Draws the selection picker  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DrawSelectionTitle:

  DrawNewSelectionTitle:        ; draw new selection
                                
    .setLength:                 
      LDY #$00                  ; Y = 0
      LDA #$01                  ; we'll draw one byte
      STA [bufferLow], y        ; store it in the buffer
      TAX                       ; move the length to X
                                
    .setTarget:                 
      LDA selection             
      BNE .sel1                 
                                
      .sel0:                    
        INY                     ; Y = 1
        LDA #T_SEL_0_HIGH       ; load the high byte of the destination
        STA [bufferLow], y      ; store it in the buffer
        INY                     ; Y = 2
        LDA #T_SEL_0_LOW        ; load the low byte of the destination
        STA [bufferLow], y      ; store it in the buffer
        JMP .setTile            
                                
      .sel1:                    
        INY                     ; Y = 1
        LDA #T_SEL_1_HIGH       ; load the high byte of the destination
        STA [bufferLow], y      ; store it in the buffer
        INY                     ; Y = 2
        LDA #T_SEL_1_LOW        ; load the low byte of the destination
        STA [bufferLow], y      ; store it in the buffer
                                
    .setTile:                   
      INY                       
      INY                       ; Y = 4
      LDA #SEL_TILE             
      STA [bufferLow], y        ; set the tile to update
    
    .advancePointer:
      LDA #$05
      CLC                      
      ADC bufferLow            
      STA bufferLow 
      LDA bufferHigh
      ADC #$00      
      STA bufferHigh

  ClearPreviousSelectionTitle:  ; clear previous selection

    .setLength:
      LDY #$00                  ; Y = 0
      LDA #$01                  ; we'll draw one byte
      STA [bufferLow], y        ; store it in the buffer
      TAX                       ; move the length to X
                                
    .setTarget:                 
      LDA selection             
      BEQ .sel1                 
                                
      .sel0:                    
        INY                     ; Y = 1
        LDA #T_SEL_0_HIGH       ; load the high byte of the destination
        STA [bufferLow], y      ; store it in the buffer
        INY                     ; Y = 2
        LDA #T_SEL_0_LOW        ; load the low byte of the destination
        STA [bufferLow], y      ; store it in the buffer
        JMP .setTile            
                                
      .sel1:                    
        INY                     ; Y = 1
        LDA #T_SEL_1_HIGH       ; load the high byte of the destination
        STA [bufferLow], y      ; store it in the buffer
        INY                     ; Y = 2
        LDA #T_SEL_1_LOW        ; load the low byte of the destination
        STA [bufferLow], y      ; store it in the buffer
                                
    .setTile:                   
      INY                       
      INY                       ; Y = 4
      LDA #CLEAR_TILE           
      STA [bufferLow], y        ; set the tile to update
    
    .advancePointer:
      LDA #$05
      CLC                        
      ADC bufferLow              
      STA bufferLow 
      LDA bufferHigh
      ADC #$00      
      STA bufferHigh
    
  RTS
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                         ;;
;;   UpdateAttributes                            ;;
;;                                               ;;
;; Description:                                  ;;
;;   Update attributes for the selection picker  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateAttributes:

  .att0:
    LDY #$00                   ; Y = 0
    LDA #$01                   ; we'll draw one byte
    STA [bufferLow], y         ; store it in the buffer
    TAX                        ; move the length to X
  
    INY                        ; Y = 1
    LDA #T_SEL_ATT_0_HIGH      ; load the high byte of the destination
    STA [bufferLow], y         ; store it in the buffer
    INY                        ; Y = 2
    LDA #T_SEL_ATT_0_LOW       ; load the low byte of the destination
    STA [bufferLow], y         ; store it in the buffer
    
    INY
    INY                        ; Y = 4
    LDA #T_SEL_ATT_0
    STA [bufferLow], y         ; set the att. to update

    LDA #$05
    CLC                        
    ADC bufferLow              
    STA bufferLow 
    LDA bufferHigh
    ADC #$00      
    STA bufferHigh

  .att1:
    LDY #$00                   ; Y = 0
    LDA #$01                   ; we'll draw one byte
    STA [bufferLow], y         ; store it in the buffer
    TAX                        ; move the length to X
  
    INY                        ; Y = 1
    LDA #T_SEL_ATT_1_HIGH      ; load the high byte of the destination
    STA [bufferLow], y         ; store it in the buffer
    INY                        ; Y = 2
    LDA #T_SEL_ATT_1_LOW       ; load the low byte of the destination
    STA [bufferLow], y         ; store it in the buffer
    
    INY
    INY                        ; Y = 4
    LDA #T_SEL_ATT_1
    STA [bufferLow], y         ; set the att. to update

    LDA #$05
    CLC                        
    ADC bufferLow              
    STA bufferLow 
    LDA bufferHigh
    ADC #$00      
    STA bufferHigh
    
  RTS