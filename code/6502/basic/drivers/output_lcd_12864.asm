; Troy's HBC-56 - BASIC - Output (128x64 Graphics LCD)
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;


TILE_OFFSET = HBC56_USER_ZP_START + 3

!align 255, 0
c64FontData:
	!bin "lcd/fonts/c64-font-ascii.bin"

onVsync:
        lda HBC56_TICKS
        beq .doCursor
        cmp #30
        beq .doCursor
        rts

.doCursor:
        lda HBC56_TICKS
        beq +
        lda #' '
        jmp ++
+ 
        lda #$ff
++

        sty HBC56_TMP_Y
        ldy TILE_OFFSET
        sta TILEMAP_DEFAULT_BUFFER_ADDRESS, y
        ldy HBC56_TMP_Y
        jsr tilemapRender

        rts

; -----------------------------------------------------------------------------
; hbc56SetupDisplay - Setup the display (LCD)
; -----------------------------------------------------------------------------
hbc56SetupDisplay:

        sei

	jsr lcdInit
	jsr lcdClear
	jsr lcdGraphicsMode

	+tilemapCreateDefault (TILEMAP_SIZE_X_16 | TILEMAP_SIZE_Y_8), c64FontData

        lda #0
        sta TILE_OFFSET

!ifdef tmsInit {
        +hbc56SetVsyncCallback onVsync
        +tmsEnableInterrupts
}

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

        cmp #ASCII_BELL ; bell (end of buffer)
        beq .bellOut

        cmp #ASCII_CR   ; omit these
        beq .endOut

        ; regular character
        ldy TILE_OFFSET
        sta TILEMAP_DEFAULT_BUFFER_ADDRESS, y
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
        jsr tilemapRenderRow
        ldx SAVE_X
        ldy SAVE_Y
        lda SAVE_A
        cli
        rts

.bellOut
        jsr hbc56Bell
        jmp .endOut

.newline
        lda #' '
        ldy TILE_OFFSET
        sta TILEMAP_DEFAULT_BUFFER_ADDRESS, y
        ; just render this row
        lda TILE_OFFSET
        lsr
        lsr
        lsr
        lsr
        tay
        jsr tilemapRender

        lda TILE_OFFSET
        clc
        adc #16
        and #$F0
        sta TILE_OFFSET
        jsr checkTileOffset
        jmp .endOut

.backspace
        lda #' '
        ldy TILE_OFFSET
        sta TILEMAP_DEFAULT_BUFFER_ADDRESS, y
        dec TILE_OFFSET
        ldy TILE_OFFSET
        lda #' '
        sta TILEMAP_DEFAULT_BUFFER_ADDRESS, y
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
        lda TILEMAP_DEFAULT_BUFFER_ADDRESS, y
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