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
        +div8
        sta HIT_TILE_X
        tax
        
        tya
        and #$07
        sta HIT_TILE_PIX_Y

        tya
        +div8
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



BIT0 = $80
BIT1 = $40
BIT2 = $20
BIT3 = $10
BIT4 = $08
BIT5 = $04
BIT6 = $02
BIT7 = $01

hitTestBits:
!byte  BIT0, BIT1, BIT2, BIT3, BIT4, BIT5, BIT6, BIT7
hitTestMasks:
!byte  !BIT0 & $ff, !BIT1, !BIT2, !BIT3, !BIT4, !BIT5, !BIT6, !BIT7

; -----------------------------------------------------------------------------
; patternHitTest: Test a pattern row for a pixel hit
; -----------------------------------------------------------------------------
; Inputs:
;  A = The row pattern. Pixel bits.
;  HIT_TILE_PIX_X = The offset to check (0 - 7)
; Returns:
;  Zero flag  - set if pixel not hit, clear id pixel hit
; -----------------------------------------------------------------------------
patternHitTest:
        ldx HIT_TILE_PIX_X
        and hitTestBits, x
        rts


; -----------------------------------------------------------------------------
; clearPixel: Clear a pixel at
; -----------------------------------------------------------------------------
; Inputs:
;  HIT_TILE_X, HIT_TILE_Y, HIT_TILE_PIX_X, HIT_TILE_PIX_Y
; -----------------------------------------------------------------------------
tileClearPixel:

        ; Temporary value
        TILE_TMP_PATTERN = GAMEFIELD_TMP

        ; load pattern index at given tile location
        ldx HIT_TILE_X
        ldy HIT_TILE_Y
        jsr tmsSetPosRead
        +tmsGet

        ; load pattern byte for given row
        ldy HIT_TILE_PIX_Y
        jsr tmsSetPatternRead
        +tmsGet
        sta TILE_TMP_PATTERN

        jsr tmsSetAddressWrite ; TMS_TMP_ADDRESS is already set

        ; mask out pixel
        ldx HIT_TILE_PIX_X
        lda TILE_TMP_PATTERN
        and hitTestMasks, x
        +tmsPut
        rts
