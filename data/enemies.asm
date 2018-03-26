;;;;;;;;;;;;;
;; ENEMIES ;;
;;;;;;;;;;;;;

; Holds information about all enemies.
; This is the layout of the information:
;
; hit-box x offset
; hit-box y offset
; hit-box width
; hit-box height
; max hp
; ram damage
; move type
; move param 1
; move param 2
; xp yield
; bullet pointer high byte (00 means enemy doesn't shoot)
; bullet pointer low byte (00 means enemy doesn't shoot)
; bullet spawn X offset
; bullet spawn Y offset
; shoot frequency
; tiles (in rows)
; attributes (in rows)
;
; This information is copied to the enemy memory (in page 4)
; We'll be using 16 bytes per enemy.
; This is the layout:
; 
; 00: hit-box x offset
; 01: hit-box y offset
; 02: hit-box width
; 03: hit-box height
; 04: current hp
; 05: ram damage
; 06: move type
; 07: move param 1
; 08: move param 2
; 09: xp yield
; 10: bullet pointer high byte (00 means enemy doesn't shoot)
; 11: bullet pointer low byte (00 means enemy doesn't shoot)
; 12: bullet spawn X offset
; 13: bullet spawn Y offset
; 14: shoot frequency
; 15: shoot timer

; Move params:
; - linear: byte 1 is X speed, byte 2 is Y speed. FF for Y speed means move with the screen.
;           Both X and Y can be negative (though Y cannot be -1 == FF)
;
; About hitbox width/height - it's actually not the width, but width - 1.
; It's used to calculate x2 and y2. So if x1 = 10 and width = 10, x2 = 20 => width is actually 11.

spider:
  .byte $02, $00                      ; hitbox offest: x = 2, y = 0
  .byte $0B, $0F                      ; hitbox: 11x15
  .byte $01                           ; 1 HP
  .byte $02                           ; ram damage = 2
  .byte MOVE_TYPE_LINEAR              ; linear movement
  .byte $00, $05                      ; vertical movement (going down)
  .byte $01                           ; yields 1 xp
  .byte $00, $00                      ; doesn't shoot
  .byte $00, $00                      ; doesn't shoot
  .byte $00                           ; doesn't shoot
  .byte $36, $36, $46, $46            ; tiles
  .byte $01, $41, $01, $41            ; attributes
                                      
spider_up:                            
  .byte $02, $00                      ; hitbox offest: x = 2, y = 0
  .byte $0B, $0F                      ; hitbox: 11x15
  .byte $01                           ; 1 HP
  .byte $02                           ; ram damage = 2
  .byte MOVE_TYPE_LINEAR              ; linear movement
  .byte $00, $FB                      ; vertical movement (going up, $FB = -5)
  .byte $01                           ; yields 1 xp
  .byte $00, $00                      ; doesn't shoot
  .byte $00, $00                      ; doesn't shoot
  .byte $00                           ; doesn't shoot
  .byte $46, $46, $36, $36            ; tiles
  .byte $81, $C1, $81, $C1            ; attributes
                                      
sweeper_l:                            
  .byte $00, $00                      ; no hitbox offset
  .byte $0F, $0F                      ; hitbox: 15x15
  .byte $02                           ; 2 HP
  .byte $02                           ; ram damage = 2
  .byte MOVE_TYPE_LINEAR              ; linear movement
  .byte $FF, $00                      ; horizontal movement ($FC = -1)
  .byte $01                           ; yields 1 XP
  .byte ENB_FB_T_H, ENB_FB_T_L        ; shoots a targeted fireball
  .byte $05, $05                      ; bullet offsets: x = 5, y = 5
  .byte $20                           ; frequency: 32
  .byte $38, $39, $38, $39            ; tiles
  .byte $01, $01, $81, $81            ; attributes
                                      
sweeper_r:                            
  .byte $00, $00                      ; no hitbox offset
  .byte $0F, $0F                      ; hitbox: 15x15
  .byte $02                           ; 2 HP
  .byte $02                           ; ram damage = 2
  .byte MOVE_TYPE_LINEAR              ; linear movement
  .byte $01, $00                      ; horizontal movement
  .byte $01                           ; yields 1 XP
  .byte ENB_FB_T_H, ENB_FB_T_L        ; shoots a targeted fireball
  .byte $05, $05                      ; bullet offsets: x = 5, y = 5
  .byte $20                           ; frequency: 32
  .byte $39, $38, $39, $38            ; tiles
  .byte $41, $41, $C1, $C1            ; attributes
  
drone:
  .byte $00, $00                      ; hitbox offest: x = 0, y = 0
  .byte $0F, $0F                      ; hitbox: 15x15
  .byte $01                           ; 1 HP
  .byte $02                           ; ram damage = 2
  .byte MOVE_TYPE_SINUS               ; sinusoidal movement
  .byte $00, $00                      ; must both be 0 for the move type
  .byte $01                           ; yields 1 xp
  .byte $00, $00                      ; doesn't shoot
  .byte $00, $00                      ; doesn't shoot
  .byte $00                           ; doesn't shoot
  .byte $37, $37, $47, $47            ; tiles
  .byte $01, $41, $01, $41            ; attributes
  
gunship:
  .byte $00, $00                      ; hitbox offest: x = 0, y = 0
  .byte $0F, $0F                      ; hitbox: 15x15
  .byte $03                           ; 3 HP
  .byte $02                           ; ram damage = 2
  .byte MOVE_TYPE_LINEAR              ; linear movement
  .byte $00, $02                      ; slow vertical movement
  .byte $03                           ; yields 3 xp
  .byte ENB_M_T_H, ENB_M_T_L          ; shoots a targeted mine
  .byte $06, $06                      ; bullet offsets: x = 6, y = 6
  .byte $20                           ; frequency: 32
  .byte $35, $35, $45, $45            ; tiles
  .byte $01, $41, $01, $41            ; attributes
  
; Enemies lookup table

enemies:
  .byte HIGH(spider),     LOW(spider)     ; SPIDER_ID
  .byte HIGH(spider_up),  LOW(spider_up)  ; SPIDER_UP_ID
  .byte HIGH(sweeper_l),  LOW(sweeper_l)  ; SWEEPER_L_ID
  .byte HIGH(sweeper_r),  LOW(sweeper_r)  ; SWEEPER_R_ID
  .byte HIGH(drone),      LOW(drone)      ; DRONE_ID
  .byte HIGH(gunship),    LOW(gunship)    ; GUNSHIP_ID