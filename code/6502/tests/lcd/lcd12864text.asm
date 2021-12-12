!src "hbc56kernel.inc"

LCD_BUFFER_ADDR = $7d00
LCD_MODEL = 12864

!source "gfx/bitmap.asm"
!source "lcd/lcd.asm"


; -----------------------------------------------------------------------------
; metadata for the HBC-56 kernel
; -----------------------------------------------------------------------------
hbc56Meta:
        +setHbcMetaTitle "LCD 12864 TEXT"
        +consoleLCDMode
        rts

hbc56Main:

	jsr lcdInit
	jsr lcdHome
	jsr lcdClear
	jsr lcdDisplayOn

start:

	jsr lcdClear
        +lcdPrint "LCD Text Test\n2nd line too?"
        
        lda #0
-
        pha
	jsr lcdNextLine4
        pla
        +lcdChar '0'
        +lcdChar 'x'
        jsr lcdHex8

        +lcdChar ' '
        +lcdChar ' '
        jsr lcdInt8

        clc
        adc #1

        jsr delay

        jmp -

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
