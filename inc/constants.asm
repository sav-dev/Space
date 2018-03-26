;;;;;;;;;;;;;;;;                             
;; SPRITE DMA ;;                             
;;;;;;;;;;;;;;;;                             
                                             
SPRITES_LOW_BYTE    = $00  ; low byte of the sprites page
SPRITES_HIGH_BYTE   = $02  ; high sprite of the sprites page
                                              
;;;;;;;;;;;;;;;                               
;; BUFFERING ;;                               
;;;;;;;;;;;;;;;                               
                                              
BUFFER_LOW_BYTE     = $00  ; low byte of the data buffer
BUFFER_HIGH_BYTE    = $07  ; high byte of the data buffer
                    
;;;;;;;;;;;;;;;;;                             
;; CONTROLLERS ;;                             
;;;;;;;;;;;;;;;;;                             
                                              
CONTROLLER_A        = %10000000  ; controller bitmasks
CONTROLLER_B        = %01000000               
CONTROLLER_SEL      = %00100000               
CONTROLLER_START    = %00010000               
CONTROLLER_UP       = %00001000               
CONTROLLER_DOWN     = %00000100               
CONTROLLER_LEFT     = %00000010               
CONTROLLER_RIGHT    = %00000001               
CONTROLLER_L_OR_R   = %00000011               
                                             
;;;;;;;;;;;;                                 
;; LEVELS ;;                                 
;;;;;;;;;;;;
                                             
NAMETABLE_OFFSET    = $06  ; how much nametable data is offset in the level data
LEVELS_COUNT        = $02  ; how many levels are there

;;;;;;;;;;;;;;;;;
;; BACKGROUNDS ;;
;;;;;;;;;;;;;;;;;

CLEAR_TILE          = $30  ; a clear tile
CLEAR_BG_ATT        = %10101010

;;;;;;;;;;;;;;;;
;; CHARACTERS ;;
;;;;;;;;;;;;;;;;

CHAR_0              = $00
CHAR_1              = $01
CHAR_2              = $02
CHAR_3              = $03
CHAR_4              = $04
CHAR_5              = $05
CHAR_6              = $06
CHAR_7              = $07
CHAR_8              = $08
CHAR_9              = $09
CHAR_A              = $0A
CHAR_B              = $0B
CHAR_C              = $0C
CHAR_D              = $0D
CHAR_E              = $0E
CHAR_F              = $0F
CHAR_G              = $10
CHAR_H              = $11
CHAR_I              = $12
CHAR_J              = $13
CHAR_K              = $14
CHAR_L              = $15
CHAR_M              = $16
CHAR_N              = $17
CHAR_O              = $18
CHAR_P              = $19
CHAR_Q              = $1A
CHAR_R              = $1B
CHAR_S              = $1C
CHAR_T              = $1D
CHAR_U              = $1E
CHAR_V              = $1F
CHAR_W              = $20
CHAR_X              = $21
CHAR_Y              = $22
CHAR_Z              = $23
CHAR_SPACE          = CLEAR_TILE
CHAR_EXCLAMATION    = $24
CHAR_COLON          = $25
CHAR_APOSTROPHE     = $26

;;;;;;;;;;;;;;;;                                
;; GAME STATE ;;                                 
;;;;;;;;;;;;;;;;

GAMESTATE_TITLE     = $00  ; gamestate == displaying title
GAMESTATE_STAGE     = $01  ; gamestate == displaying stage #
GAMESTATE_PLAYING   = $02  ; gamestate == playing
GAMESTATE_CONTINUE  = $03  ; gamestate == continue
GAMESTATE_END       = $04  ; gamestate == end
GAMESTATE_PASSWORD  = $05  ; gamestate == password
GAMESTATE_NONE      = $FF  ; gamestate == none (game just started, change to title ASAP)

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; GAME STATE != PLAYING ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

PS_TIMER_FREQ       = $30  ; frequency of the blinking "press start" string
SEL_TILE            = $F6  ; selection tiles

;;;;;;;;;;;;;;;;;;;;;;;;;
;; GAME STATE == TITLE ;;
;;;;;;;;;;;;;;;;;;;;;;;;;

T_SEL_0_HIGH        = $22  ; selection picker addresses
T_SEL_0_LOW         = $CB

T_SEL_1_HIGH        = $23
T_SEL_1_LOW         = $0B

T_SEL_ATT_0_HIGH    = $23  ; attributes that must be updated on the shift
T_SEL_ATT_0_LOW     = $EA
T_SEL_ATT_0         = %01101010
T_SEL_ATT_1_HIGH    = $23  ; attributes that must be updated on the shift
T_SEL_ATT_1_LOW     = $F2
T_SEL_ATT_1         = %10100110

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; GAME STATE == CONTINUE ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

C_SEL_0_HIGH        = $21  ; selection picker addresses
C_SEL_0_LOW         = $CD

C_SEL_1_HIGH        = $22
C_SEL_1_LOW         = $0D

C_SEL_ATT_0_HIGH    = $23  ; attributes that must be updated
C_SEL_ATT_0_LOW     = $DB
C_SEL_ATT_0         = %10011010

C_SEL_ATT_1_HIGH    = $23
C_SEL_ATT_1_LOW     = $E3
C_SEL_ATT_1         = %10101001

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; GAME STATE == PASSWORD ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PASS_CHAR_HIGH      = $20  ; address of the first character in the password
PASS_CHAR_LOW       = $CE

SPRITE_SELECTOR     = $0200  ; selector == first sprite

SEL_ATT             = %00000001

CHAR_OFF            = CHAR_A  ; selector + this = tile for the char

;;;;;;;;;;;;;                                 
;; DRAWING ;;                                 
;;;;;;;;;;;;;

SCREEN_BOTTOM       = $F0  ; y >= this => sprite is off-screen

;;;;;;;;;;;;                                 
;; MEMORY ;;                                 
;;;;;;;;;;;;
          
; This is the memory layout:
;
; $0000 - $00FF => pointers
; $0100 - $01FF => stack
; $0200 - $02FF => sprites (see below)
; $0300 - $03FF => sound
; $0400 - $04xx => player's bullets data in memory
; $04xx - $04xx => enemy bullets data in memory
; $04xx - $04CB => enemies data in memory
; $04CC - $06FF => variables
; $0700 - $07FF => drawing buffer
;
; Sprites layout:
;
; status bars       (4 sprites)
; player's bullets  (x sprites)
; enemy bullets     (y sprites, x + y = 19)
; ship              (9 sprites)
; enemies/boss      (32 sprites)

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; RANDOM OBJECT RELATED ;;                        
;;;;;;;;;;;;;;;;;;;;;;;;;;;                 
                                             
CLEAR_SPRITE        = $FE                ; if Y is set to this it means sprite is cleared
Y_OFF               = $00                ; offset of the Y position in the sprite data
TILE_OFF            = $01                ; offset of the tile byte in the sprite data
ATT_OFF             = $02                ; offset of the att. byte in the sprite data
X_OFF               = $03                ; offset of the X position in the sprite data
SPRITE_SIZE         = $04                ; size of one sprite
METASPRITE_SIZE     = SPRITE_SIZE * $04  ; size of one metasprite (2x2)
SPRITE_OFF          = SPRITE_SIZE        ; offset from one sprite to another
SPRITES_ADDRESS     = $0200              ; where sprites start in memory
MEMORY_ADDRESS      = $0400              ; where object memory starts
                  
;;;;;;;;;;;;;;;;;
;; STATUS BARS ;;
;;;;;;;;;;;;;;;;;

SPRITE_HP_BAR_0     = SPRITES_ADDRESS  ; which sprites do status bars use
SPRITE_HP_BAR_1     = SPRITE_HP_BAR_0 + SPRITE_OFF
SPRITE_XP_BAR_0     = SPRITE_HP_BAR_1 + SPRITE_OFF
SPRITE_XP_BAR_1     = SPRITE_XP_BAR_0 + SPRITE_OFF

HP_X_0              = $0A  ; position of status bars
HP_Y_0              = $0A
HP_X_1              = HP_X_0
HP_Y_1              = HP_Y_0 + $08
XP_X_0              = HP_X_0
XP_Y_0              = HP_Y_1 + $08 + $04
XP_X_1              = HP_X_0
XP_Y_1              = XP_Y_0 + $08

HP_ATT              = $02  ; what attributes do status bars use
XP_ATT              = $01

BAR_4_4             = $30  ; what tiles do status bars use
BAR_3_4             = $31
BAR_2_4             = $32
BAR_1_4             = $33
BAR_0_4             = $34
                  
;;;;;;;;;;;;;;;;;;;;;;
;; PLAYER'S BULLETS ;;
;;;;;;;;;;;;;;;;;;;;;;

BULLETS_COUNT       = $09                           ; max number of bullets
SPRITES_BULLETS     = SPRITE_XP_BAR_1 + SPRITE_OFF  ; where bullet sprites start in memory
MEMORY_BULLETS      = MEMORY_ADDRESS                ; where bullet data starts in memory
BULLETS_SIZE        = BULLETS_COUNT * SPRITE_SIZE   ; size of bullet sprites in memory
          
BULLET_FLAME        = $00
BULLET_LASER        = $01
BULLET_SPREAD       = $02
MAX_BULLET_ID       = BULLET_SPREAD
          
BULLET_TILE         = $00
BULLET_ATT          = BULLET_TILE + $01
BULLET_SIZE         = BULLET_ATT + $01
BULLET_X_OFF        = BULLET_SIZE + $01
BULLET_Y_OFF        = BULLET_X_OFF + $01
BULLET_DAMAGE       = BULLET_Y_OFF + $01
BULLET_C_FIRED      = BULLET_DAMAGE + $01
BULLET_SPEED        = BULLET_C_FIRED + $01

BULLET_MEM_DAMAGE   = $00
BULLET_MEM_SIZE     = BULLET_MEM_DAMAGE + $01
BULLET_MEM_SPEED_X  = BULLET_MEM_SIZE + $01
BULLET_MEM_SPEED_Y  = BULLET_MEM_SPEED_X + $01

;;;;;;;;;;;;;;;;;;;
;; ENEMY BULLETS ;;
;;;;;;;;;;;;;;;;;;;

EN_BULLETS_COUNT    = $09                             ; max number of enemy bullets
SPRITES_EN_BULLETS  = SPRITES_BULLETS + BULLETS_SIZE  ; where enemy bullet sprites start in memory
MEMORY_EN_BULLETS   = MEMORY_BULLETS + BULLETS_SIZE   ; where enemy bullet data starts in memory
EN_BULLETS_SIZE     = EN_BULLETS_COUNT * SPRITE_SIZE  ; size of enemy bullet sprites in memory

EN_BULLET_TILE      = $00
EN_BULLET_ATT       = EN_BULLET_TILE + $01
EN_BULLET_SIZE      = EN_BULLET_ATT + $01
EN_BULLET_DAMAGE    = EN_BULLET_SIZE + $01
EN_BULLET_TYPE      = EN_BULLET_DAMAGE + $01
EN_BULLET_SPEED     = EN_BULLET_TYPE + $01

EN_BULLET_FIXED     = $00  ; fixed direction
EN_BULLET_TARGETED  = $01  ; targeted bullet

;;;;;;;;;;;;;                          
;; EXHAUST ;;                           
;;;;;;;;;;;;;                        

SPRITE_EXHAUST     = SPRITES_EN_BULLETS + EN_BULLETS_SIZE  ; where the exhaust is in memory
SIZE_EXHAUST       = SPRITE_SIZE                           ; size of exhaust in memory
             
EXHAUST_TILE_MIN   = $40
EXHAUST_TILE_MAX   = $42

EXHAUST_ATT        = $02  ; atts

EXHAUST_X_OFFSET   = $08  ; offsets
EXHAUST_Y_OFFSET   = $18

EXHAUST_AN_FREQ    = $01  ; exhaust animation frequency
             
;;;;;;;;;;                           
;; SHIP ;;                           
;;;;;;;;;;                           
                                             
SPRITES_SHIP_COUNT  = $09                               ; ship consists of 9 sprites
SPRITES_SHIP        = SPRITE_EXHAUST + SIZE_EXHAUST     ; where ship starts in memory
SIZE_SHIP           = SPRITES_SHIP_COUNT * SPRITE_SIZE  ; size of ship memory
        
SHIP_ATT            = $00

SHIP_TILE_F_L       = $00
SHIP_TILE_L         = $03        
SHIP_TILE_U         = $06
SHIP_TILE_R         = $09        
SHIP_TILE_F_R       = $0C
                                           
SHIP_OFF_1          = SPRITE_OFF * $01  ; offsets:
SHIP_OFF_2          = SPRITE_OFF * $02  ; $00 $04 $08
SHIP_OFF_3          = SPRITE_OFF * $03  ; $0C $10 $14
SHIP_OFF_4          = SPRITE_OFF * $04  ; $18 $1C $20
SHIP_OFF_5          = SPRITE_OFF * $05
SHIP_OFF_6          = SPRITE_OFF * $06
SHIP_OFF_7          = SPRITE_OFF * $07
SHIP_OFF_8          = SPRITE_OFF * $08
              
SHIP_X_OFF          = SPRITES_SHIP + X_OFF
SHIP_Y_OFF          = SPRITES_SHIP + Y_OFF
SHIP_TILE_OFF       = SPRITES_SHIP + TILE_OFF
SHIP_ATT_OFF        = SPRITES_SHIP + ATT_OFF

shipX               = SHIP_X_OFF
shipY               = SHIP_Y_OFF
              
SHIP_WIDTH          = $13  ; = 19, width of the ship
SHIP_HEIGHT         = $18  ; = 24, height of the ship
                    
SHIP_SPEED          = $02  ; speed of the ship
                                                
SHIP_X_MIN          = $00 + SHIP_SPEED                ; ship movement bounds
SHIP_Y_MIN          = $00 + SHIP_SPEED + $08          ; $08 = max bullet height 
SHIP_X_MAX          = $FF - SHIP_WIDTH - SHIP_SPEED + $01
SHIP_Y_MAX          = $EF - SHIP_HEIGHT - SHIP_SPEED
                    
SHIP_X_DEFAULT      = ($FF - SHIP_WIDTH) / $02  ; default position (x)
SHIP_Y_DEFAULT      = SHIP_Y_MAX - $0A          ; default position (y)

SHIP_MAX_HP         = $08  ; max and inital HP
SHIP_XP_CAP         = $20  ; how much XP is needed to level up

SHIP_OUT_HB_X_OFF   = $01  ; ship's hitboxes
SHIP_OUT_HB_Y_OFF   = $01  ; note - width and height are not actual values in pixels,
SHIP_OUT_HB_WIDTH   = $10  ; they are also offsets. So Width = 7 actually  means Width = 8
SHIP_OUT_HB_HEIGHT  = $15

SHIP_IN_HB_1_X_OFF  = $03
SHIP_IN_HB_1_Y_OFF  = $01
SHIP_IN_HB_1_WIDTH  = $0C
SHIP_IN_HB_1_HEIGHT = $0B

SHIP_IN_HB_2_X_OFF  = $01
SHIP_IN_HB_2_Y_OFF  = $0C
SHIP_IN_HB_2_WIDTH  = $10
SHIP_IN_HB_2_HEIGHT = $0A

SHIP_DIRECTION_F_L  = $00  ; ship direction
SHIP_DIRECTION_L    = $01
SHIP_DIRECTION_U    = $02
SHIP_DIRECTION_R    = $03
SHIP_DIRECTION_F_R  = $04

SHIP_MOVEMENT_L     = $00
SHIP_MOVEMENT_U     = $01
SHIP_MOVEMENT_R     = $02

SHIP_ANIMATION_FREQ = $04 ; how fast the ship turning animation is

CONTINUE_COUNTER    = $A0 ; when to show the continue screen after the ship blows up

;;;;;;;;;;;;;
;; ENEMIES ;;
;;;;;;;;;;;;;

ENEMIES_COUNT       = $08                                  ; max number of enemies
SPRITES_ENEMIES     = SPRITES_SHIP + SIZE_SHIP             ; where enemy sprites start in memory
MEMORY_ENEMIES      = MEMORY_EN_BULLETS + EN_BULLETS_SIZE  ; where enemy gdata starts in memory
ENEMIES_SIZE        = ENEMIES_COUNT * METASPRITE_SIZE      ; size of enemy sprites in memory
                                              
SPEC_HB_X_OFFSET    = $00
SPEC_HB_Y_OFFSET    = SPEC_HB_X_OFFSET + $01
SPEC_HITBOX_W       = SPEC_HB_Y_OFFSET + $01
SPEC_HITBOX_H       = SPEC_HITBOX_W + $01
SPEC_MAX_HP         = SPEC_HITBOX_H + $01
SPEC_RAM_DAMAGE     = SPEC_MAX_HP + $01
SPEC_MOVE_TYPE      = SPEC_RAM_DAMAGE + $01
SPEC_MOVE_PARAM_1   = SPEC_MOVE_TYPE + $01
SPEC_MOVE_PARAM_2   = SPEC_MOVE_PARAM_1 + $01
SPEC_XP_YIELD       = SPEC_MOVE_PARAM_2 + $01
SPEC_BULLET_HIGH    = SPEC_XP_YIELD + $01
SPEC_BULLET_LOW     = SPEC_BULLET_HIGH + $01
SPEC_BULLET_X_OFF   = SPEC_BULLET_LOW + $01
SPEC_BULLET_Y_OFF   = SPEC_BULLET_X_OFF + $01
SPEC_SHOOT_FREQ     = SPEC_BULLET_Y_OFF + $01
SPEC_TILES          = SPEC_SHOOT_FREQ + $01
SPEC_ATT            = SPEC_TILES + $04 
                    
EN_HB_X_OFFSET      = $00
EN_HB_Y_OFFSET      = EN_HB_X_OFFSET + $01
EN_HITBOX_W         = EN_HB_Y_OFFSET + $01     
EN_HITBOX_H         = EN_HITBOX_W + $01      
EN_CURRENT_HP       = EN_HITBOX_H + $01
EN_RAM_DAMAGE       = EN_CURRENT_HP + $01    
EN_MOVE_TYPE        = EN_RAM_DAMAGE + $01   
EN_MOVE_PARAM_1     = EN_MOVE_TYPE + $01     
EN_MOVE_PARAM_2     = EN_MOVE_PARAM_1 + $01  
EN_XP_YIELD         = EN_MOVE_PARAM_2 + $01
EN_BULLET_HIGH      = EN_XP_YIELD + $01
EN_BULLET_LOW       = EN_BULLET_HIGH + $01
EN_BULLET_X_OFF     = EN_BULLET_LOW + $01
EN_BULLET_Y_OFF     = EN_BULLET_X_OFF + $01
EN_SHOOT_FREQ       = EN_BULLET_Y_OFF + $01    
EN_SHOOT_TIMER      = EN_SHOOT_FREQ + $01    
                    
MOVE_TYPE_LINEAR    = $00  ; linear move type                                             
MOVE_TYPE_SINUS     = $01  ; sinusoidal move type
 
SINUS_SEQ_COUNT     = $08  ; number of sequences in the sinus move type
SINUS_FREQ          = $04  ; how often to update the states in the sinus move type
 
SPIDER_ID           = $00
SPIDER_UP_ID        = $01
SWEEPER_L_ID        = $02
SWEEPER_R_ID        = $03
DRONE_ID            = $04
GUNSHIP_ID          = $05

;;;;;;;;;;;;;;;;;;;;;;
;; ENEMY EXPLOSIONS ;;
;;;;;;;;;;;;;;;;;;;;;;

EN_EXPLOSION_ATT     = $02  ; atts of the enemy explosion
EN_EXPLOSION_TILE_0  = $50  ; tiles
EN_EXPLOSION_TILE_1  = $51
EN_EXPLOSION_TILE_2  = $60
EN_EXPLOSION_TILE_3  = $61
EN_EXPLOSION_END     = $5C  ; last tile # for the first sprite
EN_EXPLOSION_TIMER   = $03  ; how quick the enemy explosion animation is

SH_EXPLOSION_ATT     = $02  ; atts of the ship explosion
SH_EXPLOSION_TILE_0  = $70  ; tiles
SH_EXPLOSION_TILE_1  = $71
SH_EXPLOSION_TILE_2  = $72
SH_EXPLOSION_TILE_3  = $80
SH_EXPLOSION_TILE_4  = $81
SH_EXPLOSION_TILE_5  = $82
SH_EXPLOSION_TILE_6  = $90
SH_EXPLOSION_TILE_7  = $91
SH_EXPLOSION_TILE_8  = $92
SH_EXPLOSION_END     = $7C  ; last tile # for the first sprite
SH_EXPLOSION_TIMER   = $05  ; how quick the ship explosion animation is

B_EXPLOSION_ATT      = $02  ; atts of the bullet explosion
B_EXPLOSION_TILE     = $A0  ; first tile of the bullet explosion
B_EXPLOSION_END      = $A6  ; last tile of the bullet explosion
B_EXPLOSION_TIMER    = $02  ; how quick the bullet explosion animation is

;;;;;;;;;;;
;; SOUND ;;
;;;;;;;;;;;

SONG_NONE          = $01
SONG_TITLE         = $02
SONG_GAME          = $03

  .include "sound\ggsound\ggsound.inc"