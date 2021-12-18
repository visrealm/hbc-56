; Troy's HBC-56 - LCD Tilemap tests
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;

!src "hbc56kernel.inc"

!align 255, 0
c64FontData:
	!bin "lcd/fonts/c64-font-ascii.bin"

; -----------------------------------------------------------------------------
; metadata for the HBC-56 kernel
; -----------------------------------------------------------------------------
hbc56Meta:
        +setHbcMetaTitle "LCD TILEMAP"
        +consoleLCDMode
        rts

hbc56Main:

	jsr lcdInit
	jsr lcdHome
	jsr lcdClear
	jsr lcdGraphicsMode

	+tilemapCreateDefault (TILEMAP_SIZE_X_16 | TILEMAP_SIZE_Y_8), c64FontData

        +tilemapSetActive TILEMAP_FIXED_ADDRESS

TILE_OFFSET = $c0

        lda #32
        sta TILE_OFFSET

start:

        ldy #0
        clc

-
        tya
        clc
        adc TILE_OFFSET
        sta (TILEMAP_TMP_BUFFER_ADDR), y
        iny
        cpy #128
        bne -

        ;+memcpy TILEMAP_DEFAULT_BUFFER_ADDRESS, screenBuffer, 128

        jsr tilemapRenderToLcd

        inc TILE_OFFSET

        jsr delay
        
        jmp start

medDelay:
	jsr delay
	jsr delay


delay:
	ldx #255
	ldy #255
.loop:
	dex
	bne .loop 
	ldx #255
	dey
	bne .loop
	rts


screenBuffer:
!text "* HBC-56 BASIC *"
!text " 64K RAM SYSTEM "
!text "                "
!text "READY.          "
!text "LOAD *,8,1      "
!text "LOADING...      "
!text "RUN             "

