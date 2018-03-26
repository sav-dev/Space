;;;;;;;;;;;;;;;;;;
;; INES HEADERS ;;
;;;;;;;;;;;;;;;;;;

  .inesprg 2  ; 2x 16KB PRG code (banks 0-3)
  .ineschr 1  ; 1x  8KB CHR data (bank 4)
  .inesmap 0  ; mapper 0 = NROM, no bank swapping
  .inesmir 0  ; horizontal mirroring for vertical scrolling
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; POINTERS, VARS AND CONSTS ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  .include "inc\constants.asm"
  .include "inc\variables.asm"
  .include "inc\zeroPage.asm"
  
;;;;;;;;;;;
;; RESET ;;
;;;;;;;;;;;

  .bank 2
  .org $C000 
RESET:
  SEI               ; disable IRQs
  CLD               ; disable decimal mode
  LDX #$40          
  STX $4017         ; disable APU frame IRQ
  LDX #$FF          
  TXS               ; Set up stack
  INX               ; now X = 0
  STX $2000         ; disable NMI
  STX $2001         ; disable rendering
  STX $4010         ; disable DMC IRQs
                    
vblankwait1:        ; First wait for vblank to make sure PPU is ready
  BIT $2002         
  BPL vblankwait1   
                    
clrmem:             
  LDA #$00          
  STA $0000, x      
  STA $0100, x      
  STA $0300, x      
  STA $0400, x      
  STA $0500, x      
  STA $0600, x      
  STA $0700, x      
  INX
  BNE clrmem        
  JSR ClearSprites     
     
vblankwait2:        ; Second wait for vblank, PPU is ready after this
  BIT $2002              
  BPL vblankwait2

initSound:  
  ;LDA #SOUND_REGION_NTSC
  ;STA sound_param_byte_0
  ;LDA #LOW(song_list)
  ;STA sound_param_word_0
  ;LDA #HIGH(song_list)
  ;STA sound_param_word_0 + $01
  ;LDA #LOW(sfx_list)
  ;STA sound_param_word_1
  ;LDA #HIGH(sfx_list)
  ;STA sound_param_word_1 + $01
  ;JSR sound_initialize
  
;;;;;;;;;;;;;;;
;; GAME INIT ;;
;;;;;;;;;;;;;;;

  
  LDA #GAMESTATE_NONE    ; set gamestate to "none"
  STA gameState          
                         
  LDA #$01               ; init NMI variables
  STA needDma            ; need DMA is set to 1 so all sprites are cleared
  LDA #$00               
  STA needDraw           
  STA needPpuReg         
  LDA #BUFFER_LOW_BYTE   
  STA bufferLow          
  LDA #BUFFER_HIGH_BYTE  
  STA bufferHigh         

  JSR ClearPalettes
  
  LDA #%00000110         ; init PPU - disable sprites and background
  STA soft2001
  STA $2001
  LDA #%10010000         ; enable NMI
  STA soft2000           
  STA $2000              
  BIT $2002              
  LDA #$00               ; no horizontal scroll
  STA $2005              
  LDA scroll             ; no vertical scroll
  STA $2005
  
  JSR WaitForFrame       ; wait for one frame for everything to get loaded
  
;;;;;;;;;;;;;;;
;; GAME LOOP ;;
;;;;;;;;;;;;;;;

GameLoop:
  
  .readController:

    JSR ReadController     ; always read controller input first
    
  .readControllerDone:
  
  .checkGameState:
  
    LDA gameState
    CMP #GAMESTATE_TITLE
    BEQ .gameStateTitle
    CMP #GAMESTATE_STAGE
    BEQ .gameStateStage
    CMP #GAMESTATE_PLAYING
    BEQ .gameStatePlaying
    CMP #GAMESTATE_CONTINUE
    BEQ .gameStateContinue
    CMP #GAMESTATE_END
    BEQ .gameStateEnd
    CMP #GAMESTATE_PASSWORD
    BEQ .gameStatePassword
    JMP .gameStateNone     ; nothing was matched => game state is "none"
  
  .checkGameStateDone:
  
  .gameStateTitle:
  
    JSR TitleFrame         
    JMP GameLoopDone
  
  .gameStateTitleDone:
  
  .gameStateStage:
  
    JSR StageFrame         
    JMP GameLoopDone
  
  .gameStateStageDone:
  
  .gameStatePlaying:
  
    JSR GameFrame          
    JMP GameLoopDone
    
  .gameStatePlayingDone:

  .gameStateContinue:
  
    JSR ContinueFrame          
    JMP GameLoopDone
    
  .gameStateContinueDone:
  
  .gameStateEnd:
  
    JSR EndFrame          
    JMP GameLoopDone
    
  .gameStateEndDone:
  
  .gameStatePassword:
  
    JSR PasswordFrame      
    JMP GameLoopDone
    
  .gameStatePasswordDone:
  
  .gameStateNone:
  
    JSR LoadTitleScreen
    JMP GameLoopDone
  
  .gameStateNoneDone:
  
GameLoopDone:
  JSR WaitForFrame         ; always wait for a frame at the end of the loop iteration
  JMP GameLoop
  
;;;;;;;;;;;;;;;;;;;
;; NMI INTERRUPT ;;
;;;;;;;;;;;;;;;;;;;

NMI:
  PHA                      ; back up registers (important)
  TXA
  PHA
  TYA
  PHA

  LDA needDma
  BEQ DmaDone
    LDA #SPRITES_LOW_BYTE  ; do sprite DMA
    STA $2003              ; conditional via the 'needDma' flag
    LDA #SPRITES_HIGH_BYTE
    STA $4014
    DEC needDma
  DmaDone:

  LDA needDraw             ; do other PPU drawing (NT/Palette/whathaveyou)
  BEQ DrawDone             ;  conditional via the 'needDraw' flag
    BIT $2002              ; clear VBl flag, reset $2005/$2006 toggle
    JSR DoDrawing          ; draw the stuff from the drawing buffer
    DEC needDraw
  DrawDone:

  LDA needPpuReg
  BEQ PpuRegDone
    LDA soft2001           ; copy buffered $2000/$2001 (conditional via needPpuReg)
    STA $2001
    LDA soft2000
    STA $2000

    BIT $2002              ; set the scroll (conditional via needPpuReg)
    LDA #$00               ; no horizontal scroll
    STA $2005              
    LDA scroll             ; set vertical scroll
    STA $2005
    DEC needPpuReg
  PpuRegDone:
       
  ; todo: uncomment
  ;soundengine_update

  LDA #$00                 ; clear the sleeping flag so that WaitForFrame will exit
  STA sleeping

  PLA                      ; restore regs and exit
  TAY
  PLA
  TAX
  PLA
  RTI

  RTI
  
;;;;;;;;;;;;;;;;;
;; SUBROUTINES ;;
;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                          ;;
;;   WaitForFrame                                 ;;
;;                                                ;;
;; Description:                                   ;;
;;   Waits for NMI, returns as soon as it's done  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitForFrame
  INC sleeping
  .loop:
    LDA sleeping
    BNE .loop
  RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                                 ;;
;;   ClearSprites                                        ;;
;;                                                       ;;
;; Description:                                          ;;
;;   Clears all 64 sprites by setting all values to $FE  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClearSprites:
  LDA #CLEAR_SPRITE
  LDX #$FF
  
  .loop:
    STA $0200, x
    DEX
    BNE .loop
    
  RTS
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                  ;;
;;   SleepForXFrames      ;;
;;                        ;;
;; Description:           ;;
;;   Sleeps for X frames  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SleepForXFrames:
  .loop:
    JSR WaitForFrame
    DEX
    BNE .loop
    
  RTS
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                              ;;
;;   DoDrawing                                        ;;
;;                                                    ;;
;; Description:                                       ;; 
;;   Copies buffered draw data to the PPU.            ;;
;;   Input data has the following format:             ;;
;;     Byte 0  = length                               ;;
;;     Byte 1  = high byte of the PPU address         ;;
;;     Byte 2  = low byte of the PPU address          ;;
;;     Byte 3  = flags (currently not used)           ;;
;;     Byte 4+ = {length} bytes                       ;;
;;                                                    ;;
;;   Repeat until length == 0 is found.               ;;
;;   Data starts at BUFFER_HIGH_BYTE;BUFFER_LOW_BYTE  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DoDrawing:

  LDA #BUFFER_LOW_BYTE        ; load the address of the buffer
  STA drawPointerLow         
  LDA #BUFFER_HIGH_BYTE     
  STA drawPointerHigh        
                            
  .draw:                    
    
    LDA $2002                 ; read PPU status to reset the high/low latch    
    
    LDY #$00                  ; load 0 to the Y register
    LDA [drawPointerLow], y   ; load the length of the data
    BEQ DoDrawingDone         ; length is 0 which means that the drawing is done
    
    LDY #$01                  ; load 1 to the Y register
    LDA [drawPointerLow], y   ; load the high byte of the target address
    STA $2006                 ; write the high byte to PPU
    LDA #$00
    STA [drawPointerLow], y   ; reset the high byte to 0
    
    INY                       ; increment Y
    LDA [drawPointerLow], y   ; load the low byte of the target address
    STA $2006                 ; write the low byte to PPU
    LDA #$00
    STA [drawPointerLow], y   ; reset the low byte to 0
    
    LDY #$00                  ; load 0 to the Y register
    LDA [drawPointerLow], y   ; load the length of the data again
    TAX                       ; transfer the length to the X register
                              ; we're not resetting the data yet since we'll need it later
                              
    LDY #$04                  ; load 4 to the Y register (where data starts)
    
    .loop:
      
      LDA [drawPointerLow], y ; load a byte of the data
      STA $2007               ; write it to PPU
      LDA #$00
      STA [drawPointerLow], y ; reset the data byte to #$00
      INY                     ; increment Y
      DEX                     ; decrement X
      BNE .loop               ; if X != 0 jump to .copyLoop
      
    LDY #$00                  ; load 0 to the Y register
    LDA [drawPointerLow], y   ; load the length of the data again
    TAX                       ; transfer the length of the data to X
    LDA #$00
    STA [drawPointerLow], y   ; reset the length to 0
    TXA                       ; transfer the length of the data back to A
    
    CLC
    ADC drawPointerLow        ; add the length of previous data to drawPointerLo
    STA drawPointerLow
    LDA drawPointerHigh
    ADC #$00                  ; add carry to drawPointerHi
    STA drawPointerHigh
    
    LDA drawPointerLow
    CLC
    ADC #$04                  ; must add 4 to drawPointerLo to make sure it's pointing to next segment
    STA drawPointerLow
    LDA drawPointerHigh       ; add carry to drawPointerHi again
    ADC #$00
    STA drawPointerHigh
    
    JMP .draw                 ; jump back to draw
 
DoDrawingDone:

  LDA #BUFFER_LOW_BYTE        ; reset the buffer pointer to default values
  STA bufferLow
  LDA #BUFFER_HIGH_BYTE
  STA bufferHigh

  RTS
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                 ;;
;;   FadeOut             ;;
;;                       ;;
;; Description:          ;;
;;   Fades out to black  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

FadeOut:

  LDA #%01011110           ; intensify greens
  STA soft2001             
  INC needPpuReg           
  LDX #$04
  JSR SleepForXFrames
  
  LDA #%01111110           ; intensify greens and reds
  STA soft2001             
  INC needPpuReg           
  LDX #$04
  JSR SleepForXFrames

  LDA #%00000100           ; disable PPU
  STA soft2001
  INC needPpuReg
  LDX #$04
  JSR SleepForXFrames
  
  RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                              ;;
;;   ButtonSound                      ;;
;;                                    ;;
;; Description:                       ;;
;;   Play the universal button sound  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
ButtonSound:
  ;LDA #sfx_index_sfx_button
  ;STA sound_param_byte_0
  ;LDA #soundeffect_one
  ;STA sound_param_byte_1
  ;JSR play_sfx
  RTS
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; MODULES AND GAME DATA ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  .include "lib\common\backgroundEngine.asm"
  .include "lib\common\controllerEngine.asm"
  .include "lib\common\paletteEngine.asm"
  .include "lib\common\stringEngine.asm"
  
  .include "lib\states\continue.asm"
  .include "lib\states\end.asm"
  .include "lib\states\game.asm"
  .include "lib\states\password.asm"
  .include "lib\states\stage.asm"
  .include "lib\states\title.asm"
  
  .bank 3
  .org $E000
  
  .include "data\bullets.asm"
  .include "data\enemies.asm"
  .include "data\levels.asm"
  .include "data\lookupTables.asm"
  .include "data\strings.asm"
  
  .bank 0
  .org $8000
  
  ;.include "sound\ggsound\ggsound.asm"
  ;.include "sound\ggsound\songs.asm"
  
  .bank 1
  .org $A000
  
;;;;;;;;;;;;;
;; VECTORS ;;
;;;;;;;;;;;;;

  .bank 3
  .org $FFFA  ; vectors starts here
  .dw NMI     ; when an NMI happens (once per frame if enabled) the processor will jump to the label NMI:
  .dw RESET   ; when the processor first turns on or is reset, it will jump to the label RESET:
  .dw 0       ; external interrupt IRQ is not used

;;;;;;;;;
;; CHR ;;
;;;;;;;;;  
  
  .bank 4
  .org $0000
  .incbin "SpaceGraphics\chr\graphics1.chr"