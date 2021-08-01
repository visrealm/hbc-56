!to "lcd12864tilemap.o", plain

!source "hbc56.asm"

LCD_BUFFER_ADDR = $0200
LCD_MODEL = 12864
!source "gfx/bitmap.asm"
!source "lcd/lcd.asm"
!source "ut/memory.asm"

!align 255, 0
c64FontData:
	!bin "c64-font-ascii.bin"

!source "gfx/tilemap.asm"




main:

	jsr lcdInit
	jsr lcdHome
	jsr lcdClear
	jsr lcdGraphicsMode

	+tilemapCreateDefault (TILEMAP_SIZE_X_16 | TILEMAP_SIZE_Y_8), c64FontData

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

        jsr tilemapRender

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

