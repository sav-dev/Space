;;;;;;;;;;;;;;;;;;;
;; STRING ENGINE ;;
;;;;;;;;;;;;;;;;;;;

; responsible for displaying strings

;;;;;;;;;;;;;;;;;
;; SUBROUTINES ;;
;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                              ;;
;;   PrintString                                      ;;
;;                                                    ;;
;; Description:                                       ;;
;;   Print a string based on the data in the pointer  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PrintString:

  LDY #$00                   ; Y = 0
  LDA [stringLow], y         ; load the string length
  STA [bufferLow], y         ; store it in the buffer
  TAX                        ; move the length to X
  
  INY                        ; Y = 1
  LDA [stringLow], y         ; load the high byte of the destination
  STA [bufferLow], y         ; store it in the buffer
                             
  INY                        ; Y = 2
  LDA [stringLow], y         ; load the low byte of the destination
  STA [bufferLow], y         ; store it in the buffer
                             
  INY                        ; Y = 3 (pointing at first byte of the string and at the reserved byte of the buffer)
  
  .bufferedDrawLoop:
    LDA [stringLow], y       ; load a byte of the draw data
    INY                      ; increment Y (there's 1 byte offset between the string data and the buffer)
    STA [bufferLow], y       ; store the byte of draw data in the buffer
    DEX                      ; decrement X (the loop counter)
    BNE .bufferedDrawLoop    ; loop if there's more data to be copied
                
  INY                
  TYA                        ; advance the buffer pointer
  CLC                        
  ADC bufferLow              
  STA bufferLow 
  LDA bufferHigh
  ADC #$00      
  STA bufferHigh

  RTS
