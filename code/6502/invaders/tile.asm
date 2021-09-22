; Troy's HBC-56 - 6502 - Tile subroutines
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
;


; -----------------------------------------------------------------------------
; pixelToTileXy: Convert pixel location to tile location and tile pixel
; -----------------------------------------------------------------------------
; Inputs:
;  X/Y indexes as pixel location
; Outputs:
;  TILE in HIT_TILE_X/HIT_TILE_Y (also in X/Y)
;  TILE OFFSET in HIT_TILE_PIX_X/HIT_TILE_PIX_Y
; -----------------------------------------------------------------------------
pixelToTileXy
        txa
        and #$07
        sta HIT_TILE_PIX_X
        
        txa
        lsr
        lsr
        lsr
        sta HIT_TILE_X
        tax
        
        tya
        and #$07
        sta HIT_TILE_PIX_Y

        tya
        lsr
        lsr
        lsr
        sta HIT_TILE_Y
        tay
        rts

; -----------------------------------------------------------------------------
; decTileHitX: Decrement HIT_TILE_PIX_X (also affects HIT_TILE_X on rollover)
; -----------------------------------------------------------------------------
decTileHitX:
        lda HIT_TILE_PIX_X
        beq +
        dec HIT_TILE_PIX_X
        rts
+
        dec HIT_TILE_X
        lda #7
        sta HIT_TILE_PIX_X
        rts

; -----------------------------------------------------------------------------
; incTileHitX: Increment HIT_TILE_PIX_X (also affects HIT_TILE_X on rollover)
; -----------------------------------------------------------------------------
incTileHitX:
        lda HIT_TILE_PIX_X
        cmp #7
        beq +
        inc HIT_TILE_PIX_X
        rts
+
        inc HIT_TILE_X
        lda #0
        sta HIT_TILE_PIX_X
        rts

; -----------------------------------------------------------------------------
; decTileHitY: Decrement HIT_TILE_PIX_Y (also affects HIT_TILE_Y on rollover)
; -----------------------------------------------------------------------------
decTileHitY:
        lda HIT_TILE_PIX_Y
        beq +
        dec HIT_TILE_PIX_Y
        rts
+
        dec HIT_TILE_Y
        lda #7
        sta HIT_TILE_PIX_Y
        rts

; -----------------------------------------------------------------------------
; incTileHitY: Increment HIT_TILE_PIX_Y (also affects HIT_TILE_Y on rollover)
; -----------------------------------------------------------------------------
incTileHitY:
        lda HIT_TILE_PIX_Y
        cmp #7
        beq +
        inc HIT_TILE_PIX_Y
        rts
+
        inc HIT_TILE_Y
        lda #0
        sta HIT_TILE_PIX_Y
        rts
