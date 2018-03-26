  .rsset $04CC             ; starts at $04CC because there's some reserved space before (see consts)

;;;;;;;;;;;;;;;;
;; GAME STATE ;;
;;;;;;;;;;;;;;;;

gameState           .rs 1  ; game state

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; GAME STATE != PLAYING ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

startPressed        .rs 1  ; whether start was pressed
blinkTimer          .rs 1  ; blinking timer
showingString       .rs 1  ; whether we're currently showing the "press start" string
selection           .rs 1  ; which option is selected

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; GAME STATE = PASSWORD ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

numberOfChars       .rs 1  ; how many characters have been entered
characters          .rs 4  ; characters entered (with offset)

;;;;;;;;;;;
;; SOUND ;;
;;;;;;;;;;;

currentSong         .rs 1  ; currently playing song

  .include "sound\ggsound\ggsound_ram.inc"