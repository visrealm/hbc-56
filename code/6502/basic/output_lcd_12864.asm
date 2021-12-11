; Troy's HBC-56 - BASIC - Output (128x64 Graphics LCD)
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;


LCD_MODEL        = 12864                ; 128x64 graphics LCD
LCD_BUFFER_ADDR  = $7d00                ; temp buffer for copies

TILE_OFFSET = $e3

!src "lcd/lcd.asm"                      ; lcd library
!align 255, 0
c64FontData:
	!bin "lcd/fonts/c64-font-ascii.bin"

!source "gfx/tilemap.asm"

; -----------------------------------------------------------------------------
; hbc56SetupDisplay - Setup the display (LCD)
; -----------------------------------------------------------------------------
hbc56SetupDisplay:
	jsr lcdInit
	jsr lcdHome
	jsr lcdClear
	jsr lcdGraphicsMode

	+tilemapCreateDefault (TILEMAP_SIZE_X_16 | TILEMAP_SIZE_Y_8), c64FontData
        
        jsr tilemapRender

        lda #0
        sta TILE_OFFSET
        rts

; -----------------------------------------------------------------------------
; hbc56Out - EhBASIC output subroutine (for HBC-56 LCD)
; -----------------------------------------------------------------------------
; Inputs:       A - ASCII character (or code) to output
; Outputs:      A - must be maintained
; -----------------------------------------------------------------------------
hbc56Out:
        sei     ; disable interrupts during output
        stx SAVE_X
        sty SAVE_Y
        sta SAVE_A
        cmp #ASCII_RETURN
        beq .newline
        cmp #ASCII_BACKSPACE
        beq .backspace

        cmp #ASCII_CR   ; omit these
        beq .endOut

        ; regular character
        ldy TILE_OFFSET
        sta (TILEMAP_TMP_BUFFER_ADDR), y
        inc TILE_OFFSET
        jsr checkTileOffset


.endOut:
        ; just render this row
        lda TILE_OFFSET
        lsr
        lsr
        lsr
        lsr
        tay
        jsr tilemapRender;Row

        ldx SAVE_X
        ldy SAVE_Y
        lda SAVE_A
        cli
        rts


.newline
        lda TILE_OFFSET
        clc
        adc #16
        and #$F0
        sta TILE_OFFSET
        jsr checkTileOffset
        jmp .endOut

.backspace
        dec TILE_OFFSET
        ldy TILE_OFFSET
        lda #' '
        sta (TILEMAP_TMP_BUFFER_ADDR), y
        jmp .endOut
	rts

checkTileOffset:
        lda TILE_OFFSET
        cmp #128
        bcc .offsetOk

        ; scroll
        ldx #0
        ldy #16
-
        lda (TILEMAP_TMP_BUFFER_ADDR), y
        sta TILEMAP_DEFAULT_BUFFER_ADDRESS, x
        inx
        iny
        cpy #128
        bne -
        lda #128-16
        sta TILE_OFFSET

        ; clear the last row
        +memset TILEMAP_DEFAULT_BUFFER_ADDRESS + 128 - 16, ' ', 16

        jsr tilemapRender

.offsetOk
        rts