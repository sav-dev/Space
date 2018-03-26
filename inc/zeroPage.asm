  .rsset $0000

;;;;;;;;;;;;;;
;; POINTERS ;;
;;;;;;;;;;;;;;
  
;; NMI
drawPointerLow   .rs 1  ; low byte of the draw pointer
drawPointerHigh  .rs 1  ; high byte of the draw pointer

;; GENERIC NON-NMI
bufferLow        .rs 1  ; low byte of current buffer address
bufferHigh       .rs 1  ; high byte of current buffer address

;; BACKGROUNDS
bgTargetRowLow   .rs 1  ; low byte of new row address
bgTargetRowHigh  .rs 1  ; high byte of new row address
bgSourceRowLow   .rs 1  ; low byte of source for row data
bgSourceRowHigh  .rs 1  ; high byte of source for row data
bgLevelLow       .rs 1  ; low byte of the level data address. Once set shouldn't be modified for the remainder of the level.
bgLevelHigh      .rs 1  ; high byte of the level data address. Once set shouldn't be modified for the remainder of the level.
ntLow            .rs 1  ; low byte of nametable address (used for loading static background)
ntHigh           .rs 1  ; low byte of nametable address (used for loading static background) 

;; ENEMIES
enLevelLow       .rs 1  ; low byte of enemy data address. Once set shouldn't be modified for the remainder of the level.
enLevelHigh      .rs 1  ; high byte of enemy data address. Once set shouldn't be modified for the remainder of the level.
enScreenLow      .rs 1  ; low byte of enemy on screen data address. Updated when screen changes.
enScreenHigh     .rs 1  ; high byte of enemy on screen data address. Updated when screen changes.
enemyLow         .rs 1  ; low byte of the actual particular eneny data address
enemyHigh        .rs 1  ; hifh byte of the actual particular eneny data address

;; SHIP
bulletLow        .rs 1  ; low byte of currently loaded weapon
bulletHigh       .rs 1  ; high byte of currently loaded weapon

;; ENEMIES
enBulletLow      .rs 1  ; low byte of enemies weapon
enBulletHigh     .rs 1  ; high byte of enemies weapon

;; PALETTES
paletteLow       .rs 1  ; low byte of the palette data
paletteHigh      .rs 1  ; high byte of the palette data

;; STRINGS
stringLow        .rs 1  ; low byte of the string data
stringHigh       .rs 1  ; high byte of the string data

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; NMI / MAIN THREAD COORDINATION ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

soft2000            .rs 1  ; buffering $2000 writes
soft2001            .rs 1  ; buffering $2001 writes
needDma             .rs 1  ; nonzero if NMI should perform sprite DMA
needDraw            .rs 1  ; nonzero if NMI needs to do drawing from the buffer
needPpuReg          .rs 1  ; nonzero if NMI should update $2000/$2001/$2005
sleeping            .rs 1  ; nonzero if main thread is waiting for VBlank
                    
;;;;;;;;;;;;;;;;;;     
;; PLACEHOLDERS ;;       
;;;;;;;;;;;;;;;;;;     
                    
placeholder1        .rs 1  ; used to temporarily store values. Cannot be used by NMI.
placeholder2        .rs 1
placeholder3        .rs 1
placeholder4        .rs 1
placeholder5        .rs 1
placeholder6        .rs 1
placeholder7        .rs 1
placeholder8        .rs 1
placeholder9        .rs 1

;;;;;;;;;;;;;;;;;;;;;;;;
;; COLLISION CEHCKING ;;
;;;;;;;;;;;;;;;;;;;;;;;;

ax1                 .rs 1 ; 1st hitbox
ax2                 .rs 1 
ay1                 .rs 1 
ay2                 .rs 1 
bx1                 .rs 1 ; 2nd hitbox
bx2                 .rs 1 
by1                 .rs 1 
by2                 .rs 1 
collision           .rs 1 ; whether there's a collision
   
;;;;;;;;;;;;;;;;;
;; BACKGROUNDS ;;
;;;;;;;;;;;;;;;;;

scroll              .rs 1  ; vertical scroll
scrollInc           .rs 1  ; used to have slower scroll
scrollSpeed         .rs 1  ; scroll speed, the higher the slower the scroll. Min. value is 1
nametable           .rs 1  ; which nametable should be displayed (0 or 2)
screenNumber        .rs 1  ; which screen is currently being drawn
numberOfScreens     .rs 1  ; number of screens in the current level
endOfLevel          .rs 1  ; whether the scroll made it to the end of the level
bulkDraw            .rs 1  ; if != 0 it means we're doing a bulk draw and should draw directly to PPU
newRow              .rs 1  ; if != 0 it means we've drawn a new row
clearAtts           .rs 1  ; atts to set when clearing a screen

;;;;;;;;;;;;;;;;;
;; CONTROLLERS ;;
;;;;;;;;;;;;;;;;;

controllerDown      .rs 1  ; buttons that are pressed down
controllerPrevious  .rs 1  ; buttons that were pressed down frame before that
controllerPressed   .rs 1  ; buttons that have been pressed since the last frame

;;;;;;;;;;;;;;;;;;;;;;;;;;
;; GAME STATE = PLAYING ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

currentLevel        .rs 1  ; currently loaded level
paused              .rs 1  ; > 0 means game is paused
updateHPBar         .rs 1  ; if > 0 at the end of the loop it means hp bar must be updated
updateXPBar         .rs 1  ; if > 0 at the end of the loop it means xp bar must be updated
shipDestroyed       .rs 1  ; whether the ship is destroyed
continueCounter     .rs 1  ; used to time when to show the continue screen

;;;;;;;;;;;;;;;;
;; SHIP STATE ;;
;;;;;;;;;;;;;;;;

shipHP              .rs 1  ; ship HP
shipXP              .rs 1  ; ship XP
currentWeapon       .rs 1  ; currently equiped weapon

shipDirectionTimer  .rs 1  ; timer used to animate ship changing direction
shipMovement        .rs 1  ; where the ship is currently moving
shipMovementOld     .rs 1  ; ship movement from the previous frame
shipDirection       .rs 1  ; whether the ship is turning or not
shipDrawn           .rs 1  ; == 0 means the ship hasn't been drawn yet
updateShipPosition  .rs 1  ; whether ship position must be updated
updateShipTiles     .rs 1  ; whether ship tiles must be updated
updateShipAtts      .rs 1  ; whether ship atts. must be updated
updateExhaust       .rs 1  ; whether to update the exhaust

shipX1Outer         .rs 1  ; ship's hitboxes
shipX2Outer         .rs 1  ; must be updated everytime ship's position is updated
shipY1Outer         .rs 1
shipY2Outer         .rs 1
shipX1Inner1        .rs 1
shipX2Inner1        .rs 1
shipY1Inner1        .rs 1
shipY2Inner1        .rs 1
shipX1Inner2        .rs 1
shipX2Inner2        .rs 1
shipY1Inner2        .rs 1
shipY2Inner2        .rs 1

shipXCenter         .rs 1  ; ship's center coordinates
shipYCenter         .rs 1 

shipExplTimer       .rs 1  ; ship explosion timer

exhaustTimer        .rs 1  ; exhaust timer
exhaustCurrentTile  .rs 1  ; animation tile to set
exhaustNextTile     .rs 1  ; next animation tile

;;;;;;;;;;;
;; SOUND ;;
;;;;;;;;;;;

  ; .rs 56
  .include "sound\ggsound\ggsound_zp.inc"