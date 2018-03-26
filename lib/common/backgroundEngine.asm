;;;;;;;;;;;;;;;;;;;;;;;
;; BACKGROUND ENGINE ;;
;;;;;;;;;;;;;;;;;;;;;;;

; Responsible for drawing the background, scrolling, and so on.

;;;;;;;;;;;;;;;;;
;; SUBROUTINES ;;
;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                                           ;;
;;   LoadBackground                                                ;;
;;                                                                 ;;
;; Description:                                                    ;;
;;   Loads a static background to nt 0 based on the input pointer  ;;
;;   Writes directly to PPU.                                       ;;
;;   Must be called with PPU disabled                              ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadBackground:
   
  LDA #$00
  STA placeholder1          ; placeholders 1 and 2 will serve as counters
  STA placeholder2          
                            
  LDA $2002                 ; read PPU status to reset the high/low latch
  LDA #$20                  ; we want to load to nametable 0
  STA $2006                 ; write the high byte of the address (#$20)
  LDA #$00                            
  STA $2006                 ; write the low byte of the address (always #$00)
        

  LDY #$00
        
  .loop:
    LDA [ntLow], y          ; load a byte of the nametable
    STA $2007               ; write the byte
                            
    LDA ntLow               ; increment the pointer
    CLC                     
    ADC #$01                
    STA ntLow               
    LDA ntHigh              
    ADC #$00                
    STA ntHigh              
                            
    LDA placeholder1        
    CLC                     
    ADC #$01                
    STA placeholder1        
    LDA placeholder2        
    ADC #$00                
    STA placeholder2                        
    CMP #$04                
    BNE .loop
    
  LDA #$00
  STA scroll                ; no scroll with static backgrounds
   
  RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                               ;;
;;   ClearBackground                   ;;
;;                                     ;;
;; Description:                        ;;
;;   Loads a clear background to nt 0  ;;
;;   Atts. are set to clearAtts        ;;
;;   Writes directly to PPU.           ;;
;;   Must be called with PPU disabled  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClearBackground:
   
  LDA #$00
  STA placeholder1          ; placeholders 1 and 2 will serve as counters
  STA placeholder2          

  LDA #CLEAR_TILE
  STA placeholder3          ; placeholder 3 contains the value to set  
                  
  LDA $2002                 ; read PPU status to reset the high/low latch
  LDA #$20                  ; we want to load to nametable 0
  STA $2006                 ; write the high byte of the address (#$20)
  LDA #$00                            
  STA $2006                 ; write the low byte of the address (always #$00)
                            
  .loop:
    LDA placeholder3
    STA $2007               ; write the value
                            
    LDA placeholder1        
    CLC                     
    ADC #$01                
    STA placeholder1        
    LDA placeholder2        
    ADC #$00                
    STA placeholder2

    LDA placeholder1
    CMP #$C0                ; 960 = 3 x 256 + 192, 192 = $C0
    BNE .checkIfExit
    
    LDA placeholder2
    CMP #$03                ; 960 = 3 x 256 + 192, 192 = $C0
    BNE .checkIfExit
    
    LDA clearAtts        
    STA placeholder3        ; time to load atts
    JMP .loop
    
    .checkIfExit:
      LDA placeholder2
      CMP #$04
      BNE .loop
  
  LDA #$00
  STA scroll                ; no scroll with static backgrounds
  
  RTS
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                                       ;;
;;   IncrementScroll                                           ;;
;;                                                             ;;
;; Description:                                                ;;
;;   Increments the scroll (actually, decrements it), then     ;;
;;   then checks if new rows must be drawn - if yes it draws   ;;
;;   new data to the buffer.                                   ;;
;;                                                             ;;
;; Notes:                                                      ;;
;;   This routine increments the needPpuReg and needDraw,      ;;
;;   meaning that no bulk drawing and/or buffering is allowed  ;;
;;   until next WaitForFrame is called                         ;;    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IncrementScroll:

  LDA #$00
  STA newRow                     ; set newRow to 0 for now

  ScrollChange:
    
    LDA screenNumber
    CMP numberOfScreens          ; if we're on the last screen, don't scroll
    BEQ BackgroundCheckDone
    
    INC scrollInc                ; increase the scrollInc counter
    LDA scrollInc
    CMP scrollSpeed              ; compare to scroll speed
    BCC BackgroundCheckDone      ; if scrollInc < scrollSpeed, we're done

    LDA #$00
    STA scrollInc                ; reset scrollInc to 0    
    DEC scroll                   ; subract one from scroll       
    BNE .checkForScrollWrap
    JSR MoveToNextScreen         ; if we got here it means that scroll == 0 - inc the screenNumber
    JMP ScrollChangeDone
                                 
    .checkForScrollWrap:                         
      LDA scroll                   
      CMP #$FF                   ; scroll == 255 means it just wrapped from 0 to 255.
      BNE ScrollChangeDone       ; if that's the case set the scroll to 239 and update nametables
                                 
      LDA #$EF                   ; $EF = 239
      STA scroll                 
                                 
      LDA nametable              ; swap the nametable from 0 to 2 and vice versa
      EOR #$02                   
      STA nametable                  
        
      .ppuSetup:
        LDA #%10010000           ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
        ORA nametable            ; select correct nametable for bit 0 (0 or 2)
        STA soft2000             
        LDA #%00011110           ; enable sprites, enable background, no clipping on left side
        STA soft2001                 
                                 
  ScrollChangeDone:              
                                 
    INC needPpuReg               ; PPU will always be needed if we did the scroll.
                                 ; No bulk drawing is allowed after this flag is set
                                 ; until WaitForFrame is called
                                 
    LDA screenNumber             ; if we've just shown the last screen, don't draw any new rows
    CMP numberOfScreens           
    BNE BackgroundCheck
    INC endOfLevel               ; set the end of level flag
    RTS
  
  BackgroundCheck:
  
    NewRowCheck:
  
      LDA scroll                 
      AND #%00000111             ; check if scroll is a multiple of 8
      BNE BackgroundCheckDone    ; done if lower bits != 0. It also means we don't have to check for attributes
      JSR DrawNewRow             ; time for new row
      INC newRow                 ; set the newRow flag
      
    NewRowCheckDone:
      
    NewAttributesCheck:
    
      LDA scroll                 
      AND #%00011111             ; check if scroll is a multiple of 32
      BNE NewAttributesCheckDone ; done if lower bits != 0;      
      JSR DrawNewAttributes      ; time for new attributes
      
    NewAttributesCheckDone:
    
    INC needDraw                 ; if we got here it means a draw is needed
                                 ; nothing can be buffered after this is incremented
                                 ; until WaitForFrame is called 
    
  BackgroundCheckDone:

  RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                             ;;
;;   MoveToNextScreen                                ;;
;;                                                   ;;
;; Description:                                      ;;
;;   Increments the screen number and does anything  ;;
;;   that needs to be done when that happens.        ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
MoveToNextScreen:
  INC screenNumber              ; increment the screen number
  JSR LoadEnemiesScreenPointer  ; this needs to be called every time screen number is updated
  RTS
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                            ;;
;;   LoadLevelBackground                            ;;
;;                                                  ;;
;; Description:                                     ;;
;;   Initializes the background - loads nametable   ;;
;;   and attributes, and initializes variables.     ;;
;;   Writes directly to PPU.                        ;;
;;   Must be called with PPU disabled               ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadLevelBackground:

  LDY #$00                     ; load 0 to the Y register
  LDA [bgLevelLow], y          ; load the high byte of the bg. palette pointer
  STA paletteHigh              ; store it in the pointer
  INY                          ; Y now 1
  LDA [bgLevelLow], y          ; load the low byte of the bg. palette pointer
  STA paletteLow               ; store it in the pointer
  JSR LoadBgPalette            ; load the palette

  LDY #$02                     ; load 2 to the Y register
  LDA [bgLevelLow], y          ; load the high byte of the sprites palette pointer
  STA paletteHigh              ; store it in the pointer
  INY                          ; Y now 3
  LDA [bgLevelLow], y          ; load the low byte of the sprites palette pointer
  STA paletteLow               ; store it in the pointer
  JSR LoadSpritesPalette       ; load the palette
  
  LDY #$04                     ; load 4 to the Y register
  LDA [bgLevelLow], y          ; load the scroll speed
  STA scrollSpeed              ; store it in the variable
  
  INY                          ; Y now 5
  LDA [bgLevelLow], y          ; load the number of screens
  STA numberOfScreens          ; store it in the variable
  
  LDA #$01
  STA bulkDraw                 ; set the bulkDraw flag to 1
  
  InitializeNametables:

    ; Load entire nametable 0. 
    
    LDA #$00
    STA screenNumber           ; set screenNumber to 0
    
    ; Start with loading the bottom most row - set nametable to 2 and scroll to 0.

    LDA #$00               
    STA scroll                 ; set scroll to 0
    LDA #$02                   
    STA nametable              ; set nametable to 2
    JSR DrawNewRow             ; draw the row

    ; Now load the rest of the rows.
    ; Set the nametable to 0 and scroll to 232.
    ; Then draw 29 rows decreasing scroll by 8 every time.

    LDA #$00
    STA nametable              ; set nametable to 0
    LDA #$E8                   
    STA scroll                 ; set scroll to 232
                               
    .loop:             
      JSR DrawNewRow           ; draw the row
      LDA scroll               ; decrease scroll by 8
      SEC                      
      SBC #$08                 
      STA scroll               
      BNE .loop                ; scroll == 0 means we've drawn all 29 rows
  
    ; Finally, we want to draw the last row in nametable 2.
    ; Scroll and nametable must both be 0 - that's all set.
    ; Just increment the screenNumber.
  
    INC screenNumber
    JSR DrawNewRow
  
  InitializeNametablesDone:
  
  InitializeAttributes:
    
    ; Load attributes for entire nametable 0.
    
    LDA #$00
    STA screenNumber           ; set screenNumber to 0
    
    ; Start with loading the bottom most row - set nametable to 2 and scroll to 0.
    
    LDA #$00               
    STA scroll                 ; set scroll to 0
    LDA #$02                   
    STA nametable              ; set nametable to 2
    JSR DrawNewAttributes      ; draw attributes
  
    ; Now load the rest of the rows.
    ; Set the nametable to 0 and scroll to 224.
    ; Then draw 7 rows decreasing scroll by 32 every time.
  
    LDA #$00
    STA nametable              ; set nametable to 0
    LDA #$E0                   
    STA scroll                 ; set scroll to 224
  
    .loop:
      JSR DrawNewAttributes    ; draw attributes
      LDA scroll               ; decrease scroll by 32
      SEC                      
      SBC #$20                 
      STA scroll               
      BNE .loop                ; scroll == 0 means we've drawn all 8 rows
  
    ; Finally, we want to draw the last row in nametable 2.
    ; Scroll and nametable must both be 0 - that's all set.
    ; Just increment the screenNumber.
  
    INC screenNumber
    JSR DrawNewAttributes
  
  InitializeAttributesDone:
  
  LDA #$00
  STA bulkDraw                 ; reset the bulkDraw flag to 0
  STA scroll                   ; set scroll to 0
  STA scrollInc                ; set scrollInc to 0           
  STA endOfLevel               ; set endOfLevel to 0
  STA nametable                ; show nametable 0
  
  LDA #$01
  STA newRow                   ; scroll % 8 == 0 => newRow = 1
  
  RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                            ;;
;;   DrawNewRow                                     ;;
;;                                                  ;;
;; Description:                                     ;; 
;;   Draws in PPU the row that's about to be shown  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DrawNewRow:

  ; First calculate where in PPU to draw the row using the following formula:
  ;
  ; |---------|------------|------------------|---------------------|---------------------------|
  ; | Bg. Row |   Offset   | Draw when scroll |      Draw in        |           Formula         |
  ; |---------|------------|------------------|---------------------|---------------------------|
  ; |    0    |  $00 = 0   |     $08 = 08     |  current nametable  | Offset = (scroll - 8) x 4 |
  ; |    1    |  $20 = 32  |     $10 = 16     |  current nametable  | Offset = (scroll - 8) x 4 |
  ; |    2    |  $40 = 64  |     $18 = 24     |  current nametable  | Offset = (scroll - 8) x 4 |
  ; |    3    |  $60 = 96  |     $20 = 32     |  current nametable  | Offset = (scroll - 8) x 4 |
  ; |    4    |  $80 = 128 |     $28 = 40     |  current nametable  | Offset = (scroll - 8) x 4 |
  ; |    5    |  $A0 = 160 |     $30 = 48     |  current nametable  | Offset = (scroll - 8) x 4 |
  ; |   ...   |    ...     |       ...        |        ...          |            ...            |
  ; |   28    | $360 = 864 |     $E0 = 224    |  current nametable  | Offset = (scroll - 8) x 4 |
  ; |   29    | $380 = 896 |     $E8 = 232    |  current nametable  | Offset = (scroll - 8) x 4 |
  ; |   30    | $3A0 = 928 |     $00 = 00     | the other nametable |        special case       |
  ; |---------|------------|------------------|---------------------|---------------------------|
  
  DrawNewRowPPU:
  
    LDA scroll
    BEQ .scroll0                 ; check if it's the special case of scroll == 0
                                 
    .scrollNot0:                 
      LDA nametable              ; load nametable number
      ASL A                      ; shift up, A = $04 (for nametable == 2) or $00 (for nametable == 0)
      ASL A                      ; shift up, A = $08 (for nametable == 2) or $00 (for nametable == 0)
      CLC                        
      ADC #$20                   ; add $20, now A = $20 (for nametable == 0) or $28 (for nametable == 2)
      STA bgTargetRowHigh        
                                 
      LDA scroll                 
      SEC                        
      SBC #$08                   ; subract 8 from scroll
      CLC                        
      ASL A                      ; shift up (equivalent to x2)
      STA bgTargetRowLow         
      BCC .carryClear            ; if carry was not set, skip the next section
                                 
      .carrySet:                 
        CLC                      
        LDA bgTargetRowHigh      
        ADC #$02                 
        STA bgTargetRowHigh      ; add 2 to bgTargetRowHigh (highest bit in bgTargetRowLow shifted twice)
                                 
      .carryClear:               
        LDA bgTargetRowLow       
        CLC                      
        ASL A                    ; shift up (equivalent x2, effectively we've done x4)
        STA bgTargetRowLow       
        BCC DrawNewRowPPUDone    ; if carry was not set, skip the next section
        CLC                      
        LDA bgTargetRowHigh      
        ADC #$01                 
        STA bgTargetRowHigh      ; add 1 to bgTargetRowHigh (2nd to highest bit in bgTargetRowLow shifted twice)
        JMP DrawNewRowPPUDone    
                                 
    .scroll0:                    
      LDA nametable              ; load nametable number
      EOR #$02                   ; invert second bit, A = $00 (for nametable == 2) or $02 (for nametable == 0)
      ASL A                      ; shift up, A = $00 (for nametable == 2) or $04 (for nametable == 0)
      ASL A                      ; shift up, A = $00 (for nametable == 2) or $08 (for nametable == 0)
      CLC                             
      ADC #$23                   ; add $23, now A = $23 (for nametable == 2) or $2B (for nametable == 0)
      STA bgTargetRowHigh        
      LDA #$A0                   
      STA bgTargetRowLow         ; now address is $23A0 (for nametable == 2) or $2BA0 (for nametable == 0)
                                 
  DrawNewRowPPUDone:             ; PPU address is calculated
  
  ; Calculate the source address of the row.
  ; First figure out which nametable should we load from (based on screen number).
  ; Then get the pointer. Finally, calculate the offset using the following formula:
  ;
  ; |--------|------------|------------|----------------------------------|
  ; | Scroll | Source Row |   Offset   |              Formula             |
  ; |--------|------------|------------|----------------------------------|
  ; |    0   |     29     | $3A0 = 928 |          Offset = 29 x 32        |
  ; |    8   |      0     |  $00 = 0   | Offset = ((scroll - 8) / 8) x 32 |
  ; |   16   |      1     |  $20 = 32  | Offset = ((scroll - 8) / 8) x 32 |
  ; |   24   |      2     |  $40 = 64  | Offset = ((scroll - 8) / 8) x 32 |
  ; |   32   |      3     |  $60 = 96  | Offset = ((scroll - 8) / 8) x 32 |
  ; |  ...   |    ...     |    ...     |                ...               |
  ; |  216   |     26     | $340 = 832 | Offset = ((scroll - 8) / 8) x 32 |
  ; |  224   |     27     | $360 = 864 | Offset = ((scroll - 8) / 8) x 32 |
  ; |  232   |     28     | $380 = 896 | Offset = ((scroll - 8) / 8) x 32 |
  ; |--------|------------|------------|----------------------------------|
  
  DrawNewRowSource:
  
    LDA screenNumber             ; load the screenNumber
    ASL A                        ; shift left. A now contains "screen number * 2"
    CLC
    ADC #NAMETABLE_OFFSET        ; add the nametable offset set A to the nametable pointer
    TAY                          ; move A to Y
    
    LDA [bgLevelLow], y          ; load the high byte of the nametable's address
    STA bgSourceRowHigh          
    INY                          ; Y = Y + 1
    LDA [bgLevelLow], y          ; load the low byte of the nametable's address
    STA bgSourceRowLow           
    
    LDA scroll                   ; load the scroll
    BEQ .scroll0
    
    .scrollNot0:
      LDA scroll
      SEC
      SBC #$08                   ; A = scroll - 8
      BEQ DrawNewRowSourceDone   ; scroll = 8 => no offset
      LSR A
      LSR A
      LSR A                      ; A = (scroll - 8) / 8
      TAX                        ; X = (scroll - 8) / 8
      JMP .loop
    
    .scroll0:
      LDX #$1D                   ; X = 29
    
    .loop:                       
      LDA bgSourceRowLow         ; add 32 to bgSourceRowLow
      CLC                        
      ADC #$20                   
      STA bgSourceRowLow         
      LDA bgSourceRowHigh        ; add carry to bgSourceRowHigh
      ADC #$00
      STA bgSourceRowHigh
      DEX                        ; X = X - 1
      BNE .loop                  ; if X > 0 there is still data to copy
      
  DrawNewRowSourceDone:
    
  ; Now just copy the 32 bytes of the row using calculated addresses.
    
  DrawRow:
  
    LDA bulkDraw
    BNE .bulkDraw
  
    .bufferedDraw:               ; we're doing a buffered draw, buffer the data in RAM
                                 
      LDY #$00                   ; load 0 to the Y register
      LDA #$20                   ; load $20 = 32 to the A register (we're drawing a row == 32 bytes)
      STA [bufferLow], y         ; set that to byte 0 of the buffer segment
                                 
      INY                        ; increment the Y register (now Y == 1)
      LDA bgTargetRowHigh        ; load the high byte of the target row
      STA [bufferLow], y         ; set that to byte 1 of the buffer segment
                                 
      INY                        ; increment the Y register (now Y == 2)
      LDA bgTargetRowLow         ; load the low byte of the target row
      STA [bufferLow], y         ; set that to byte 2 of the buffer segment   
                                 
      INY                        
      INY                        ; increment the Y register twice (now Y == 4)
                                 
      STY placeholder1           ; store the value of the Y register in placeholder1
      LDY #$00                   ; start out at 0
                                 
      .bufferedDrawLoop:          
        LDA [bgSourceRowLow], y  ; load a byte of the background data
        STY placeholder2         ; store current source offset in placeholder2    
        
        LDY placeholder1         ; load the buffer offset from placeholder1
        STA [bufferLow], y       ; write to the buffer
        INY                      ; Y = Y + 1
        STY placeholder1         ; store the new buffer back to the placeholder1
        
        LDY placeholder2         ; load the source offset from placeholder2
        INY                      ; Y = Y + 1
        CPY #$20                 ; compare Y to hex $20, decimal 32 - copying 32 bytes
        BNE .bufferedDrawLoop    ; loop if there's more data to be copied
                                 
      LDA placeholder1           ; load the buffer offset from placeholder1
      CLC                        
      ADC bufferLow              
      STA bufferLow              ; add it to bufferLow to point to the next buffer
      LDA bufferHigh             
      ADC #$00                   
      STA bufferHigh             ; add carry to bufferHigh
                                 
      JMP DrawRowDone            
                                 
    .bulkDraw:                   ; we're doing a bulk draw, draw directly in PPU
                                 
      LDA $2002                  ; read PPU status to reset the high/low latch
      LDA bgTargetRowHigh        
      STA $2006                  ; write the high byte of row address
      LDA bgTargetRowLow         
      STA $2006                  ; write the low byte of row address
      LDX #$20                   ; copy 32 bytes
      LDY #$00
      
      .bulkDrawLoop:
        LDA [bgSourceRowLow], y
        STA $2007
        INY
        DEX
        BNE .bulkDrawLoop
      
  DrawRowDone:

  RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Name:                                                     ;;
;;   DrawNewAttributes                                       ;;
;;                                                           ;;
;; Description:                                              ;; 
;;   Draws in PPU the attributes that are about to be shown  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DrawNewAttributes:

  ; First calculate where in PPU to draw the attributes using the following formula:
  ; 
  ; |----------|-----------|------------------|---------------------|-----------------------------|
  ; | Att. Row |   Offset  | Draw when scroll |      Draw in        |           Formula           |
  ; |----------|-----------|------------------|---------------------|-----------------------------|
  ; |    0     | $C0 = 192 |    $20 = 32      |  current nametable  | Offset = $B8 + (scroll / 4) |
  ; |    1     | $C8 = 200 |    $40 = 64      |  current nametable  | Offset = $B8 + (scroll / 4) |
  ; |    2     | $D0 = 208 |    $60 = 96      |  current nametable  | Offset = $B8 + (scroll / 4) |
  ; |    3     | $D8 = 216 |    $80 = 128     |  current nametable  | Offset = $B8 + (scroll / 4) |
  ; |    4     | $E0 = 224 |    $A0 = 160     |  current nametable  | Offset = $B8 + (scroll / 4) |
  ; |    5     | $E8 = 232 |    $C0 = 192     |  current nametable  | Offset = $B8 + (scroll / 4) |
  ; |    6     | $F0 = 240 |    $E0 = 224     |  current nametable  | Offset = $B8 + (scroll / 4) |
  ; |    7     | $F8 = 248 |    $00 = 0       | the other nametable |       special case          |
  ; |----------|-----------|------------------|---------------------|-----------------------------|
  
  DrawNewAttributesPPU:
  
    LDA scroll
    BEQ .scroll0
  
    .scrollNot0:
      LDA nametable                     ; load nametable number
      ASL A                             ; shift up, A = $04 (for nametable == 2) or $00 (for nametable == 0)
      ASL A                             ; shift up, A = $08 (for nametable == 2) or $00 (for nametable == 0)
      CLC                                    
      ADC #$23                          ; add $23, now A = $23 (for nametable == 0) or $2B (for nametable == 2)
      STA bgTargetRowHigh               
                                        
      LDA scroll                        
      LSR A                             
      LSR A                             ; shift right twice - same as dividing by 4
      CLC                               
      ADC #$B8                          ; add $B8
      STA bgTargetRowLow
      JMP DrawNewAttributesPPUDone
    
    .scroll0:
      LDA nametable                     ; load nametable number
      EOR #$02                          ; invert second bit, A = $00 (for nametable == 2) or $02 (for nametable == 0)
      ASL A                             ; shift up, A = $00 (for nametable == 2) or $04 (for nametable == 0)
      ASL A                             ; shift up, A = $00 (for nametable == 2) or $08 (for nametable == 0)
      CLC                                    
      ADC #$23                          ; add $23, now A = $23 (for nametable == 2) or $2B (for nametable == 0)
      STA bgTargetRowHigh               
      LDA #$F8                          
      STA bgTargetRowLow                ; now address is $23F8 (for nametable == 2) or $2BF8 (for nametable == 0)
      
  DrawNewAttributesPPUDone:
  
  ; Calculate the source address of the attr. row.
  ; First figure out which nametable should we load from (based on screen number).
  ; Then get the pointer. Finally, calculate the offset using the following formula:
  ;
  ; |--------|------------|------------------------|-----------------------------------|
  ; | Scroll | Source Row |         Offset         |              Formula              |
  ; |--------|------------|------------------------|-----------------------------------|
  ; |    0   |     7      | $3F8 = 1016 = 960 + 56 |        Offset = 960 + 7 x 8       |
  ; |   32   |     0      | $3C0 = 960  = 960 + 0  | Offset = 960 + (scroll - 32) / 32 |
  ; |   64   |     1      | $3C8 = 968  = 960 + 8  | Offset = 960 + (scroll - 32) / 32 |
  ; |   96   |     2      | $3D0 = 976  = 960 + 16 | Offset = 960 + (scroll - 32) / 32 |
  ; |  128   |     3      | $3D8 = 984  = 960 + 24 | Offset = 960 + (scroll - 32) / 32 |
  ; |  160   |     4      | $3E0 = 992  = 960 + 32 | Offset = 960 + (scroll - 32) / 32 |
  ; |  192   |     5      | $3E8 = 1000 = 960 + 40 | Offset = 960 + (scroll - 32) / 32 |
  ; |  224   |     6      | $3F0 = 1008 = 960 + 48 | Offset = 960 + (scroll - 32) / 32 |
  ; |--------|------------|------------------------|-----------------------------------|
  
  DrawNewAttributesSource:
  
    LDA screenNumber                    ; load the screenNumber
    ASL A                               ; shift left. A now contains "screen number * 2"
    CLC                                 
    ADC #NAMETABLE_OFFSET               ; add the nametable offset set A to the nametable pointer
    TAY                                 ; move A to Y
                                        
    LDA [bgLevelLow], y                 ; load the high byte of the nametable's address
    STA bgSourceRowHigh                 
    INY                                 ; Y = Y + 1
    LDA [bgLevelLow], y                 ; load the low byte of the nametable's address
    STA bgSourceRowLow                  
                                        
    INC bgSourceRowHigh                 
    INC bgSourceRowHigh                 
    INC bgSourceRowHigh                 ; we must add 960 to the offset - inc high byte 3 times (same as +768)
    LDA bgSourceRowLow                  
    CLC                                 
    ADC #$C0                            ; add #$C0 = 192 to low byte (768 + 192 = 960)
    STA bgSourceRowLow                  
    LDA bgSourceRowHigh                 
    ADC #$00                            
    STA bgSourceRowHigh                 ; add carry to the high byte
                                        
    LDA scroll                          ; load the scroll
    BEQ .scroll0                        
                                        
    .scrollNot0:                        
      LDA scroll                        
      SEC                               
      SBC #$20                          ; A = scroll - 32
      BEQ DrawNewAttributesSourceDone   ; scroll = 32 => no offset
      LSR A
      LSR A
      LSR A
      LSR A
      LSR A                             ; A = (scroll - 32) / 32
      TAX                               ; X = (scroll - 32) / 32
      JMP .loop                         
                                        
    .scroll0:                           
      LDX #$07                          ; X = 7
                                        
    .loop:                              
      LDA bgSourceRowLow                ; add 8 to bgSourceRowLow
      CLC                               
      ADC #$08
      STA bgSourceRowLow                
      LDA bgSourceRowHigh               ; add carry to bgSourceRowHigh
      ADC #$00                          
      STA bgSourceRowHigh               
      DEX                               ; X = X - 1
      BNE .loop                         ; if X > 0 there is still data to copy
  
  DrawNewAttributesSourceDone:
  
  
  ; Now just copy the 8 bytes of the attributes using the calculated addresses
  
  DrawAttributes:
  
    LDA bulkDraw
    BNE .bulkDraw
    
    .bufferedDraw:                      ; we're doing a buffered draw, buffer the data in RAM
                                        
      LDY #$00                          ; load 0 to the Y register
      LDA #$08                          ; load $08 = 08 to the A register (we're drawing a attribute row == 8 bytes)
      STA [bufferLow], y                ; set that to byte 0 of the buffer segment
                                        
      INY                               ; increment the Y register (now Y == 1)
      LDA bgTargetRowHigh               ; load the high byte of the target row
      STA [bufferLow], y                ; set that to byte 1 of the buffer segment
                                        
      INY                               ; increment the Y register (now Y == 2)
      LDA bgTargetRowLow                ; load the low byte of the target row
      STA [bufferLow], y                ; set that to byte 2 of the buffer segment   
                                        
      INY                               
      INY                               ; increment the Y register twice (now Y == 4)
                                 
      STY placeholder1                  ; store the value of the Y register in placeholder1
      LDY #$00                          ; start out at 0
                                        
      .bufferedDrawLoop:                 
        LDA [bgSourceRowLow], y         ; load a byte of the attributes data
        STY placeholder2                ; store current source offset in placeholder2    
                                        
        LDY placeholder1                ; load the buffer offset from placeholder1
        STA [bufferLow], y              ; write to the buffer
        INY                             ; Y = Y + 1
        STY placeholder1                ; store the new buffer back to the placeholder1
                                        
        LDY placeholder2                ; load the source offset from placeholder2
        INY                             ; Y = Y + 1
        CPY #$08                        ; compare Y to hex $08, decimal 08 - copying 8 bytes
        BNE .bufferedDrawLoop           ; loop if there's more data to be copied
                                        
      LDA placeholder1                  ; load the buffer offset from placeholder1
      CLC                               
      ADC bufferLow                     
      STA bufferLow                     ; add it to bufferLow to point to the next buffer
      LDA bufferHigh                    
      ADC #$00                          
      STA bufferHigh                    ; add carry to bufferHigh
                                        
      JMP DrawAttributesDone            
                                        
    .bulkDraw:                          ; we're doing a bulk draw, draw directly in PPU
                                        
      LDA $2002                         ; read PPU status to reset the high/low latch
      LDA bgTargetRowHigh               
      STA $2006                         ; write the high byte of row address
      LDA bgTargetRowLow                
      STA $2006                         ; write the low byte of row address
      LDX #$08                          ; copy 8 bytes
      LDY #$00
      
      .bulkDrawLoop:
        LDA [bgSourceRowLow], y
        STA $2007
        INY
        DEX
        BNE .bulkDrawLoop
      
  DrawAttributesDone:

  RTS