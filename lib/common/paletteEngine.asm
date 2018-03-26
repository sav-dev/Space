;;;;;;;;;;;;;;;;;;;;
;; PALETTE ENGINE ;;
;;;;;;;;;;;;;;;;;;;;

; Responsible for loading palettes

;;;;;;;;;;;;;;;;;
;; SUBROUTINES ;;
;;;;;;;;;;;;;;;;;
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                                    ;;
;;   LoadSpritesPalette                                     ;;
;;                                                          ;;
;; Description:                                             ;; 
;;   Buffers the sprites palette to be drawn in NMI         ;;
;;   Palette pointer must be set                            ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadSpritesPalette:
  LDA #$3F               
  STA placeholder1       ; store the high target byte in placeholder1
  LDA #$10               
  STA placeholder2       ; store the low target byte in placeholder1
  JSR LoadPalette        ; load the palette
  RTS
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                                    ;;
;;   LoadBgPalette                                          ;;
;;                                                          ;;
;; Description:                                             ;; 
;;   Buffers the bg. palette to be drawn in NMI             ;;
;;   Palette pointer must be set                            ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


LoadBgPalette:
  LDA #$3F               
  STA placeholder1       ; store the high target byte in placeholder1
  LDA #$00               
  STA placeholder2       ; store the low target byte in placeholder1
  JSR LoadPalette        ; load the palette
  RTS
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                                          ;;
;;   LoadPalette                                                  ;;
;;                                                                ;;
;; Description:                                                   ;; 
;;   Buffers a palette to be drawn in NMI                         ;;
;;   Palette pointer must be set                                  ;;
;;   placeholder1 should contain the high byte of target address  ;;
;;   placeholder2 should contain the high byte of target address  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


LoadPalette:

  LDY #$00                   ; load 0 to the Y register
  LDA #$10                   ; load $10 = 16 to the A register (we're drawing a palette == 16 bytes)
  STA [bufferLow], y         ; set that to byte 0 of the buffer segment
                             
  INY                        ; increment the Y register (now Y == 1)
  LDA placeholder1           ; load the high byte of the target address
  STA [bufferLow], y         ; set that to byte 1 of the buffer segment
                             
  INY                        ; increment the Y register (now Y == 2)
  LDA placeholder2           ; load the low byte of the target address
  STA [bufferLow], y         ; set that to byte 2 of the buffer segment   
                             
  INY                        
  INY                        ; increment the Y register twice (now Y == 4)
  
  STY placeholder1           ; store the value of the Y register in placeholder1
  LDY #$00                   ; start out at 0
                             
  .bufferedDrawLoop:          
    LDA [paletteLow], y      ; load a byte of the palette data
    STY placeholder2         ; store current source offset in placeholder2    
    
    LDY placeholder1         ; load the buffer offset from placeholder1
    STA [bufferLow], y       ; write to the buffer
    INY                      ; Y = Y + 1
    STY placeholder1         ; store the new buffer back to the placeholder1
    
    LDY placeholder2         ; load the source offset from placeholder2
    INY                      ; Y = Y + 1
    CPY #$10                 ; compare Y to hex $10, decimal 16 - copying 16 bytes
    BNE .bufferedDrawLoop    ; loop if there's more data to be copied
                             
  LDA placeholder1           ; load the buffer offset from placeholder1
  CLC                        
  ADC bufferLow              
  STA bufferLow              ; add it to bufferLow to point to the next buffer
  LDA bufferHigh             
  ADC #$00                   
  STA bufferHigh             ; add carry to bufferHigh
  
  RTS
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                                       ;;
;;   ClearPalettes                                             ;;
;;                                                             ;;
;; Description:                                                ;; 
;;   Clears both palettes. Cannot be called with NMI enabled.  ;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


ClearPalettes:

  LDA $2002  
  LDA #$3F
  STA $2006  
  LDA #$00
  STA $2006  
 
  LDX #$00
  LDA #$0F
  
  .loop:
    STA $2007
    INX      
    CPX #$20            
    BNE .loop
    
  RTS