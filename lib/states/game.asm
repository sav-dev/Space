;;;;;;;;;;
;; GAME ;;
;;;;;;;;;;

; responsible for running the game
 
;;;;;;;;;;;;;;;;;
;; SUBROUTINES ;;
;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                                         ;;
;;   GameFrame                                                   ;;
;;                                                               ;;
;; Description:                                                  ;;
;;   Called once each frame when game is in the "playing" state  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GameFrame:

  .checkPause:
    JSR CheckPause            ; check if game should be paused/unpaused
    LDA paused
    BNE GameFrameDone         ; we don't do anything if game is paused

  .checkIfEndOfLevel:
    LDA endOfLevel
    BEQ .checkIfShipExploded 
    LDA shipHP
    BEQ .checkIfShipExploded 
    LDA shipDestroyed
    BNE .checkIfShipExploded 
    JSR EndOfLevel            ; end of level reached and the ship still exists
    JMP GameFrameDone
  
  .checkIfShipExploded:
    LDA shipDestroyed
    BEQ .processGame     
    INC continueCounter       ; ship exploded. INC the continue counter
    LDA continueCounter
    CMP #CONTINUE_COUNTER     ; check if it's time to show the continue screen
    BNE .processGame    
    JSR FadeOut               ; switch to the continue screen
    LDX #$28
    JSR SleepForXFrames
    JSR LoadContinueScreen
    JMP GameFrameDone    
  
  .processGame:  
    JSR CheckCollisions       ; check for collisions - do this before positions of any objects are updated
    
    JSR UpdateBullets         ; update all bullets
    JSR UpdateShip            ; update ship
    JSR UpdateEnemies         ; update existing enemies
    JSR SpawnEnemies          ; spawn new ones
    
    JSR UpdateHPBar           ; update status bars if needed
    JSR UpdateXPBar
    
    JSR IncrementScroll
    INC needDma               ; we'll assume we always need DMA in the game
  
GameFrameDone:
  RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                          ;;
;;   CheckPause                                   ;;
;;                                                ;;
;; Description:                                   ;;
;;   Check if the game should be paused/unpaused  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckPause:
  LDA controllerPressed
  AND #CONTROLLER_START
  BEQ CheckPauseDone         ; start not pressed
  LDA paused
  EOR #$00000001             ; invert first bit
  STA paused
CheckPauseDone:
  RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                                ;;
;;   LoadGame                                           ;;
;;                                                      ;;
;; Description:                                         ;;
;;   Loads level - load background, init all vars, etc  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
LoadGame:
  
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
                                  
    LDA currentLevel              ; load current level number
    ASL A                         ; x2 because there's 2 bytes per level in the lookup table
    TAX                           ; move it to X  
    LDA levelBackgrounds, x       ; load the level pointer
    STA bgLevelHigh               
    INX                           
    LDA levelBackgrounds, x               
    STA bgLevelLow                
    JSR LoadLevelBackground       ; load the background
    INC needDraw                  ; because we've buffered the palettes
                                  
  .loadBackgroundDone:            
                                  
  .loadEnemiesPointer:            
                                  
    LDA currentLevel              ; load current level number
    ASL A                         ; x2 because there's 2 bytes per level in each lookup table
    TAX                           ; move it to X
    LDA levelEnemies, x           ; load the enemies pointer
    STA enLevelHigh     
    INX                 
    LDA levelEnemies, x 
    STA enLevelLow      
    JSR LoadEnemiesScreenPointer
                                  
  .loadEnemiesPointerDone:        
                                  
  .loadShip:                      
                                  
    LDA #SHIP_X_DEFAULT           
    STA shipX                     
    LDA #SHIP_Y_DEFAULT           
    STA shipY                     
    JSR UpdateShip                
    LDA #BULLET_FLAME             
    STA currentWeapon             
    JSR LoadBulletPointer         
                                  
  .loadShipDone:                  
                                  
  .loadStatusBars:                
                                  
    LDA #SHIP_MAX_HP              
    STA shipHP                    
    LDA #$00                      
    STA shipXP                    
    INC updateHPBar               
    INC updateXPBar               
    JSR UpdateHPBar               
    JSR UpdateXPBar               
                                  
  .loadStatusBarsDone:            
                                  
  .enablePPU:                     
                                  
    LDA #%10010000                ; sprites from PT 0, bg from PT 1, display NT 0
    STA soft2000                  
    LDA #%00011110                ; enable sprites and background
    STA soft2001                  
    INC needPpuReg                
                                  
  .enablePPUDone:                 
                                  
  .initVars:                      
                                  
    LDA #GAMESTATE_PLAYING        
    STA gameState                 
                                  
    LDA #$00                      
    STA paused                    
    STA shipDestroyed
    STA shipDrawn              
    STA shipDirectionTimer
    STA exhaustTimer
    STA continueCounter
    
    LDA #SHIP_DIRECTION_U
    STA shipDirection  
    
    LDA #EXHAUST_TILE_MIN
    STA exhaustCurrentTile
    
    LDA #EXHAUST_TILE_MIN + $01
    STA exhaustNextTile
  
  .initVarsDone:                  
             
  .playSong:
  
    ;LDA currentSong
    ;CMP #SONG_GAME
    ;BEQ .playSongDone
    ;
    ;LDA #SONG_GAME
    ;STA currentSong
    ;LDA #song_index_soler42
    ;STA sound_param_byte_0
    ;JSR play_song
  
  .playSongDone:
             
  JSR WaitForFrame                ; wait for everything to get loaded
  RTS
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                            ;;
;;   UpdateShip                                     ;;
;;                                                  ;;
;; Description:                                     ;;
;;   Update the ship based on the controller input  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateShip:
  
  .checkIfShipExloding:
    LDA shipHP
    BEQ .checkIfShipExists                ; check if the ship is alive
    JMP .processController                ; ship is not exploding, process input  
                                          
  .checkIfShipExists:                                                                 
    LDA shipDestroyed                     
    BEQ .checkTimer                       ; check if ship is already destroyed
    RTS                                   ; ship is destroyed, return
                   
  .checkTimer:
    INC shipExplTimer                     
    LDA shipExplTimer                     
    CMP #SH_EXPLOSION_TIMER
    BEQ .updateAnimation                  ; check if explosion animation should be updated
    RTS                                   ; too soon for an update, return
                                          
  .updateAnimation:
    LDA #$00                              
    STA shipExplTimer                     
    LDA SHIP_TILE_OFF                     
    CMP #SH_EXPLOSION_END                 
    BEQ .deleteShip                       ; check if ship should be deleted
                                          
    INC SHIP_TILE_OFF                     ; update the animation
    INC SHIP_TILE_OFF                     
    INC SHIP_TILE_OFF                     
    INC SHIP_TILE_OFF + SHIP_OFF_1        
    INC SHIP_TILE_OFF + SHIP_OFF_1        
    INC SHIP_TILE_OFF + SHIP_OFF_1        
    INC SHIP_TILE_OFF + SHIP_OFF_2        
    INC SHIP_TILE_OFF + SHIP_OFF_2        
    INC SHIP_TILE_OFF + SHIP_OFF_2        
    INC SHIP_TILE_OFF + SHIP_OFF_3        
    INC SHIP_TILE_OFF + SHIP_OFF_3        
    INC SHIP_TILE_OFF + SHIP_OFF_3        
    INC SHIP_TILE_OFF + SHIP_OFF_4        
    INC SHIP_TILE_OFF + SHIP_OFF_4        
    INC SHIP_TILE_OFF + SHIP_OFF_4        
    INC SHIP_TILE_OFF + SHIP_OFF_5        
    INC SHIP_TILE_OFF + SHIP_OFF_5        
    INC SHIP_TILE_OFF + SHIP_OFF_5        
    INC SHIP_TILE_OFF + SHIP_OFF_6        
    INC SHIP_TILE_OFF + SHIP_OFF_6        
    INC SHIP_TILE_OFF + SHIP_OFF_6        
    INC SHIP_TILE_OFF + SHIP_OFF_7        
    INC SHIP_TILE_OFF + SHIP_OFF_7        
    INC SHIP_TILE_OFF + SHIP_OFF_7        
    INC SHIP_TILE_OFF + SHIP_OFF_8        
    INC SHIP_TILE_OFF + SHIP_OFF_8        
    INC SHIP_TILE_OFF + SHIP_OFF_8        
    RTS            
                                          
  .deleteShip:                          
    LDA #CLEAR_SPRITE                   
    STA SHIP_TILE_OFF                   
    STA SHIP_TILE_OFF + SHIP_OFF_1      
    STA SHIP_TILE_OFF + SHIP_OFF_2      
    STA SHIP_TILE_OFF + SHIP_OFF_3      
    STA SHIP_TILE_OFF + SHIP_OFF_4      
    STA SHIP_TILE_OFF + SHIP_OFF_5      
    STA SHIP_TILE_OFF + SHIP_OFF_6      
    STA SHIP_TILE_OFF + SHIP_OFF_7      
    STA SHIP_TILE_OFF + SHIP_OFF_8      
    INC shipDestroyed                   
    RTS          
    
  .processController:                     

    LDA #SHIP_MOVEMENT_U
    STA shipMovement
    
    .checkUp:                             
                                          
      LDA controllerDown                  
      AND #CONTROLLER_UP                  
      BEQ .upDone                         
                                          
      LDA shipY                           
      CMP #SHIP_Y_MIN                     
      BEQ .upDone                         ; ship cannot move anymore
                                          
      INC updateShipPosition              
      INC updateExhaust
                                          
      SEC                                 
      SBC #SHIP_SPEED                     
      STA shipY                           ; move the ship up
                                          
      CMP #SHIP_Y_MIN                     
      BCS .upDone                         ; check if ship is out of bounds
                                          
      LDA #SHIP_Y_MIN                     
      STA shipY                           ; ship is out of bounds, move it to the right place
                                          
    .upDone:                              
                                          
    .checkDown:                           
                                          
      LDA controllerDown                  
      AND #CONTROLLER_DOWN                
      BEQ .downDone                       
                                          
      LDA shipY                           
      CMP #SHIP_Y_MAX                     
      BEQ .downDone                       ; ship cannot move anymore
                                          
      INC updateShipPosition              
      INC updateExhaust
                                          
      CLC                                 
      ADC #SHIP_SPEED                     
      STA shipY                           ; move the ship up
                                          
      CMP #SHIP_Y_MAX                     
      BCC .downDone                       ; check if ship is out of bounds
                                          
      LDA #SHIP_Y_MAX                     
      STA shipY                           ; ship is out of bounds, move it to the right place
                                          
    .downDone:                            
                                          
    .checkLeft:                           
                                          
      LDA controllerDown                  
      AND #CONTROLLER_LEFT                
      BEQ .leftDone                       
                                          
      LDA #SHIP_MOVEMENT_L
      STA shipMovement
      
      LDA shipX                           
      CMP #SHIP_X_MIN                     
      BEQ .leftDone                       ; ship cannot move anymore
                                          
      INC updateShipPosition              
      INC updateExhaust
      
      SEC                                 
      SBC #SHIP_SPEED                     
      STA shipX                           ; move the ship up
                                          
      CMP #SHIP_X_MIN                     
      BCS .leftDone                       ; check if ship is out of bounds
                                          
      LDA #SHIP_X_MIN                     
      STA shipX                           ; ship is out of bounds, move it to the right place
                    
    .leftDone:                            
                                          
    .checkRight:                          
                                          
      LDA controllerDown                  
      AND #CONTROLLER_RIGHT               
      BEQ .rightDone                      
                      
      LDA #SHIP_MOVEMENT_R
      STA shipMovement
                      
      LDA shipX                           
      CMP #SHIP_X_MAX                     
      BEQ .rightDone                      ; ship cannot move anymore
                                          
      INC updateShipPosition              
      INC updateExhaust
      
      CLC                                 
      ADC #SHIP_SPEED                     
      STA shipX                           ; move the ship up
                                          
      CMP #SHIP_X_MAX                     
      BCC .rightDone                      ; check if ship is out of bounds
                                          
      LDA #SHIP_X_MAX                     
      STA shipX                           ; ship is out of bounds, move it to the right place
                                          
    .rightDone:                           
                                          
    .updateShip:

      JSR UpdateShipIfNeeded
    
    .updateShipDone:
                                          
    .checkA:                              
                                          
      LDA controllerPressed               
      AND #CONTROLLER_A                   
      BEQ .aDone                          
      JSR FireBullet                      
                                          
    .aDone:                               
                                          
    .checkB:                              
                                          
      LDA controllerPressed               
      AND #CONTROLLER_B                   
      BEQ .bDone                          
                                          
      LDA shipXP                          
      CMP #SHIP_XP_CAP                    ; check if XP is at max
      BNE .bDone                          
                        
      .resetXP:                           
                                          
        LDA #$00                          
        STA shipXP                        ; reset XP to 0
                                          
      .resetXPDone:                       
                                          
      .upgradeWeapon:                     
                                          
        LDA currentWeapon                 
        CMP #MAX_BULLET_ID                
        BEQ .upgradeWeaponDone            ; already on the best weapon
                                          
        INC currentWeapon                 ; upgrade the weapon
        JSR LoadBulletPointer             ; update the pointer
                                          
      .upgradeWeaponDone:                 
                                          
      .repairShip:                        
                                          
        LDA #SHIP_MAX_HP                  
        STA shipHP                        ; repair the ship
                                          
      .repairShipDone:                    
                                          
      INC updateHPBar                     ; update both bars
      INC updateXPBar
      
    .bDone:
  
  .processControllerDone:
  
UpdateShipDone:
  RTS
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                                      ;;
;;   UpdateShipIfNeeded                                       ;;
;;                                                            ;;
;; Description:                                               ;;
;;   Update the ship based on the following input variables:  ;;
;;   - shipMovement                                           ;;
;;   - shipMovementOld                                        ;;
;;   - updateShipPosition                                     ;;
;;   - updateShipTiles                                        ;;
;;   - updateShipAtts                                         ;;
;;   - updateExhaust                                          ;;
;;   - shipX                                                  ;;
;;   - shipY                                                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
UpdateShipIfNeeded

  .checkIfDirectionChanged:
   
    LDA shipMovement
    CMP shipMovementOld                 ; check if ship direction has changed since the last frame
    BEQ .checkIfDirectionChangedDone     
    LDA #$00                            ; direction changed, reset the timer 
    STA shipDirectionTimer
   
  .checkIfDirectionChangedDone:
   
  .updateDirection:
  
    INC shipDirectionTimer
    LDA shipDirectionTimer
    CMP #SHIP_ANIMATION_FREQ
    BNE .updateDirectionDone
    
    LDA #$00
    STA shipDirectionTimer
    
    LDA shipMovement
    CMP #SHIP_MOVEMENT_L
    BEQ .updateLeft
    
    CMP #SHIP_MOVEMENT_R
    BEQ .updateRight
    
    .updateUp:
      LDA shipDirection                ; check which direction to go
      CMP #SHIP_DIRECTION_U
      BEQ .updateDirectionDone         ; no update needed
      BCC .increment                   ; direction < up
      JMP .decrement                   ; direction > up
      
    .updateLeft:
      LDA shipDirection                ; check which direction to go
      CMP #SHIP_DIRECTION_F_L
      BEQ .updateDirectionDone         ; no update needed
      JMP .decrement                   ; when going left we always decrement
      
    .updateRight:
      LDA shipDirection                ; check which direction to go
      CMP #SHIP_DIRECTION_F_R
      BEQ .updateDirectionDone         ; no update needed
      JMP .increment                   ; when going right we always increment
      
    .increment:
      INC shipDirection
      INC updateShipTiles
      INC updateExhaust
      JMP .updateDirectionDone
      
    .decrement:
      DEC shipDirection
      INC updateShipTiles
      INC updateExhaust
      JMP .updateDirectionDone
  
  .updateDirectionDone:
   
  .updateExhaustAnimation:
  
    INC exhaustTimer
    LDA exhaustTimer
    CMP #EXHAUST_AN_FREQ
    BNE .updateExhaustAnimationDone
    
    LDA #$00
    STA exhaustTimer
    
    INC updateExhaust
    
    LDA exhaustNextTile
    CMP exhaustCurrentTile
    STA exhaustCurrentTile
    BCS .animationIncrementing
  
    .animationDecrementing:
      LDA exhaustNextTile
      CMP #EXHAUST_TILE_MIN
      BEQ .incrementAnimation        
      JMP .decrementAnimation
  
    .animationIncrementing:
      LDA exhaustNextTile
      CMP #EXHAUST_TILE_MAX
      BEQ .decrementAnimation        
      
    .incrementAnimation:
      INC exhaustNextTile
      JMP .updateExhaustAnimationDone
      
    .decrementAnimation:
      DEC exhaustNextTile
    
  .updateExhaustAnimationDone:
  
  .updateShip:                                                    
                        
    LDA shipDrawn                       
    BNE .updateWhatsNeeded              
                                        
    INC updateShipPosition              ; we get here when shipDrawn == 0. Mark everything as "must be updated"
    INC updateShipTiles                 
    INC updateShipAtts                  
    INC updateExhaust
    INC shipDrawn
   
    .updateWhatsNeeded:                 
                                        
      .updatePositionAndHitbox:         
        LDA updateShipPosition          
        BNE .updatePosition             
        JMP .updateTiles                
                                        
        .updatePosition:
          LDA shipX                     ; load the X position
          STA SHIP_X_OFF + SHIP_OFF_3   ; set the same position on the tiles in the same column
          STA SHIP_X_OFF + SHIP_OFF_6   
          CLC                           
          ADC #$08                      ; add 8 to the X position
          STA SHIP_X_OFF + SHIP_OFF_1   ; set that position on the tiles in the center column
          STA SHIP_X_OFF + SHIP_OFF_4   
          STA SHIP_X_OFF + SHIP_OFF_7   
          CLC                           
          ADC #$08                      ; add 8 to the X position again
          STA SHIP_X_OFF + SHIP_OFF_2   ; set that position on the tiles in the right column
          STA SHIP_X_OFF + SHIP_OFF_5   
          STA SHIP_X_OFF + SHIP_OFF_8   
                                        
          LDA shipY                     ; load the Y position
          STA SHIP_Y_OFF + SHIP_OFF_1   ; set the same position on the tiles in the same row
          STA SHIP_Y_OFF + SHIP_OFF_2   
          CLC                           
          ADC #$08                      ; add 8 to the Y position
          STA SHIP_Y_OFF + SHIP_OFF_3   ; set the position on the tiles in the center row
          STA SHIP_Y_OFF + SHIP_OFF_4   
          STA SHIP_Y_OFF + SHIP_OFF_5   
          CLC                           
          ADC #$08                      ; add 8 to the Y position again
          STA SHIP_Y_OFF + SHIP_OFF_6   ; set the position on the tiles in the bottom row
          STA SHIP_Y_OFF + SHIP_OFF_7     
          STA SHIP_Y_OFF + SHIP_OFF_8     
                                        
        .hitboxUpdate:                  
          CLC                           
          LDA shipX                     
          ADC #SHIP_OUT_HB_X_OFF        
          STA shipX1Outer               
          ADC #SHIP_OUT_HB_WIDTH        
          STA shipX2Outer               
          LDA shipY                     
          ADC #SHIP_OUT_HB_Y_OFF        
          STA shipY1Outer               
          ADC #SHIP_OUT_HB_HEIGHT       
          STA shipY2Outer               
                                        
          CLC                           
          LDA shipX                     
          ADC #SHIP_IN_HB_1_X_OFF       
          STA shipX1Inner1              
          ADC #SHIP_IN_HB_1_WIDTH       
          STA shipX2Inner1              
          LDA shipY                     
          ADC #SHIP_IN_HB_1_Y_OFF       
          STA shipY1Inner1              
          ADC #SHIP_IN_HB_1_HEIGHT      
          STA shipY2Inner1              
                                        
          CLC                           
          LDA shipX                     
          ADC #SHIP_IN_HB_2_X_OFF       
          STA shipX1Inner2              
          ADC #SHIP_IN_HB_2_WIDTH       
          STA shipX2Inner2              
          LDA shipY                     
          ADC #SHIP_IN_HB_2_Y_OFF       
          STA shipY1Inner2              
          ADC #SHIP_IN_HB_2_HEIGHT      
          STA shipY2Inner2              
                                        
        .centerUpdate:                  
          LDA shipX                     
          CLC                           
          ADC #SHIP_WIDTH / $02         
          STA shipXCenter               
                                        
          LDA shipY                     
          CLC                           
          ADC #SHIP_HEIGHT / $02        
          STA shipYCenter               
                                        
      .updateTiles:                     
        LDA updateShipTiles             
        BNE .tilesFarLeft
        JMP .updateAtts                 
      
        .tilesFarLeft:
          LDA shipDirection
          CMP #SHIP_DIRECTION_F_L
          BNE .tilesLeft
         
          LDA #SHIP_TILE_F_L
          STA SHIP_TILE_OFF                
          LDA #SHIP_TILE_F_L + $01            
          STA SHIP_TILE_OFF + SHIP_OFF_1  
          LDA #SHIP_TILE_F_L + $02            
          STA SHIP_TILE_OFF + SHIP_OFF_2  
          LDA #SHIP_TILE_F_L + $10            
          STA SHIP_TILE_OFF + SHIP_OFF_3  
          LDA #SHIP_TILE_F_L + $11            
          STA SHIP_TILE_OFF + SHIP_OFF_4  
          LDA #SHIP_TILE_F_L + $12            
          STA SHIP_TILE_OFF + SHIP_OFF_5  
          LDA #SHIP_TILE_F_L + $20            
          STA SHIP_TILE_OFF + SHIP_OFF_6  
          LDA #SHIP_TILE_F_L + $21            
          STA SHIP_TILE_OFF + SHIP_OFF_7  
          LDA #SHIP_TILE_F_L + $22            
          STA SHIP_TILE_OFF + SHIP_OFF_8  

        .tilesLeft:
          LDA shipDirection
          CMP #SHIP_DIRECTION_L
          BNE .tilesUp
         
          LDA #SHIP_TILE_L
          STA SHIP_TILE_OFF                
          LDA #SHIP_TILE_L + $01            
          STA SHIP_TILE_OFF + SHIP_OFF_1  
          LDA #SHIP_TILE_L + $02            
          STA SHIP_TILE_OFF + SHIP_OFF_2  
          LDA #SHIP_TILE_L + $10            
          STA SHIP_TILE_OFF + SHIP_OFF_3  
          LDA #SHIP_TILE_L + $11            
          STA SHIP_TILE_OFF + SHIP_OFF_4  
          LDA #SHIP_TILE_L + $12            
          STA SHIP_TILE_OFF + SHIP_OFF_5  
          LDA #SHIP_TILE_L + $20            
          STA SHIP_TILE_OFF + SHIP_OFF_6  
          LDA #SHIP_TILE_L + $21            
          STA SHIP_TILE_OFF + SHIP_OFF_7  
          LDA #SHIP_TILE_L + $22            
          STA SHIP_TILE_OFF + SHIP_OFF_8  

        .tilesUp:
          LDA shipDirection
          CMP #SHIP_DIRECTION_U
          BNE .tilesRight
        
          LDA #SHIP_TILE_U                  
          STA SHIP_TILE_OFF                
          LDA #SHIP_TILE_U + $01            
          STA SHIP_TILE_OFF + SHIP_OFF_1  
          LDA #SHIP_TILE_U + $02            
          STA SHIP_TILE_OFF + SHIP_OFF_2  
          LDA #SHIP_TILE_U + $10            
          STA SHIP_TILE_OFF + SHIP_OFF_3  
          LDA #SHIP_TILE_U + $11            
          STA SHIP_TILE_OFF + SHIP_OFF_4  
          LDA #SHIP_TILE_U + $12            
          STA SHIP_TILE_OFF + SHIP_OFF_5  
          LDA #SHIP_TILE_U + $20            
          STA SHIP_TILE_OFF + SHIP_OFF_6  
          LDA #SHIP_TILE_U + $21            
          STA SHIP_TILE_OFF + SHIP_OFF_7  
          LDA #SHIP_TILE_U + $22            
          STA SHIP_TILE_OFF + SHIP_OFF_8 
        
        .tilesRight:
          LDA shipDirection
          CMP #SHIP_DIRECTION_R
          BNE .tilesFarRight
         
          LDA #SHIP_TILE_R
          STA SHIP_TILE_OFF                
          LDA #SHIP_TILE_R + $01            
          STA SHIP_TILE_OFF + SHIP_OFF_1  
          LDA #SHIP_TILE_R + $02            
          STA SHIP_TILE_OFF + SHIP_OFF_2  
          LDA #SHIP_TILE_R + $10            
          STA SHIP_TILE_OFF + SHIP_OFF_3  
          LDA #SHIP_TILE_R + $11            
          STA SHIP_TILE_OFF + SHIP_OFF_4  
          LDA #SHIP_TILE_R + $12            
          STA SHIP_TILE_OFF + SHIP_OFF_5  
          LDA #SHIP_TILE_R + $20            
          STA SHIP_TILE_OFF + SHIP_OFF_6  
          LDA #SHIP_TILE_R + $21            
          STA SHIP_TILE_OFF + SHIP_OFF_7  
          LDA #SHIP_TILE_R + $22            
          STA SHIP_TILE_OFF + SHIP_OFF_8  
          
        .tilesFarRight:
          LDA shipDirection
          CMP #SHIP_DIRECTION_F_R
          BNE .updateAtts
         
          LDA #SHIP_TILE_F_R
          STA SHIP_TILE_OFF                
          LDA #SHIP_TILE_F_R + $01            
          STA SHIP_TILE_OFF + SHIP_OFF_1  
          LDA #SHIP_TILE_F_R + $02            
          STA SHIP_TILE_OFF + SHIP_OFF_2  
          LDA #SHIP_TILE_F_R + $10            
          STA SHIP_TILE_OFF + SHIP_OFF_3  
          LDA #SHIP_TILE_F_R + $11            
          STA SHIP_TILE_OFF + SHIP_OFF_4  
          LDA #SHIP_TILE_F_R + $12            
          STA SHIP_TILE_OFF + SHIP_OFF_5  
          LDA #SHIP_TILE_F_R + $20            
          STA SHIP_TILE_OFF + SHIP_OFF_6  
          LDA #SHIP_TILE_F_R + $21            
          STA SHIP_TILE_OFF + SHIP_OFF_7  
          LDA #SHIP_TILE_F_R + $22            
          STA SHIP_TILE_OFF + SHIP_OFF_8   
                                        
      .updateAtts:                      
        LDA updateShipAtts              
        BEQ .updateExhaust             
                                        
        LDA #SHIP_ATT                   
        STA SHIP_ATT_OFF                
        STA SHIP_ATT_OFF + SHIP_OFF_1   
        STA SHIP_ATT_OFF + SHIP_OFF_2   
        STA SHIP_ATT_OFF + SHIP_OFF_3   
        STA SHIP_ATT_OFF + SHIP_OFF_4   
        STA SHIP_ATT_OFF + SHIP_OFF_5   
        STA SHIP_ATT_OFF + SHIP_OFF_6   
        STA SHIP_ATT_OFF + SHIP_OFF_7   
        STA SHIP_ATT_OFF + SHIP_OFF_8   
                          
      .updateExhaust:
        LDA updateExhaust
        BEQ .updateShipDone
                 
        LDA shipX
        CLC
        ADC #EXHAUST_X_OFFSET
        ADC shipDirection
        SEC
        SBC #$02                        ; same logic as bullet firing
        STA SPRITE_EXHAUST + X_OFF
        
        LDA shipY
        CLC
        ADC #EXHAUST_Y_OFFSET
        STA SPRITE_EXHAUST + Y_OFF
        
        LDA #EXHAUST_ATT
        STA SPRITE_EXHAUST + ATT_OFF
        
        LDA exhaustCurrentTile
        STA SPRITE_EXHAUST + TILE_OFF          
        
  .updateShipDone: 

  LDA #$00                              
  STA updateShipPosition                
  STA updateShipTiles                   
  STA updateShipAtts                    
  STA updateExhaust
  
  LDA shipMovement
  STA shipMovementOld
  
  RTS
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                     ;;
;;   UpdateHPBar                             ;;
;;                                           ;;
;; Description:                              ;;
;;   Updates the HP to present new HP value  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
UpdateHPBar:

  LDA updateHPBar
  BEQ UpdateHPBarDone
  
  LDA #$00
  STA updateHPBar

  LDX shipHP

  LDA #HP_Y_0
  STA SPRITE_HP_BAR_0 + Y_OFF
    
  LDA bar_lookup_0, x
  STA SPRITE_HP_BAR_0 + TILE_OFF

  LDA #HP_ATT
  STA SPRITE_HP_BAR_0 + ATT_OFF

  LDA #HP_X_0
  STA SPRITE_HP_BAR_0 + X_OFF

  LDA #HP_Y_1
  STA SPRITE_HP_BAR_1 + Y_OFF
  
  LDA bar_lookup_1, x
  STA SPRITE_HP_BAR_1 + TILE_OFF

  LDA #HP_ATT
  STA SPRITE_HP_BAR_1 + ATT_OFF

  LDA #HP_X_1
  STA SPRITE_HP_BAR_1 + X_OFF

UpdateHPBarDone:  
  RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                         ;;
;;   UpdateXPBar                                 ;;
;;                                               ;;
;; Description:                                  ;;
;;   Updates the XP bar to present new XP value  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateXPBar:

  LDA updateXPBar
  BEQ UpdateXPBarDone
  
  LDA #$00
  STA updateXPBar

  LDA shipXP                      ; load the xp value
  LSR A                           ; divide it by 4 to be able to use the lookup table
  LSR A                           ; 0-3 will be 0, 4-7 will be 1, ..., 28-31 will be 7, 32 will be 8
  TAX

  LDA #XP_Y_0
  STA SPRITE_XP_BAR_0 + Y_OFF
    
  LDA bar_lookup_0, x
  STA SPRITE_XP_BAR_0 + TILE_OFF

  LDA #XP_ATT
  STA SPRITE_XP_BAR_0 + ATT_OFF

  LDA #XP_X_0
  STA SPRITE_XP_BAR_0 + X_OFF

  LDA #XP_Y_1
  STA SPRITE_XP_BAR_1 + Y_OFF
  
  LDA bar_lookup_1, x
  STA SPRITE_XP_BAR_1 + TILE_OFF

  LDA #XP_ATT
  STA SPRITE_XP_BAR_1 + ATT_OFF

  LDA #XP_X_1
  STA SPRITE_XP_BAR_1 + X_OFF

UpdateXPBarDone:
  RTS
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                           ;;
;;   FireBullet                    ;;
;;                                 ;;
;; Description:                    ;;
;;   Fire new bullet (if possible) ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NoSlots:
  RTS

FireBullet:

  .checkSpace:
  
    LDY #BULLET_C_FIRED
    LDA [bulletLow], y              ; load the number of bullets to fire
    TAY                             ; move it to Y
    
    LDX #$00
    
    .checkSpaceLoop:
        LDA SPRITES_BULLETS, x
        CMP #CLEAR_SPRITE           ; check if the slot is available
        BNE .checkNext              ; not available
        
        .empty:                     ; slot is available
          DEY                       ; decrement Y
          BEQ .firingPrep           ; if Y == 0 it means there's enough slots
        
        .checkNext:
          INX                         
          INX                         
          INX                         
          INX                       ; X += 4
          CPX #BULLETS_SIZE           
          BEQ NoSlots               ; we've checked everything. Not enough slots. Exit.
          JMP .checkSpaceLoop  
      
  .checkSpaceDone:
     
  .firingPrep:
   
    LDY #BULLET_C_FIRED
    LDA [bulletLow], y              ; load the number of bullets again
    SEC
    SBC #$01                        ; decrement it  
    ASL A                           ; x2. So now A = (number of bullets - 1) x 2
    STA placeholder1                ; store it in placeholder1
    JSR LaserSound
  
  .firingPrepDone:
  
  .fireBulletLoop:
  
    .findSlot:
    
      LDX #$00
    
      .loop:
        LDA SPRITES_BULLETS, x
        CMP #CLEAR_SPRITE           ; look for the first available slot
        BCS .findSlotDone           ; found a bullet that's off-screen
        INX                         
        INX                         
        INX                         
        INX                         ; X += 4
        CPX #BULLETS_SIZE           
        BEQ FireBulletDone          ; no available slots. No need to check if there are any more bullets.
        JMP .loop                   
                                    
    .findSlotDone:                  ; if we got here, X contains the slot number to use
    
    .fireBullet:
    
      .drawBullet:
        
        LDA shipY
        LDY #BULLET_Y_OFF
        SEC
        SBC [bulletLow], y          ; subtract the Y offset from ship Y          
        STA SPRITES_BULLETS, x      ; set the Y position of the bullet
        
        INX
        LDY #BULLET_TILE
        LDA [bulletLow], y          ; load the tile
        STA SPRITES_BULLETS, x      ; set the tile of the bullet
    
        INX
        LDY #BULLET_ATT
        LDA [bulletLow], y          ; load the atts.
        STA SPRITES_BULLETS, x      ; set the atts. of the bullet
        
        INX
        LDA shipX                   ; load shipX
        LDY #BULLET_X_OFF
        CLC
        ADC [bulletLow], y          ; add the X offset to ship X
        ADC shipDirection           ; add shipDirection
        SEC
        SBC #$02                    ; finally, subract 2 - this will give enough offset so everything lines up
        STA SPRITES_BULLETS, x      ; set the X position of the bullet
    
      .drawBulletDone:
    
      .initBullet:
      
        DEX
        DEX
        DEX                         ; X -= 3, points to the right place now
        
        LDY #BULLET_DAMAGE
        LDA [bulletLow], y
        STA MEMORY_BULLETS, x       ; copy the bullet damage
    
        INX
        LDY #BULLET_SIZE
        LDA [bulletLow], y
        STA MEMORY_BULLETS, x       ; copy the bullet size
        
        INX
        LDA #BULLET_SPEED
        CLC
        ADC placeholder1            ; add the placeholder to get the right bullet
        TAY                         ; move A to Y
        LDA [bulletLow], y
        STA MEMORY_BULLETS, x       ; copy the bullet x speed
        
        INX
        INY                         ; increment Y so it points to the y speed
        LDA [bulletLow], y
        STA MEMORY_BULLETS, x       ; copy the bullet y speed
        
      .initBulletDone:
    
    .fireBulletDone:
    
    LDA placeholder1
    BEQ FireBulletDone              ; placeholder1 == 0 means we're done
    SEC
    SBC #$02                        ; subtact 2 so it points to the next bullet
    STA placeholder1                ; store it back in the placeholder
    JMP .fireBulletLoop             ; fire next bullet
  
FireBulletDone:
  RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                ;;
;;   UpdateBullets                      ;;
;;                                      ;;
;; Description:                         ;;
;;   Update the position of all bullets ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateBullets:
  JSR UpdatePlayersBullets
  JSR UpdateEnemyBullets
  RTS
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                     ;;
;;   UpdatePlayersBullets                    ;;
;;                                           ;;
;; Description:                              ;;
;;   Update the position of players bullets  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdatePlayersBullets:
 
  LDX #$00

  .loop:
    STX placeholder1                 ; store the bullet index in placeholder1
    CPX #BULLETS_SIZE              
    BNE .checkIfExists
    RTS

    .checkIfExists:                  
      LDA SPRITES_BULLETS, x          
      CMP #CLEAR_SPRITE              ; check if the bullet is created
      BNE .checkIfExploding          
      JMP .goToNext                  ; not created, go to next
                                     
    .checkIfExploding:               
      LDA MEMORY_BULLETS, x       
      BNE .loadOffsets               ; damage == 0 means bullet is exploding
                                     
    .checkIfShouldUpdateAnimation:   
      INX                            ; X points at the timer
      INC MEMORY_BULLETS, x          ; increment the timer
      LDA MEMORY_BULLETS, x       
      CMP #B_EXPLOSION_TIMER          
      BEQ .checkIfAnimationFinished  
      JMP .goToNext                  ; too soon to update animation
                                     
    .checkIfAnimationFinished:
      LDA #$00
      STA MEMORY_BULLETS, x          ; reset the timer
      LDA SPRITES_BULLETS, x         ; X points to the tile
      CMP #B_EXPLOSION_END
      BNE .updateAnimation
      JMP .clearBullet               ; animation finished, delete the bullet
                                     
    .updateAnimation:
      INC SPRITES_BULLETS, x
      JMP .goToNext                  ; not created, go to next
                                  
    .loadOffsets:                                                  
      TXA                         
      CLC                         
      ADC #BULLET_MEM_SPEED_X     
      TAX                         
      LDA MEMORY_BULLETS, x          ; load the x speed
      STA placeholder2               ; store it in placeholder 2
      INX                            
      LDA MEMORY_BULLETS, x          ; load the y speed
      STA placeholder3               ; store it in placeholder 3
                                     
    .moveX:                                                            
      LDX placeholder1               
      INX                            
      INX                            
      INX                            ; X += 3, points at the x position
                                     
      LDA placeholder2                 
      BMI .goingLeft                   
                                             
      .goingRight:                   ; x offset >= 0                                  
        LDA SPRITES_BULLETS, x             
        CLC                                
        ADC placeholder2             
        BCC .setX                    
        JMP .clearBullet             ; sprite is off screen - delete the bullet
                                                                                     
      .goingLeft:                    ; x offset < 0                                  
        LDA SPRITES_BULLETS, x             
        CLC                                
        ADC placeholder2               
        BCS .setX                    
        JMP .clearBullet             ; sprite is off screen - delete the bullet         
                                     
      .setX:                                                           
        STA SPRITES_BULLETS, x       
                                     
    .moveY:                                                            
      LDX placeholder1               ; X points at the y position  
                                     
      LDA placeholder3               
      BMI .goingUp                   
                                     
      .goingDown:                    
        LDA SPRITES_BULLETS, x             
        CLC                                
        ADC placeholder3             
        CMP #SCREEN_BOTTOM           
        BCC .setY                    
        JMP .clearBullet             ; sprite is off screen - delete the bullet
                                     
      .goingUp:                      
        LDA SPRITES_BULLETS, x             
        CLC                                
        ADC placeholder3               
        BCS .setY                    
        JMP .clearBullet             ; sprite is off screen - delete the bullet
                                     
      .setY:                         
        STA SPRITES_BULLETS, x       ; store the modified position
        JMP .goToNext                ; go to next
                                     
    .clearBullet:                    
      LDX placeholder1               ; load the bullet index from placeholder1
      LDA #CLEAR_SPRITE              
      STA SPRITES_BULLETS, x         
      INX                            
      STA SPRITES_BULLETS, x         
      INX                            
      STA SPRITES_BULLETS, x         
      INX                            
      STA SPRITES_BULLETS, x         
      INX                            ; we've reset the sprite and X += 4
      JMP .loop                      
                                     
    .goToNext:                       
      LDX placeholder1               ; load the bullet index from placeholder1
      INX                            
      INX                            
      INX                            
      INX                            ; X += 4
      JMP .loop
  
UpdatePlayersBulletsDone:
  RTS
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                                    ;;
;;   UpdateEnemyBullets                                     ;;
;;                                                          ;;
;; Description:                                             ;;
;;   Update the position of enemy bullets                   ;;
;;   Note: this is a copy paste of UpdatePlayersBullets     ;;
;;         with some vars replaced. Any changes there must  ;;
;;         be reflected here, and vice versa                ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateEnemyBullets:
 
  LDX #$00

  .loop:
    STX placeholder1                 ; store the bullet index in placeholder1
    CPX #EN_BULLETS_SIZE             
    BNE .checkIfExists               
    RTS
                                     
    .checkIfExists:                  
      LDA SPRITES_EN_BULLETS, x          
      CMP #CLEAR_SPRITE              ; check if the bullet is created
      BNE .checkIfExploding          
      JMP .goToNext                  ; not created, go to next
                                     
    .checkIfExploding:               
      LDA MEMORY_EN_BULLETS, x       
      BNE .loadOffsets               ; damage == 0 means bullet is exploding
                                     
    .checkIfShouldUpdateAnimation:   
      INX                            ; X points at the timer
      INC MEMORY_EN_BULLETS, x       ; increment the timer
      LDA MEMORY_EN_BULLETS, x       
      CMP #B_EXPLOSION_TIMER          
      BEQ .checkIfAnimationFinished  
      JMP .goToNext                  ; too soon to update animation
                                     
    .checkIfAnimationFinished:
      LDA #$00
      STA MEMORY_EN_BULLETS, x       ; reset the timer
      LDA SPRITES_EN_BULLETS, x      ; X points to the tile
      CMP #B_EXPLOSION_END
      BNE .updateAnimation
      JMP .clearBullet               ; animation finished, delete the bullet
                                     
    .updateAnimation:
      INC SPRITES_EN_BULLETS, x
      JMP .goToNext                  
                                     
    .loadOffsets:                                                    
      TXA                            
      CLC                            
      ADC #BULLET_MEM_SPEED_X        
      TAX                            
      LDA MEMORY_EN_BULLETS, x       ; load the x speed
      STA placeholder2               ; store it in placeholder 2
      INX                            
      LDA MEMORY_EN_BULLETS, x       ; load the y speed
      STA placeholder3               ; store it in placeholder 3
                                     
    .moveX:                                                            
      LDX placeholder1               
      INX                            
      INX                            
      INX                            ; X += 3, points at the x position
                                     
      LDA placeholder2                 
      BMI .goingLeft                   
                                             
      .goingRight:                   ; x offset >= 0                                  
        LDA SPRITES_EN_BULLETS, x             
        CLC                                
        ADC placeholder2             
        BCC .setX                    
        JMP .clearBullet             ; sprite is off screen - delete the bullet
                                                                                     
      .goingLeft:                    ; x offset < 0                                  
        LDA SPRITES_EN_BULLETS, x             
        CLC                                
        ADC placeholder2               
        BCS .setX                    
        JMP .clearBullet             ; sprite is off screen - delete the bullet         
                                     
      .setX:                                                           
        STA SPRITES_EN_BULLETS, x       
                                     
    .moveY:                                                            
      LDX placeholder1               ; X points at the y position  
                                     
      LDA placeholder3               
      BMI .goingUp                   
                                     
      .goingDown:                    
        LDA SPRITES_EN_BULLETS, x             
        CLC                                
        ADC placeholder3             
        CMP #SCREEN_BOTTOM           
        BCC .setY                    
        JMP .clearBullet             ; sprite is off screen - delete the bullet
                                     
      .goingUp:                      
        LDA SPRITES_EN_BULLETS, x             
        CLC                                
        ADC placeholder3               
        BCS .setY                    
        JMP .clearBullet             ; sprite is off screen - delete the bullet
                                     
      .setY:                         
        STA SPRITES_EN_BULLETS, x    ; store the modified position
        JMP .goToNext                ; go to next
                                     
    .clearBullet:                    
      LDX placeholder1               ; load the bullet index from placeholder1
      LDA #CLEAR_SPRITE              
      STA SPRITES_EN_BULLETS, x         
      INX                            
      STA SPRITES_EN_BULLETS, x         
      INX                            
      STA SPRITES_EN_BULLETS, x         
      INX                            
      STA SPRITES_EN_BULLETS, x         
      INX                            ; we've reset the sprite and X += 4
      JMP .loop                      
                                     
    .goToNext:                       
      LDX placeholder1               ; load the bullet index from placeholder1
      INX                            
      INX                            
      INX                            
      INX                            ; X += 4
      JMP .loop
  
UpdateEnemyBulletsDone:
  RTS
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                                        ;;
;;   SpawnEnemies                                               ;;
;;                                                              ;;
;; Description:                                                 ;;
;;   Check if new enemies must be spawned, and do so if needed  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NoSpawn:
  RTS

SpawnEnemies: 

  LDA newRow
  BEQ NoSpawn                   ; only spawn on newRow

  LDY #$00
  
  .scrollLoop:                  ; check if there are any enemies to spawn
    LDA [enScreenLow], y        ; load the scroll
    CMP #$FF                    
    BEQ NoSpawn                 ; FF means processing is done
                                
    CMP scroll                  ; compare with the current scroll
    BCC NoSpawn                 ; carry clear means scroll from table < current scroll,
                                ; meaning we shouldn't spawn enemies yet. Exit.    
                                
    BEQ .willSpawn              ; if scroll from table == current scroll, spawn the enemy
                                
    INY                         
    INY
    INY    
    INY                         ; Y += 4
    JMP .scrollLoop             ; move to the next entry
                                
  .willSpawn:                   ; we will spawn the enemy
                                
    LDX #$00
                                
    .slotLoop:                  ; find a slot in memory to spawn it                             
      LDA SPRITES_ENEMIES, x    
      CMP #CLEAR_SPRITE         ; look for the first available slot
      BCS .loadEnemy            ; found an enemy that's off-screen
      
      TXA
      CLC
      ADC #$10
      TAX                       ; X += 16
 
      CPX #ENEMIES_SIZE
      BEQ NoSpawn               ; no available slots, skip the enemy
      JMP .slotLoop
    
    .loadEnemy:
      STX placeholder1          ; X now contains the target metasprite index.
                                ; store that in placeholder1 for now    
  
      INY
      LDA [enScreenLow], y      ; load the index of the enemy to A
      ASL A                     ; x2 because we're loading a pointer
      TAX                       ; move it to X
      LDA enemies, x            
      STA enemyHigh             ; high byte of the enemy address
      INX
      LDA enemies, x
      STA enemyLow              ; low byte of the enemy address
      
      LDX placeholder1          ; load the target metasprite index back to the X register
      
      INY                     
      LDA [enScreenLow], y      ; load the initial x position of the enemy
      STA placeholder1          ; store the initial x position of the enemy in placeholder1
      
      INY                     
      LDA [enScreenLow], y      ; load the initial y position of the enemy
      STA placeholder2          ; store the initial y position of the enemy in placeholder1
      
    .drawEnemy:
    
      LDA placeholder2          ; SPRITE 0
      STA SPRITES_ENEMIES, x    ; y position of sprite 0
      LDY #SPEC_TILES           ; load the tiles offset to Y
      LDA [enemyLow], y         ; load the tile for sprite 0
      INX                       ; x points to the tile of sprite 0
      STA SPRITES_ENEMIES, x    ; set the tile
      LDY #SPEC_ATT             ; load the att. offset to Y
      LDA [enemyLow], y         ; load the att. for sprite 0
      INX                       ; x points to the att. of sprite 0
      STA SPRITES_ENEMIES, x    ; set the att.
      LDA placeholder1          ; load the initial x
      INX                       ; x points to the x position of sprite 0
      STA SPRITES_ENEMIES, x    ; set the x position
      INX                       ; x points to the next sprite
      
      LDA placeholder2          ; SPRITE 1
      STA SPRITES_ENEMIES, x    ; y position of sprite 1
      LDY #SPEC_TILES           ; load the tiles offset to Y
      INY                       ; point to the 2nd tile
      LDA [enemyLow], y         ; load the tile for sprite 1
      INX                       ; x points to the tile of sprite 1
      STA SPRITES_ENEMIES, x    ; set the tile
      LDY #SPEC_ATT             ; load the att. offset to Y
      INY                       ; point to the 2nd att.
      LDA [enemyLow], y         ; load the att. for sprite 1
      INX                       ; x points to the att. of sprite 1
      STA SPRITES_ENEMIES, x    ; set the att.
      LDA placeholder1          ; load the initial x
      CLC
      ADC #$08                  ; add 8 to the initial X
      INX                       ; x points to the x position of sprite 1
      STA SPRITES_ENEMIES, x    ; set the x position
      INX                       ; x points to the next sprite

      LDA placeholder2          ; SPRITE 2
      CLC
      ADC #$08                  ; add 8 to the initial Y
      STA SPRITES_ENEMIES, x    ; y position of sprite 2
      LDY #SPEC_TILES           ; load the tiles offset to Y
      INY
      INY                       ; point to the 3rd tile
      LDA [enemyLow], y         ; load the tile for sprite 2
      INX                       ; x points to the tile of sprite 2
      STA SPRITES_ENEMIES, x    ; set the tile
      LDY #SPEC_ATT             ; load the att. offset to Y
      INY
      INY                       ; point to the 3rd att.
      LDA [enemyLow], y         ; load the att. for sprite 2
      INX                       ; x points to the att. of sprite 2
      STA SPRITES_ENEMIES, x    ; set the att.
      LDA placeholder1          ; load the initial x
      INX                       ; x points to the x position of sprite 2
      STA SPRITES_ENEMIES, x    ; set the x position
      INX                       ; x points to the next sprite

      LDA placeholder2          ; SPRITE 3
      CLC
      ADC #$08                  ; add 8 to the initial Y
      STA SPRITES_ENEMIES, x    ; y position of sprite 2
      LDY #SPEC_TILES           ; load the tiles offset to Y
      INY
      INY
      INY                       ; point to the 4th tile
      LDA [enemyLow], y         ; load the tile for sprite 3
      INX                       ; x points to the tile of sprite 3
      STA SPRITES_ENEMIES, x    ; set the tile
      LDY #SPEC_ATT             ; load the att. offset to Y
      INY
      INY
      INY                       ; point to the 4h att.
      LDA [enemyLow], y         ; load the att. for sprite 3
      INX                       ; x points to the att. of sprite 3
      STA SPRITES_ENEMIES, x    ; set the att.
      LDA placeholder1          ; load the initial x
      CLC
      ADC #$08                  ; add 8 to the initial X
      INX                       ; x points to the x position of sprite 3
      STA SPRITES_ENEMIES, x    ; set the x position
      INX                       ; x points to the next sprite
      
    .initEnemyMemory:
    
      TXA                       ; move X to ADC
      SEC
      SBC #$10                  ; subract 16. Now A is {metasprite} x 16
      TAX                       ; move back to X. MEMORY_ENEMIES + X points to the right place in memory
      
      LDY #SPEC_HB_X_OFFSET
      LDA [enemyLow], y
      STA MEMORY_ENEMIES, x     ; hitbox x offset (byte 0)
      
      LDY #SPEC_HB_Y_OFFSET
      LDA [enemyLow], y
      INX                       ; X = 1
      STA MEMORY_ENEMIES, x     ; hitbox y offset (byte 1)
      
      LDY #SPEC_HITBOX_W    
      LDA [enemyLow], y
      INX                       ; X = 2
      STA MEMORY_ENEMIES, x     ; hitbox width (byte 2)
      
      LDY #SPEC_HITBOX_H    
      LDA [enemyLow], y
      INX                       ; X = 3
      STA MEMORY_ENEMIES, x     ; hitbox height (byte 3)
      
      LDY #SPEC_MAX_HP      
      LDA [enemyLow], y
      INX                       ; X = 4
      STA MEMORY_ENEMIES, x     ; current hp = max hp (byte 4)

      LDY #SPEC_RAM_DAMAGE  
      LDA [enemyLow], y
      INX                       ; X = 5
      STA MEMORY_ENEMIES, x     ; ram damage (byte 5)
      
      LDY #SPEC_MOVE_TYPE   
      LDA [enemyLow], y
      INX                       ; X = 6
      STA MEMORY_ENEMIES, x     ; move type (byte 6)
      
      LDY #SPEC_MOVE_PARAM_1
      LDA [enemyLow], y
      INX                       ; X = 7
      STA MEMORY_ENEMIES, x     ; move param 1 (byte 7)
      
      LDY #SPEC_MOVE_PARAM_2
      LDA [enemyLow], y
      INX                       ; X = 8
      STA MEMORY_ENEMIES, x     ; move param 2 (byte 8)
      
      LDY #SPEC_XP_YIELD
      LDA [enemyLow], y
      INX                       ; X = 9
      STA MEMORY_ENEMIES, x     ; XP yield (byte 9)
      
      LDY #SPEC_BULLET_HIGH
      LDA [enemyLow], y
      INX                       ; X = 10
      STA MEMORY_ENEMIES, x     ; bullet high pointer (byte 10)
      
      LDY #SPEC_BULLET_LOW
      LDA [enemyLow], y
      INX                       ; X = 11
      STA MEMORY_ENEMIES, x     ; bullet low pointer (byte 11)

      LDY #SPEC_BULLET_X_OFF
      LDA [enemyLow], y
      INX                       ; X = 12
      STA MEMORY_ENEMIES, x     ; bullet x offset (byte 12)
      
      LDY #SPEC_BULLET_Y_OFF
      LDA [enemyLow], y
      INX                       ; X = 13
      STA MEMORY_ENEMIES, x     ; bullet y offset (byte 13)
      
      LDY #SPEC_SHOOT_FREQ  
      LDA [enemyLow], y
      INX                       ; X = 14
      STA MEMORY_ENEMIES, x     ; shooting freq (byte 14)
      
      LDA #$00                  ; timer starts at #$00 and goes up
      INX                       ; X = 15
      STA MEMORY_ENEMIES, x     ; shooting timer (byte 15)
      
SpawnEnemiesDone:
  RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                                    ;;
;;   UpdateEnemies                                          ;;
;;                                                          ;;
;; Description:                                             ;;
;;   Update enemies position based on their movement type.  ;;
;;   Also process enemies shooting.                         ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
UpdateEnemies:
  
  LDX #$00
  
  .slotLoop:
    LDA SPRITES_ENEMIES, x    
    CMP #CLEAR_SPRITE                    ; check if the slot is filled
    BCC .updateEnemy                     ; slot is not filled
    STX placeholder1                     ; store the offset in placeholder1 as that's where nextSlot expectes it
    JMP .nextSlot                        
                                         
    .updateEnemy:                                                           
      TXA                                
      STA placeholder1                   ; store the offset in placeholder1 as we'll need it later
      CLC                                
      ADC #EN_CURRENT_HP
      TAX
      LDA MEMORY_ENEMIES, x              ; load current HP
      BNE .calculateMoveOffset           ; hp > 0 means enemy still alive
                   
      .updateExplosion:                  ; enemy is an explosion
      
        LDA placeholder1
        CLC
        ADC #EN_SHOOT_TIMER
        TAX
        INC MEMORY_ENEMIES, x            ; increment the timer
        LDA MEMORY_ENEMIES, x
        CMP #EN_EXPLOSION_TIMER
        BEQ .updateAnimation
        JMP .nextSlot                    ; too soon to update animation
        
        .updateAnimation:                ; time to update animation
        
          LDA #$00
          STA MEMORY_ENEMIES, x          ; reset timer to 0
          
          LDX placeholder1
          INX
          LDA SPRITES_ENEMIES, x
          CMP #EN_EXPLOSION_END          ; check if animation is done
          BNE .nextFrame
          DEX
          JSR DeleteEnemy                ; animation is done, delete the enemy
          JMP .nextSlot
          
          .nextFrame:                    ; time for the next explosion frame
        
            LDX placeholder1             ; update the tiles
            INX
            INC SPRITES_ENEMIES, x
            INC SPRITES_ENEMIES, x       ; offset between tiles in different frames is 2
            INX
            INX
            INX
            INX
            INC SPRITES_ENEMIES, x
            INC SPRITES_ENEMIES, x
            INX
            INX
            INX
            INX
            INC SPRITES_ENEMIES, x
            INC SPRITES_ENEMIES, x
            INX
            INX
            INX
            INX
            INC SPRITES_ENEMIES, x
            INC SPRITES_ENEMIES, x
            JMP .nextSlot
                           
      .calculateMoveOffset:              
      
        LDA placeholder1
        CLC                                
        ADC #EN_MOVE_TYPE                  
        TAX                                
        LDA MEMORY_ENEMIES, x            ; load the movement type
      
        CMP #MOVE_TYPE_SINUS
        BEQ .sinus
                                           
        .linear:                         ; checked all other move types, it must be linear                        
          INX                            ; X points to param 1
          LDA MEMORY_ENEMIES, x          ; load the X speed
          STA placeholder2               ; store it in placeholder2
          INX                            ; X points to param 2
          LDA MEMORY_ENEMIES, x          ; load the Y speed
          CMP #$FF                       
          BNE .loadY                     
          LDA scrollSpeed                ; Y speed == #$FF means move with the screen                                     
          .loadY:                        
            STA placeholder3             ; store the Y speed in placeholder3                                          
          JMP .calculateMoveOffsetDone                      
          
        .sinus:
          INX                            ; X points to param 1
          LDA MEMORY_ENEMIES, x          ; load the current state
          STA placeholder2               ; store it in placeholder2 for now
          INX                            ; X points to param 2
          LDA MEMORY_ENEMIES, x          ; load the timer
          CLC
          ADC #$01                       ; increment the timer
          CMP #SINUS_FREQ
          BEQ .sinusIncState             ; check if it's time to increment the state
          STA MEMORY_ENEMIES, x          ; not time to increment the state yet. Set the updated timer
          JMP .loadSinusSpeed
                    
          .sinusIncState:
            LDA #$00
            STA MEMORY_ENEMIES, x        ; reset the timer to 0
            DEX                          ; X points to param 1 again
            LDA placeholder2             ; load the state back            
            CLC
            ADC #$01                     ; increment it
            CMP #SINUS_SEQ_COUNT
            BNE .sinusSetState
            LDA #$00                     ; wrap the state
            .sinusSetState:
              STA MEMORY_ENEMIES, x      ; store the new state
          
          .loadSinusSpeed:
            LDA placeholder2             ; load the state back
            ASL A                        ; x2
            TAX                          ; move the state to X          
            LDA moveSinus, x             ; load the X speed
            STA placeholder2             ; store it in placeholder2
            INX
            LDA moveSinus, x             ; load the Y speed
            STA placeholder3             ; store it in placeholder3                    
          
      .calculateMoveOffsetDone:          
                                         
      .moveEnemy:                        ; by now X change is in placeholder2 and Y change is in placeholder3
        LDX placeholder1                 ; load the metasprite pointer back from placeholder1
        LDY #$00                         ; Y is the loop counter
                                         
        .moveLoop:                       
                                         
          .updateY:                      
                                         
            LDA placeholder3             
            BMI .goingUp                 
                                         
            .goingDown:                  
              LDA SPRITES_ENEMIES, x     
              CLC                            
              ADC placeholder3               
              CMP #SCREEN_BOTTOM                       
              BCC .setY                  
                                         
              LDX placeholder1           ; load the metasprite pointer back from placeholder1
              JSR DeleteEnemy            ; sprite is off screen - delete the enemy
              JMP .nextSlot              
                                         
            .goingUp:                    
              LDA SPRITES_ENEMIES, x     
              CLC                            
              ADC placeholder3               
              BCS .setY                  
                                         
              LDX placeholder1           ; load the metasprite pointer back from placeholder1
              JSR DeleteEnemy            ; sprite is off screen - delete the enemy
              JMP .nextSlot              
                                         
            .setY:                       
              STA SPRITES_ENEMIES, x     
              INX                            
              INX                            
              INX                        
                                         
          .updateYDone:                  
                                         
          .updateX:                      
                                         
            LDA placeholder2             
            BMI .goingLeft               
                                         
            .goingRight:                 ; x offset >= 0
              LDA SPRITES_ENEMIES, x         
              CLC                            
              ADC placeholder2           
              BCC .setX                  
                                         
              LDX placeholder1           ; load the metasprite pointer back from placeholder1
              JSR DeleteEnemy            ; sprite is off screen - delete the enemy
              JMP .nextSlot              
                                                                                 
            .goingLeft:                  ; x offset < 0
              LDA SPRITES_ENEMIES, x         
              CLC                            
              ADC placeholder2           
              BCS .setX                  
                                         
              LDX placeholder1           ; load the metasprite pointer back from placeholder1
              JSR DeleteEnemy            ; sprite is off screen - delete the enemy
              JMP .nextSlot              
                                         
            .setX:                       
              STA SPRITES_ENEMIES, x     
              INX                        
                                         
          .updateXDone:                  
                                                                    
          INY                            
          CPY #$04                       
          BEQ .moveEnemyDone                  
          JMP .moveLoop                  
                                         
      .moveEnemyDone:                    
                                         
      .shootingUpdate:                   
                                         
        .checkIfShouldShoot:             
                                         
          LDA placeholder1               ; load the metasprite pointer back from placeholder1
          CLC                            
          ADC #EN_SHOOT_TIMER            
          TAX                            ; X now points to the shooting timer
                                         
          INC MEMORY_ENEMIES, x          ; increment the timer
          LDA MEMORY_ENEMIES, x          ; load it
          DEX                            ; X now points to the shooting frequency
          CMP MEMORY_ENEMIES, x          ; compare the timer in A with the frequency in memory
          BEQ .willFire
          JMP .shootingUpdateDone        ; too soon to fire a bullet
                                         
        .willFire:
          INX                            ; X points to the timer again
          LDA #$00                       
          STA MEMORY_ENEMIES, x          ; reset the timer to 0
                                         
        .checkIfShouldShootDone:         
                                         
        .findBulletSlot:
                                         
          LDX #$00                       
                                         
          .findSlotLoop:                 
              LDA SPRITES_EN_BULLETS, x  
              CMP #CLEAR_SPRITE          ; check if the slot is available
              BNE .checkNext             ; not available
                                         
              .slotFound:                ; slot is available
                STX placeholder2         ; store the bullet slot index in placeholder2
                JMP .findBulletSlotDone
                                         
              .checkNext:                
                INX                        
                INX                        
                INX                        
                INX                      ; X += 4
                CPX #EN_BULLETS_SIZE
                BNE .findSlotLoop
                JMP .shootingUpdateDone  ; we've checked everything, no free slots
                                         
        .findBulletSlotDone:             
                                         
        .loadPosition:                   
                           
          .loadEnemyPosition:
          
            LDX placeholder1             ; load the metasprite pointer back from placeholder1
            LDA SPRITES_ENEMIES, x       
            STA placeholder4             ; placeholder4 now holds the y position of the enemy
            INX                          
            INX                          
            INX                          
            LDA SPRITES_ENEMIES, x       
            STA placeholder3             ; placeholder3 now holds the x position of the enemy
            
          .loadEnemyPositionDone:
                                 
          .processXOffset:
          
            LDA placeholder1               ; load the metasprite pointer back from placeholder1
            CLC                            
            ADC #EN_BULLET_X_OFF           
            TAX                            
            LDA MEMORY_ENEMIES, x          ; load the bullet x offset
            CLC                            
            ADC placeholder3               ; add it to placeholder3
            STA placeholder3               ; store the new position back to placeholder3
            BCC .processXOffsetDone
            JMP .shootingUpdateDone        ; bullet would spawn off-screen                    
          
          .processXOffsetDone:
          
          .processYOffset:
          
            INX                            ; X now points to the bullet y offset
            LDA MEMORY_ENEMIES, x          ; load the bullet y offset
            CLC                            
            ADC placeholder4               ; add it to placeholder4
            CMP #SCREEN_BOTTOM             
            STA placeholder4               ; store the new position back to placeholder4
            BCC .processYOffsetDone
            JMP .shootingUpdateDone        ; bullet would spawn off-screen            
                          
          .processYOffsetDone:
          
        .loadPositionDone:               
                                         
        .loadDirection:                  
                                         
          LDA placeholder1               ; load the metasprite pointer back from placeholder1
          CLC                            
          ADC #EN_BULLET_HIGH            
          TAX                            
          LDA MEMORY_ENEMIES, x          
          STA enBulletHigh               ; load the high byte of bullet pointer
          INX                            
          LDA MEMORY_ENEMIES, x          
          STA enBulletLow                ; load the high byte of bullet pointer
                        
          LDY #EN_BULLET_TYPE
          LDA [enBulletLow], y           ; load the bullet type
          
          CMP #EN_BULLET_TARGETED
          BEQ .targeted
          
          .fixed:                        ; fixed bullets
          
            LDY #EN_BULLET_SPEED
            LDA [enBulletLow], y
            STA placeholder5             ; store bullet x speed in placeholder5
            INY
            LDA [enBulletLow], y
            STA placeholder6             ; store bullet y speed in placeholder6            
            JMP .loadDirectionDone
          
          .targeted:                     ; targeted bullets
          
            LDA #$00
            STA placeholder7             ; placeholders 7 and 8 will tell if x and y speed have to be negated
            STA placeholder8             ; for now set them to 0
          
            .getDeltaX:
          
              LDA shipXCenter
              CMP placeholder3
              BCS .bulletGoingRight      ; figure out whether the bullet is supposed to go left or right
              
              .bulletGoingLeft:          ; bullet will go left - x speed should be negative (shipX < bulletX)
                
                INC placeholder7         ; remember to negate the value later
                LDA placeholder3
                SEC
                SBC shipXCenter
                STA placeholder5         ; store delta X in placeholder 5
                JMP .getDeltaXDone
              
              .bulletGoingRight:         ; bullet will go right - x speed should be positive (shipX >= bulletX)
              
                LDA shipXCenter
                SEC
                SBC placeholder3
                STA placeholder5         ; store delta X in placeholder 5
            
            .getDeltaXDone:
            
            .getDeltaY:

              LDA shipYCenter
              CMP placeholder4
              BCS .bulletGoingDown       ; figure out whether the bullet is supposed to go up or down
              
              .bulletGoingUp:            ; bullet will go up - y speed should be negative  (shipY < bulletY)
              
                INC placeholder8         ; remember to negate the value later
                LDA placeholder4
                SEC
                SBC shipYCenter
                STA placeholder6         ; store delta Y in placeholder 6
                JMP .getDeltaYDone
            
              .bulletGoingDown:          ; bullet will go dowb - y speed should be positive (shipY >= bulletY)
              
                LDA shipYCenter
                SEC
                SBC placeholder4
                STA placeholder6         ; store delta Y in placeholder 6
              
            .getDeltaYDone:
            
            .getSpeed:
            
              LDY #EN_BULLET_SPEED
              LDA [enBulletLow], y
              STA placeholder9             ; store bullet speed in placeholder9
              
              ; placeholder5 = delta x
              ; placeholder6 = delta y
              ; placeholder7 = whether to negate speed x
              ; placeholder8 = whether to negate speed y
              ; placeholder9 = desired speed
              ;
              ; this is the algorithm to use:
              ;
              ; while (delta x > desired speed or delta y > desired speed)
              ; {
              ;   LSR delta x
              ;   LSR delta y
              ; }
              
              .getSpeedLoop:
              
                .checkDX:
                  LDA placeholder5       ; compare delta x and desired speed
                  CMP placeholder9
                  BEQ .checkDY           ; equal is OK
                  BCC .checkDY           ; smaller is OK
                  JMP .shift             ; delta x > desired speed
                
                .checkDY:
                  LDA placeholder6       ; compare delta y and desired speed
                  CMP placeholder9
                  BEQ .getSpeedLoopDone  ; equal is OK
                  BCC .getSpeedLoopDone  ; smaller is OK
                  JMP .shift             ; delta y > desired speed
                
                .shift:
                  LSR placeholder5
                  LSR placeholder6
                  JMP .getSpeedLoop
                  
              .getSpeedLoopDone:  
              
              .negateX:
              
                LDA placeholder7         ; check if x speed has to be negated
                BEQ .negateXDone
                LDA #$00
                SEC
                SBC placeholder5
                STA placeholder5         ; negate x speed
              
              .negateXDone:
              
              .negateY:
              
                LDA placeholder8         ; check if y speed has to be negated
                BEQ .negateYDone
                LDA #$00
                SEC
                SBC placeholder6
                STA placeholder6         ; negate x speed
                
              .negateYDone:              
            
            .getSpeedDone:
                                  
        .loadDirectionDone:              
                                  
        .fireBullet:
        
          ; if we got here, this is the state of the memory:
          ; - placeholder1: enemy metasprite index
          ; - placeholder2: bullet slot index
          ; - placeholder3: bullet initial x
          ; - placeholder4: bullet initial y
          ; - placeholder5: bullet x speed
          ; - placeholder6: bullet y speed

          .drawBullet:
        
            LDX placeholder2
            LDA placeholder4
            STA SPRITES_EN_BULLETS, x     ; set the y position of the bullet
                                         
            INX                          
            LDY #EN_BULLET_TILE             
            LDA [enBulletLow], y
            STA SPRITES_EN_BULLETS, x     ; set the tile of the bullet
                                         
            INX                          
            LDY #EN_BULLET_ATT              
            LDA [enBulletLow], y
            STA SPRITES_EN_BULLETS, x     ; set the atts. of the bullet
                                         
            INX
            LDA placeholder3
            STA SPRITES_EN_BULLETS, x     ; set the X position of the bullet
                                         
          .drawBulletDone:               
                                         
          .initBullet:                   
                                         
            LDX placeholder2
            LDY #EN_BULLET_DAMAGE           
            LDA [enBulletLow], y           
            STA MEMORY_EN_BULLETS, x      ; copy the bullet damage
                                         
            INX                          
            LDY #EN_BULLET_SIZE             
            LDA [enBulletLow], y           
            STA MEMORY_EN_BULLETS, x      ; copy the bullet size
                                         
            INX                          
            LDA placeholder5
            STA MEMORY_EN_BULLETS, x      ; set the bullet x speed
                                        
            INX                          
            LDA placeholder6
            STA MEMORY_EN_BULLETS, x      ; set the bullet y speed
            
          .initBulletDone:
          
        .fireBulletDone:
                                  
      .shootingUpdateDone:               
                                         
    .updateEnemyDone:                    
                                         
    .nextSlot:                           
      LDA placeholder1                   ; load the metasprite pointer back from placeholder1
      CLC                                
      ADC #$10                           
      TAX                                ; X += 16
      CPX #ENEMIES_SIZE
      BEQ UpdateEnemiesDone
      JMP .slotLoop      
      
UpdateEnemiesDone:
  RTS
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                                  ;;
;;   DeleteEnemy                                          ;;
;;                                                        ;;
;; Description:                                           ;;
;;   Deletes an enemy.                                    ;;
;;   X register should point to that enemy's  metasprite  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
DeleteEnemy:
  
  LDY #$00
  LDA #CLEAR_SPRITE
  
  .loop:
    STA SPRITES_ENEMIES, x
    INX
    INY
    CPY #$10
    BNE .loop
  
  RTS
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                                               ;;
;;   LoadEnemiesScreenPointer                                          ;;
;;                                                                     ;;
;; Description:                                                        ;;
;;   Loads current "enemies on screen" ptr based on the screen number  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadEnemiesScreenPointer:

  LDA screenNumber         ; load current screen number
  ASL A                    ; x2 because there's 2 bytes per screen in the lookup table
  TAY                      ; move it to Y
  
  LDA [enLevelLow], y      ; load the high byte of the screen data
  STA enScreenHigh         ; store it in the pointer
  INY
  LDA [enLevelLow], y      ; load the low byte of the screen data
  STA enScreenLow          ; store it in the pointer
  
  RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                               ;;
;;   LoadBulletPointer                                 ;;
;;                                                     ;;
;; Description:                                        ;;
;;   Loads current weapon ptr based on the variable    ;;
;;   Must be called whenever currentWeapon is updated  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
LoadBulletPointer:

  LDA currentWeapon           ; load the current weapon
  ASL A                       ; x2 because we're loading pointers
  TAX
  LDA bullets, x              ; load the high byte
  STA bulletHigh              ; store it in the right place
  INX
  LDA bullets, x              ; load the low byte
  STA bulletLow               ; store it in the right place
  RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                ;;
;;   CheckCollisions                    ;;
;;                                      ;;
;; Description:                         ;;
;;   Check for all kinds of collisions  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
; Note - for collision checking in it's current form to have any sense,
; hitboxes cannot move fast enough for them to be able to miss each other.
  
CheckCollisions:
  JSR CheckCollisionsEnemies
  
  LDA shipHP
  CMP #$00
  BEQ CheckCollisionsDone     ; no need to check ship's collisions if HP == 0
  JSR CheckCollisionsShip
  
CheckCollisionsDone:
  RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                  ;;
;;   CheckCollisionsEnemies               ;;
;;                                        ;;
;; Description:                           ;;
;;   Check for collisions between enemies ;;
;;   and the ship and ship bullets.       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
CheckCollisionsEnemies:

  LDX #$00
  
  .slotLoop:
    STX placeholder1                    ; store the offset in placeholder1
    LDA SPRITES_ENEMIES, x    
    CMP #CLEAR_SPRITE                   ; check if the slot is filled
    BCC .checkEnemy                     ; slot is not filled
    JMP .nextSlot     

    .checkEnemy:
    
      LDA placeholder1                  ; load the enemy offset
      CLC
      ADC #EN_CURRENT_HP
      TAX
      LDA MEMORY_ENEMIES, x             ; load current HP
      BNE .loadPosition                 ; hp > 0 means enemy still alive
      JMP .nextSlot                     ; enemy is an explosion, ignore      
    
      .loadPosition:
      
        LDX placeholder1                ; load the enemy offset
        LDA SPRITES_ENEMIES, x          ; load y position of the enemy
        STA placeholder3                ; store it in placeholder3
        INX
        INX
        INX
        LDA SPRITES_ENEMIES, x          ; load x position of the enemy
        STA placeholder2                ; store it in placeholder2
      
      .loadPositionDone:
      
      .loadHitbox:
      
        LDX placeholder1                ; load the metasprite offset back from X        
        
        LDA MEMORY_ENEMIES, x           ; hitbox x offset
        CLC
        ADC placeholder2                ; add the offset to the x position of the enemy
        BCS .nextSlot                   ; hitbox is off-screen
        STA ax1                         ; store the shifted x position in ax1
        
        INX
        LDA MEMORY_ENEMIES, x           ; hitbox y offset
        CLC
        ADC placeholder3                ; add the offset to the y position of the enemy
        CMP #SCREEN_BOTTOM
        BCS .nextSlot                   ; hitbox is off-screen
        STA ay1                         ; store the shifted y position in ay1
        
        INX                             ; X points to hitbox width
        LDA MEMORY_ENEMIES, x           ; hitbox width
        CLC
        ADC ax1                         ; add the width to the x position of the hitbox)
        BCC .storeX2
        LDA #$FF                        ; hitbox ends off screen, cap at $FF
        .storeX2:
          STA ax2                       ; store the result in ax2
        
        INX                             ; X points to hitbox height
        LDA MEMORY_ENEMIES, x           ; hitbox height
        CLC
        ADC ay1                         ; add the height to the y position of the hitbox
        CMP #SCREEN_BOTTOM
        BCC .storeY2
        LDA #SCREEN_BOTTOM - $01        ; hitbox ends off screen, cap at $EF
        .storeY2:
          STA ay2                       ; store the result in ay2
      
      .loadHitboxDone:
      
      JSR CheckCollisionsOneEnemy       ; call the subroutine that checks one particular enemy
      
    .nextSlot:                          
      LDA placeholder1                  ; load the metasprite pointer back from placeholder1
      CLC                               
      ADC #$10                          
      TAX                               ; X += 16
      CPX #ENEMIES_SIZE
      BEQ CheckCollisionsBulletsEnemiesDone
      JMP .slotLoop      

CheckCollisionsBulletsEnemiesDone:
  RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                                                    ;;
;;   CheckCollisionsOneEnemy                                                ;;
;;                                                                          ;;
;; Description:                                                             ;;
;;   Check for collisions of one particular enemy                           ;;
;;   1st hitbox vars should be set (ax1, ax2, ay1, ay2)                     ;;
;;   Cannot modify placeholder1 - enemy's metasprite index is stored there  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
CheckCollisionsOneEnemy:

  .checkBullets:
  
    LDX #$00
  
    .checkBulletsLoop: 
      LDA SPRITES_BULLETS, x
      CMP #CLEAR_SPRITE                ; check if the slot is filled
      BNE .checkIfBulletExploding                 
      JMP .checkNext                   ; slot is not filleds
                                       
      .checkIfBulletExploding:         
                                       
        LDA MEMORY_BULLETS, x          
        BNE .checkBullet               ; damage > 0 means bullet is not exploding
        JMP .checkNext                 ; bullet is exploding. Ignore it.
                                       
      .checkBullet:                    ; slot is filled
                                       
        LDA SPRITES_BULLETS, x         ; load the y position of the bullet (in sprites data)
        STA by1                        ; store it in by1
                                       
        INX                            
        INX                            
        INX                            ; X now points to the x position of the bullet (in sprites data)
        LDA SPRITES_BULLETS, x         ; load the x position of the bullet
        STA bx1                        ; store it in bx1
                                       
        DEX                            
        DEX                            ; X now points to bullet's size (in memory data)
                                       
        LDA MEMORY_BULLETS, x          ; load the bullet size
        LSR A                          
        LSR A                          
        LSR A                          
        LSR A                          ; A now contains the bullet's width
        CLC                            
        ADC bx1                        ; add it to bx1
        BCC .setX2                     
        LDA #$FF                       ; hitbox ends off screen, cap at $FF
        .setX2:                        
          STA bx2                      ; set bx2
                                       
        LDA MEMORY_BULLETS, x          ; load the bullet size
        AND #%00001111                 ; A now contains the bullet's height
        CLC                            
        ADC by1                        ; add it to by1
        CMP #SCREEN_BOTTOM             
        BCC .setY2                     
        LDA #SCREEN_BOTTOM - $01       ; hitbox ends off screen, cap at $EF
        .setY2:                        
          STA by2                      ; set by2
                                       
        DEX                            ; decrement X so it points back to the bullet's index
                                       
        JSR CheckForCollision          
        LDA collision                  
        BEQ .checkNext                 
                                       
        .bulletEnemyCollision:         
                                       
          STX placeholder2             ; store bullet index in placeholder2
          LDA MEMORY_BULLETS, x        ; load the bullet damage
          STA placeholder3             ; store it in placeholder3
                                       
          .damageEnemy:                
                                       
            LDA placeholder1           ; load the enemy index
            CLC                        
            ADC #EN_CURRENT_HP         ; X now points to the current HP
            TAX                        
            LDA MEMORY_ENEMIES, x      ; load current HP
            SEC
            SBC placeholder3           ; subtract the damage
            BCS .setNewHP
            LDA #$00                   ; cap at 0
            .setNewHP:
              STA MEMORY_ENEMIES, x    ; set the new value
            
            LDA MEMORY_ENEMIES, x
            BNE .damageEnemyDone       ; check if enemy should be destroyed
                                       
            JSR DestroyEnemy           ; enemy should be destroyed
            LDX placeholder2           ; delete the bullet
            LDA #CLEAR_SPRITE          
            STA SPRITES_BULLETS, x     
            INX                        
            STA SPRITES_BULLETS, x     
            INX                        
            STA SPRITES_BULLETS, x     
            INX                        
            STA SPRITES_BULLETS, x     
            RTS                        ; stop processing
            
          .damageEnemyDone:
          
          .bulletExplosion:
            
            LDX placeholder2           ; load bullet's index
            LDA #$00
            STA MEMORY_BULLETS, x      ; set damage to 0 to mark bullet as exploding
            INX
            STA MEMORY_BULLETS, x      ; set size to 0 (this will work as a timer now)
            LDA #B_EXPLOSION_TILE
            STA SPRITES_BULLETS, x     ; set the tile (X is pointing to the right place)
            INX
            LDA #B_EXPLOSION_ATT
            STA SPRITES_BULLETS, x     ; set the attributes
            DEX
            DEX
            JMP .checkNext             ; check for further collisions
          
          .bulletExplosionDone:
          
      .checkNext:
        INX                         
        INX                         
        INX                         
        INX                            ; X += 4
        CPX #BULLETS_SIZE                
        BEQ .checkBulletsDone          ; we've checked everything
        JMP .checkBulletsLoop      
  
  .checkBulletsDone:
  
  .checkShip:

    LDA shipHP
    CMP #$00
    BEQ .checkShipDone                 ; don't check the collision if ship is exploding     
                                       
    JSR LoadShipOuterHitbox            
    JSR CheckForCollision              
    LDA collision                      
    BEQ .checkShipDone                 
                                       
    JSR LoadShipInnerHitbox1           
    JSR CheckForCollision              
    LDA collision                      
    BNE .enemyShipCollision            
                                       
    JSR LoadShipInnerHitbox2           
    JSR CheckForCollision              
    LDA collision                      
    BNE .enemyShipCollision            
                                       
    JMP .checkShipDone                 
                                       
    .enemyShipCollision:               
                                       
      .destroyEnemy:                   
                                       
        LDA placeholder1               ; load the enemy offset
        CLC                            
        ADC #EN_CURRENT_HP             
        TAX                            
        LDA #$00                       
        STA MEMORY_ENEMIES, x          ; set current HP to 0
        JSR DestroyEnemy               
                                       
      .destroyEnemyDone:               
                                       
      .damageShip:                     
                                       
        LDA placeholder1               ; load the enemy offset
        CLC                            
        ADC #EN_RAM_DAMAGE             
        TAX                            
        LDA MEMORY_ENEMIES, x          ; load the ram damage the enemy does
        STA placeholder2               ; store it in placeholder2
                                       
        JSR DamageShip                 ; damage the ship
      
      .damageShipDone:
      
  .checkShipDone:
  
CheckCollisionsOneEnemyDone:
  RTS
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                                  ;;
;;   CheckCollisionsShip                                  ;;
;;                                                        ;;
;; Description:                                           ;;
;;   Check for collisions between ship and enemy bullets  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
CheckCollisionsShip:

  LDX #$00

  .loop:
    STX placeholder1               ; store the bullet index in placeholder1
    CPX #EN_BULLETS_SIZE             
    BNE .checkIfExists
    RTS

    .checkIfExists:
      LDA SPRITES_EN_BULLETS, x        
      CMP #CLEAR_SPRITE            ; check if the bullet is created
      BNE .checkBullet                
      JMP .goToNext                ; not created, go to next
                                  
    .checkBullet:                                                  
      
      LDA MEMORY_EN_BULLETS, x     ; x is pointing at bullet damage. Damage == 0 means bullet is exploding, don't process it
      BNE .loadBulletHitbox
      JMP .goToNext
      
      .loadBulletHitbox:
      
        LDA SPRITES_EN_BULLETS, x  ; load the y position of the bullet
        STA ay1                    ; store it in ay1
        
        INX
        INX
        INX                        ; X now points to the x position of the bullet
        LDA SPRITES_EN_BULLETS, x  ; load the x position of the bullet
        STA ax1                    ; store it in ax1
        
        DEX
        DEX                        ; X now points to the size of the bullet in the 04xx memory
        LDA MEMORY_EN_BULLETS, x   ; load the size of the bullet
        LSR A
        LSR A
        LSR A
        LSR A                      ; A now contains the bullet's width
        CLC
        ADC ax1                    ; add it to ax1
        BCC .setX2                 
        LDA #$FF                   ; hitbox ends off screen, cap at $FF
        .setX2:                    
          STA ax2                  ; set ax2
        
        LDA MEMORY_EN_BULLETS, x   ; load the size of the bullet
        AND #%00001111             ; A now contains the bullet's height
        CLC                        
        ADC ay1                    ; add it to ay1
        CMP #SCREEN_BOTTOM         
        BCC .setY2                 
        LDA #SCREEN_BOTTOM - $01   ; hitbox ends off screen, cap at $EF
        .setY2:                    
          STA ay2                  ; set ay2
        
      .loadBulletHitboxDone:    
        
      .checkCollision:
      
        JSR LoadShipOuterHitbox
        JSR CheckForCollision
        LDA collision
        BEQ .checkCollisionDone
        
        JSR LoadShipInnerHitbox1
        JSR CheckForCollision
        LDA collision
        BNE .bulletShipCollision        
        
        JSR LoadShipInnerHitbox2
        JSR CheckForCollision
        LDA collision
        BNE .bulletShipCollision
      
        JMP .checkCollisionDone
      
        .bulletShipCollision:
          
          .damageShip:

            LDX placeholder1                  ; load the bullet offset
            LDA MEMORY_EN_BULLETS, x          ; load the damage the bullet does (X already points there)
            STA placeholder2                  ; store it in placeholder2
          
            JSR DamageShip                    ; damage the ship
          
          .damageShipDone:
          
          .processBullet:
          
            LDA shipHP                        ; check if the ship is exploding
            BEQ .deleteBullet                 ; if the ship is exploding, just delete the bullet
          
            .bulletExplosion:
            
              LDX placeholder1
              LDA #$00
              STA MEMORY_EN_BULLETS, x        ; set damage to 0 to mark bullet as exploding
              INX
              STA MEMORY_EN_BULLETS, x        ; set size to 0 (this will work as a timer now)
              LDA #B_EXPLOSION_TILE
              STA SPRITES_EN_BULLETS, x       ; set the tile (X is pointing to the right place)
              INX
              LDA #B_EXPLOSION_ATT
              STA SPRITES_EN_BULLETS, x       ; set the attributes
              
              JMP .processBulletDone
          
            .bulletExplosionDone:
          
            .deleteBullet:
          
              LDX placeholder1                ; delete the bullet
              LDA #CLEAR_SPRITE
              STA SPRITES_EN_BULLETS, x
              INX 
              STA SPRITES_EN_BULLETS, x
              INX
              STA SPRITES_EN_BULLETS, x
              INX
              STA SPRITES_EN_BULLETS, x
          
            .deleteBulletDone:
          
          .processBulletDone:
      
      .checkCollisionDone:
        
    .checkBulletDone:
      
    .goToNext:                     
      LDX placeholder1             ; load the bullet index from placeholder1
      INX                          
      INX                          
      INX                          
      INX                          ; X += 4
      JMP .loop

CheckCollisionsShipDone:
  RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                                ;;
;;   CheckForCollision                                  ;;
;;                                                      ;;
;; Description:                                         ;;
;;   Checks for collision. a and b hitbox must be set.  ;;
;;   Result is storen in "collision" var.               ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
CheckForCollision:

  LDA #$00
  STA collision              ; reset the collision flag
  
  LDA bx2
  CMP ax1
  BCC CheckForCollisionDone  ; ax1 > bx2, no collision
  
  LDA ax2
  CMP bx1
  BCC CheckForCollisionDone  ; ax2 < bx1, no collision
  
  LDA by2
  CMP ay1
  BCC CheckForCollisionDone  ; ay1 > by2, no collision
  
  LDA ay2
  CMP by1
  BCC CheckForCollisionDone  ; ay2 < by1, no collision
  
  INC collision              ; collision detected
  
CheckForCollisionDone:
  RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                            ;;
;;  DamageShip                                      ;;
;;                                                  ;;
;; Description:                                     ;;
;;   Damage the ship.                               ;;
;;   Damage to deal must be stored in placeholder2  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DamageShip:

  .damageShip:

    INC updateHPBar     ; we'll need to update the HP bar
                        
    LDA shipHP          ; load ship HP
    SEC                 
    SBC placeholder2    ; subtract the damage
    BCS .setHP          
    LDA #$00            ; cap at 0
    .setHP:             
      STA shipHP        ; store the new value
                        
    LDA shipHP          
    BNE DamageShipDone  
                        
  .damageShipDone:      
                        
  .destroyShip:         ; hp == 0, destroy the ship
  
    JSR ExplosionSound
    LDA #SH_EXPLOSION_TILE_0
    STA SHIP_TILE_OFF          
    LDA #SH_EXPLOSION_TILE_1
    STA SHIP_TILE_OFF + SHIP_OFF_1
    LDA #SH_EXPLOSION_TILE_2
    STA SHIP_TILE_OFF + SHIP_OFF_2
    LDA #SH_EXPLOSION_TILE_3
    STA SHIP_TILE_OFF + SHIP_OFF_3
    LDA #SH_EXPLOSION_TILE_4
    STA SHIP_TILE_OFF + SHIP_OFF_4
    LDA #SH_EXPLOSION_TILE_5
    STA SHIP_TILE_OFF + SHIP_OFF_5
    LDA #SH_EXPLOSION_TILE_6
    STA SHIP_TILE_OFF + SHIP_OFF_6
    LDA #SH_EXPLOSION_TILE_7
    STA SHIP_TILE_OFF + SHIP_OFF_7
    LDA #SH_EXPLOSION_TILE_8
    STA SHIP_TILE_OFF + SHIP_OFF_8
  
    LDA #SH_EXPLOSION_ATT
    STA SHIP_ATT_OFF              
    STA SHIP_ATT_OFF + SHIP_OFF_1
    STA SHIP_ATT_OFF + SHIP_OFF_2
    STA SHIP_ATT_OFF + SHIP_OFF_3
    STA SHIP_ATT_OFF + SHIP_OFF_4
    STA SHIP_ATT_OFF + SHIP_OFF_5
    STA SHIP_ATT_OFF + SHIP_OFF_6
    STA SHIP_ATT_OFF + SHIP_OFF_7
    STA SHIP_ATT_OFF + SHIP_OFF_8
  
    LDA #CLEAR_SPRITE
    STA SPRITE_EXHAUST + TILE_OFF
  
  .destroyShipDone:
  
DamageShipDone:
  RTS
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                    ;;
;;   DestroyEnemy                           ;;
;;                                          ;;
;; Description:                             ;;
;;   Turn an enemy into an explosion.       ;;
;;   Enemy's index must be in placeholder1  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
DestroyEnemy:
  
  .giveXP:
    LDA placeholder1        ; load the enemy index
    CLC                     
    ADC #EN_XP_YIELD        ; X now points to the XP yield
    TAX                     
    LDA MEMORY_ENEMIES, x   ; load the XP yield
    CLC                     
    ADC shipXP              ; add to current XP
    CMP #SHIP_XP_CAP        
    BCC .setXP              
    LDA #SHIP_XP_CAP        ; cap at max
    .setXP:                 
      STA shipXP            
      INC updateXPBar       
                            
  .giveXPDone:              
                            
  .turnToExplosion:         
                            
    LDX placeholder1        ; load the explosion tiles and attributes
    INX
    LDA #EN_EXPLOSION_TILE_0
    STA SPRITES_ENEMIES, x
    INX
    LDA #EN_EXPLOSION_ATT
    STA SPRITES_ENEMIES, x
    INX
    INX
    INX
    LDA #EN_EXPLOSION_TILE_1
    STA SPRITES_ENEMIES, x
    INX
    LDA #EN_EXPLOSION_ATT
    STA SPRITES_ENEMIES, x
    INX
    INX
    INX
    LDA #EN_EXPLOSION_TILE_2
    STA SPRITES_ENEMIES, x
    INX
    LDA #EN_EXPLOSION_ATT
    STA SPRITES_ENEMIES, x
    INX
    INX
    INX
    LDA #EN_EXPLOSION_TILE_3
    STA SPRITES_ENEMIES, x
    INX
    LDA #EN_EXPLOSION_ATT
    STA SPRITES_ENEMIES, x
    
  .turnToExplosionDone:
  
  .setTimer:
  
    LDA placeholder1
    CLC
    ADC #EN_SHOOT_TIMER
    TAX
    LDA #$00
    STA MEMORY_ENEMIES, x   ; reset the shooting timer to 0. It will be used to time the animation.   
  
  .setTimerDone:
  
DestroyEnemyDone:
  RTS
  
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                             ;;
;;   LoadShipOuterHitbox                             ;;
;;                                                   ;;
;; Description:                                      ;;
;;   Loads the outer hitbox of the ship to b hitbox  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
LoadShipOuterHitbox:
  LDA shipX1Outer
  STA bx1
  LDA shipX2Outer
  STA bx2
  LDA shipY1Outer
  STA by1
  LDA shipY2Outer
  STA by2
  RTS
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                                 ;;
;;   LoadShipInnerHitbox1                                ;;
;;                                                       ;;
;; Description:                                          ;;
;;   Loads the 1st inner hitbox of the ship to b hitbox  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
LoadShipInnerHitbox1:
  LDA shipX1Inner1
  STA bx1
  LDA shipX2Inner1
  STA bx2
  LDA shipY1Inner1
  STA by1
  LDA shipY2Inner1
  STA by2
  RTS
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                                 ;;
;;   LoadShipInnerHitbox2                                ;;
;;                                                       ;;
;; Description:                                          ;;
;;   Loads the 2nd inner hitbox of the ship to b hitbox  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
LoadShipInnerHitbox2:
  LDA shipX1Inner2
  STA bx1
  LDA shipX2Inner2
  STA bx2
  LDA shipY1Inner2
  STA by1
  LDA shipY2Inner2
  STA by2
  RTS
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                   ;;
;;   EndOfLevel                            ;;
;;                                         ;;
;; Description:                            ;;
;;   Process the player beating the level  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EndOfLevel:
  
  .loadMovement:
    LDA shipMovement      
    STA shipMovementOld
    LDA #SHIP_MOVEMENT_U
    STA shipMovement
  
  .loop:
    INC updateShipPosition
    INC updateExhaust   
    LDA shipY
    SEC
    SBC #$03
    BCC .shipOffScreen
    STA shipY
    JSR UpdateShipIfNeeded
    JSR UpdatePlayersBullets
    INC needDma
    JSR WaitForFrame
    JMP .loop
   
  .shipOffScreen:
    LDA #CLEAR_SPRITE                   
    STA SHIP_TILE_OFF                   
    STA SHIP_TILE_OFF + SHIP_OFF_1      
    STA SHIP_TILE_OFF + SHIP_OFF_2      
    STA SHIP_TILE_OFF + SHIP_OFF_3      
    STA SHIP_TILE_OFF + SHIP_OFF_4      
    STA SHIP_TILE_OFF + SHIP_OFF_5      
    STA SHIP_TILE_OFF + SHIP_OFF_6      
    STA SHIP_TILE_OFF + SHIP_OFF_7      
    STA SHIP_TILE_OFF + SHIP_OFF_8      
    STA SPRITE_EXHAUST
    INC needDma
    
  .sleep:
    LDX #$28
    JSR SleepForXFrames
    JSR FadeOut
    LDX #$28
    JSR SleepForXFrames
    
  .changeState:    
    INC currentLevel
    LDA currentLevel
    CMP #LEVELS_COUNT
    BEQ .theEnd
    JSR LoadStageScreen   
    RTS
   
  .theEnd:
    JSR LoadEndScreen
    RTS
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                   ;;
;;   LaserSound            ;;
;;                         ;;
;; Description:            ;;
;;   Play the laser sound  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
LaserSound:
  ;LDA #sfx_index_sfx_laser
  ;STA sound_param_byte_0
  ;LDA #soundeffect_one
  ;STA sound_param_byte_1
  ;JSR play_sfx
  RTS
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                       ;;
;;   ExplosionSound            ;;
;;                             ;;
;; Description:                ;;
;;   Play the explosion sound  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
ExplosionSound:
  ;LDA #sfx_index_sfx_explode
  ;STA sound_param_byte_0
  ;LDA #soundeffect_one
  ;STA sound_param_byte_1
  ;JSR play_sfx
  RTS