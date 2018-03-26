;;;;;;;;;;;;;
;; BULLETS ;;
;;;;;;;;;;;;;

; Holds information about all bullet types.
;
; Note - about size of bullets - size is the offset of the hitbox.
;        So if bullet's position is 10 and width is 3, then x1 = 10 and x2 = 13.
;        So the actual width ends up being 4.

;;;;;;;;;;;;;;;;;;;;;;
;; PLAYER'S BULLETS ;;
;;;;;;;;;;;;;;;;;;;;;;

; Player's bullets.
; Format;
;   tile used
;   att used
;   size (4 bits: width, 4 bits: height)
;   x offset (when spawning)
;   y offset (when spawning)
;   damage
;   number of projectiles fired
;   then for each projectile: speed (4 bits: x, 4 bits: y)
;
; When a bullet is fired, information about it is stored in memory.
; This is the format:
;   00: damage
;   01: size (4 bits: width, 4 bits: height)
;   02: speed x (signed)
;   03: speed y (signed)
;
; If damage == 0 it means the bullet is exploding, size works as the counter in that case.

bullet_flame:
  .byte $0F                       ; tile
  .byte $02                       ; att
  .byte %01000111                 ; size: 4 x 7 (so it's actually 5 x 8)
  .byte (SHIP_WIDTH - $04) / $02  ; x offset ($04 is width from above)
  .byte $08                       ; y offset ($08 is height from above)
  .byte $01                       ; dmg = 1
  .byte $01                       ; 1 projectile
  .byte $00, $FC                  ; speed (x = 0 y = -4)

bullet_laser:
  .byte $1F                       ; tile
  .byte $01                       ; att
  .byte %01000111                 ; size: 4 x 7 (so it's actually 5 x 8)
  .byte (SHIP_WIDTH - $02) / $02  ; x offset ($02 is width from above)
  .byte $08                       ; y offset ($08 is height from above)
  .byte $02                       ; dmg = 2
  .byte $01                       ; 1 projectile
  .byte $00, $FB                  ; speed (x = 0 y = -5)

bullet_spread:
  .byte $0F                       ; tile
  .byte $01                       ; att
  .byte %01000111                 ; size: 4 x 7 (so it's actually 5 x 8)
  .byte (SHIP_WIDTH - $04) / $02  ; x offset ($04 is width from above)
  .byte $08                       ; y offset ($08 is height from above)
  .byte $02                       ; dmg = 2
  .byte $03                       ; 3 projectiles
  .byte $FE, $FA                  ; 1st speed (x = -2 y = -5)
  .byte $00, $FA                  ; 2nd speed (x =  0 y = -5)
  .byte $02, $FA                  ; 3rd speed (x =  2 y = -5)
  
; Lookup table  
  
bullets:
  .byte HIGH(bullet_flame),  LOW(bullet_flame)   ; BULLET_FLAME 
  .byte HIGH(bullet_laser),  LOW(bullet_laser)   ; BULLET_LASER 
  .byte HIGH(bullet_spread), LOW(bullet_spread)  ; BULLET_SPREAD
  
;;;;;;;;;;;;;;;;;;;
;; ENEMY BULLETS ;;
;;;;;;;;;;;;;;;;;;;

; Enemy bullets.
; Format;
;   tile used
;   att used
;   size (4 bits: width, 4 bits: height)
;   damage
;   type: fixed or targeted
;   x speed (if fixed) / overall speed (if targeted)
;   y speed (if fixed) / 0 (if targeted)
;
; When a bullet is fired, information about it is stored in memory.
; Format is the same as player's bullets

en_bullet_fireball_targeted:      ; targeted fireball
  .byte $2F                       ; tile
  .byte $02                       ; att
  .byte %01010101                 ; size: 5 x 5 (so it's actually 6 x 6)
  .byte $01                       ; dmg = 1
  .byte EN_BULLET_TARGETED        ; targeted
  .byte $05, $00                  ; speed = 5

ENB_FB_T_L = LOW(en_bullet_fireball_targeted)
ENB_FB_T_H = HIGH(en_bullet_fireball_targeted)

en_bullet_mine_targeted:          ; targeted mine
  .byte $3F                       ; tile
  .byte $02                       ; att
  .byte %01000100                 ; size: 4 x 4 (so it's actually 5 x 5)
  .byte $02                       ; dmg = 2
  .byte EN_BULLET_TARGETED        ; targeted
  .byte $05, $00                  ; speed = 4

ENB_M_T_L = LOW(en_bullet_mine_targeted)
ENB_M_T_H = HIGH(en_bullet_mine_targeted)