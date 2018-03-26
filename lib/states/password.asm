;;;;;;;;;;;;;;
;; PASSWORD ;;
;;;;;;;;;;;;;;

; responsible for showing the password screen
 
;;;;;;;;;;;;;;;;;
;; SUBROUTINES ;;
;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                                          ;;
;;   PasswordFrame                                                ;;
;;                                                                ;;
;; Description:                                                   ;;
;;   Called once each frame when game is in the "password" state  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
PasswordFrame:

  LDA selection
  STA placeholder1            ; store the selection in placeholder1

  LDA #$00
  STA placeholder2            ; placeholder2 will determine wheter draw is needed
  
  .checkUp:                   
                              
    LDA controllerPressed     
    AND #CONTROLLER_UP        
    BEQ .checkUpDone          

    JSR ButtonSound      
    LDX selection             ; move up
    LDA movementUp, x         
    STA selection             
                              
  .checkUpDone:               
                              
  .checkDown:                 
                              
    LDA controllerPressed     
    AND #CONTROLLER_DOWN
    BEQ .checkDownDone        
    
    JSR ButtonSound  
    LDX selection             ; move down
    LDA movementDown, x       
    STA selection             
                              
  .checkDownDone:             
                              
  .checkLeft:                 
                              
    LDA controllerPressed     
    AND #CONTROLLER_LEFT      
    BEQ .checkLeftDone        
                     
    JSR ButtonSound  
    LDX selection             ; move left
    LDA movementLeft, x       
    STA selection             
                              
  .checkLeftDone:             
                              
  .checkRight:                
                              
    LDA controllerPressed     
    AND #CONTROLLER_RIGHT     
    BEQ .checkRightDone       
                     
    JSR ButtonSound  
    LDX selection             ; move right
    LDA movementRight, x      
    STA selection             
                              
  .checkRightDone:            
                              
  .checkIfMoved:          
                              
    LDA placeholder1          
    CMP selection             ; compare new selection to the old one
    BEQ .checkIfMovedDone
  
    JSR DrawSelectorPassword  ; selection changed, update the sprite
  
  .checkIfMovedDone:
  
  .checkA:
  
    LDA controllerPressed     
    AND #CONTROLLER_A
    BEQ .checkADone          
  
    JSR ButtonSound
    LDA numberOfChars
    CMP #$04
    BEQ .checkADone           ; check if there are available slots
  
    JSR DrawLetter
    INC placeholder2    
  
  .checkADone:

  .checkB:

    LDA controllerPressed     
    AND #CONTROLLER_B
    BEQ .checkBDone 
  
    JSR ButtonSound
    LDA numberOfChars
    BNE .deleteLetter
  
    JSR FadeOut
    JSR LoadTitleScreen
    JMP PasswordFrameDone     ; 'B' with no letters selected goes back to title screen
  
    .deleteLetter:
      JSR DeleteLetter
  
  .checkBDone:
  
  .checkStart:
  
    LDA controllerPressed
    AND #CONTROLLER_START
    BEQ .checkStartDone
  
    JSR ButtonSound
    JSR CheckPassword
  
  .checkStartDone:
  
  .checkIfDrawNeeded:
  
    LDA placeholder2
    BEQ .checkIfDrawNeededDone
  
    INC needDraw
    INC needPpuReg
  
  .checkIfDrawNeededDone:
  
PasswordFrameDone:
  RTS
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                          ;;
;;   LoadPasswordScreen           ;;
;;                                ;;
;; Description:                   ;;
;;   Loads the "password" screen  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadPasswordScreen:

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
    
  .clearSpritesDone:
  
  .sleep:                        
                                 
    LDX #$20                     
    JSR SleepForXFrames          
                                 
  .sleepDone:  
  
  .loadBackground:
  
    LDA #LOW(ntPassword)
    STA ntLow
    LDA #HIGH(ntPassword)
    STA ntHigh
    JSR LoadBackground        ; load background directly to PPU
    
  .loadBackgroundDone:
  
  .loadPalettes:
  
    LDA #LOW(palette_text)
    STA paletteLow
    LDA #HIGH(palette_text)
    STA paletteHigh
    JSR LoadBgPalette         ; load the background palette           
    JSR LoadSpritesPalette    ; load the sprites palette
    INC needDraw
    
  .loadPalettesDone:
  
  .initVars:
  
    LDA #GAMESTATE_PASSWORD
    STA gameState
  
    LDA #$00
    STA numberOfChars 
    STA selection
    
  .initVarsDone:
  
  .drawSelector:
  
    JSR DrawSelectorPassword
   
  .drawSelectorDone:
  
  .enablePPU:
  
    LDA #%10011000            ; sprites from PT 1, bg from PT 1, display NT 0
    STA soft2000
    LDA #%00011110            ; enable sprites and background
    STA soft2001
    INC needPpuReg
    
  .enablePPUDone:
    
  JSR WaitForFrame            ; wait for everything to get loaded
  RTS
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                   ;;
;;   DrawSelectorPassword  ;;
;;                         ;;
;; Description:            ;;
;;   Draws the selector    ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DrawSelectorPassword:
  
  LDX selection
  LDA selectorY, x
  STA SPRITE_SELECTOR + Y_OFF     ; set Y
                                  
  LDA selectorX, x                
  STA SPRITE_SELECTOR + X_OFF     ; set X
  
  LDA #SEL_TILE
  STA SPRITE_SELECTOR + TILE_OFF  ; set tile
  
  LDA #SEL_ATT
  STA SPRITE_SELECTOR + ATT_OFF   ; set att
  
  INC needDma
  
  RTS
  
;;;;;;;;;;;;;;;;;;;;;;;
;; Name:             ;;
;;   DrawLetter      ;;
;;                   ;;
;; Description:      ;;
;;   Draws a letter  ;;
;;;;;;;;;;;;;;;;;;;;;;; 
 
DrawLetter:
                     
  LDA #PASS_CHAR_HIGH
  STA placeholder3     ; store the high byte of destination (before adding the offset) in placeholer3
  
  LDA #PASS_CHAR_LOW
  CLC
  ADC numberOfChars    ; add the offset to the low byte of destination
  STA placeholder4     ; store it in placeholder4
  
  LDA placeholder3
  ADC #$00
  STA placeholder3     ; add the carry to high byte
  
  LDY #$00
  LDA #$01
  STA [bufferLow], y   ; buffer the length (1)
  
  INY
  LDA placeholder3
  STA [bufferLow], y   ; buffer the high byte of destination
  
  INY
  LDA placeholder4
  STA [bufferLow], y   ; buffer the low byte of destination

  LDA selection
  CLC
  ADC #CHAR_OFF        ; get the character to draw
    
  LDX numberOfChars
  STA characters, x    ; store it in the array
    
  INY
  INY
  STA [bufferLow], y   ; buffer the character
  
  LDA bufferLow        ; advance the pointer
  CLC
  ADC #$05
  STA bufferLow
  LDA bufferHigh
  ADC #$00
  STA bufferHigh
  
  INC numberOfChars    ; increase the character count
  INC placeholder2     ; draw needed
  
  RTS

;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:               ;;
;;   DeleteLetter      ;;
;;                     ;;
;; Description:        ;;
;;   Deletes a letter  ;;
;;;;;;;;;;;;;;;;;;;;;;;;; 
  
DeleteLetter:

  DEC numberOfChars    ; decrease the character count

  LDA #PASS_CHAR_HIGH
  STA placeholder3     ; store the high byte of destination (before adding the offset) in placeholer3
  
  LDA #PASS_CHAR_LOW
  CLC
  ADC numberOfChars    ; add the offset to the low byte of destination
  STA placeholder4     ; store it in placeholder4
  
  LDA placeholder3
  ADC #$00
  STA placeholder3     ; add the carry to high byte
  
  LDY #$00
  LDA #$01
  STA [bufferLow], y   ; buffer the length (1)
  
  INY
  LDA placeholder3
  STA [bufferLow], y   ; buffer the high byte of destination
  
  INY
  LDA placeholder4
  STA [bufferLow], y   ; buffer the low byte of destination

  LDA #CLEAR_TILE
  INY
  INY
  STA [bufferLow], y   ; buffer the character
  
  LDA bufferLow        ; advance the pointer
  CLC
  ADC #$05
  STA bufferLow
  LDA bufferHigh
  ADC #$00
  STA bufferHigh
  
  INC placeholder2     ; draw needed
  
  RTS
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                  ;;
;;   CheckPassword        ;;
;;                        ;;
;; Description:           ;;
;;   Checks the password  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
  
CheckPassword:

  .checkLength:
  
    LDA numberOfChars
    CMP #$04
    BNE .invalidPassword         ; 4 characters must be entered
                                 
  .checkLengthDone:              
                                 
  .checkContents:                
                                 
    LDX #$00                     
                                 
    .checkLoop:                  
                                 
      STX placeholder5           ; store the index of currently checked level in placeholder5
                                 
      TXA                        
      ASL A                      
      ASL A                      
      ASL A                      
      CLC                        
      ADC #$04                   
      TAX                        ; X points to the password pointer in levelStages
                              
      LDA levelStages, x      
      STA stringHigh          
      INX                     
      LDA levelStages, x      
      STA stringLow              ; loaded the pointer
                                 
      LDY #$03                   ; Y points at the first character of the password
      LDX #$00                   ; X points to the first character in characters
                                 
      .checkCharacterLoop:       
        LDA [stringLow], y       ; load the password character to A
        CMP characters, x        ; compare with the entered character
        BNE .checkNext           ; not equal, check next password
        INY
        INX
        CPX #$04
        BNE .checkCharacterLoop  ; check next character
        JMP .validPassword
                              
      .checkNext:             
        LDX placeholder5      
        INX                   
        CPX #LEVELS_COUNT     
        BEQ .invalidPassword     ; checked all levels, nothing matched
        JMP .checkLoop
  
  .checkContentsDone:
    
  .validPassword:
  
    LDA placeholder5
    STA currentLevel             ; load the level number and store it in the var
    JSR FadeOut
    JSR LoadStageScreen          ; go to the stage screen
    RTS
    
  .invalidPassword:
  
    LDA numberOfChars
    BEQ .invalidPasswordDone
  
    .deleteLoop:
      JSR DeleteLetter
      LDA numberOfChars
      BNE .deleteLoop
    
  .invalidPasswordDone:
  
    RTS