!to "lcd12864text.o", plain

!source "hbc56.asm"

LCD_BUFFER_ADDR = $0200
LCD_MODEL = 12864
!source "lcd/lcd.asm"

main:

	jsr lcdInit
	jsr lcdHome
	jsr lcdClear
	jsr lcdDisplayOn

start:

	jsr lcdClear
        +lcdPrint "LCD Text Test"
        
        lda #0
-
	jsr lcdScrollUp
        +lcdChar '0'
        +lcdChar 'x'
        jsr lcdHex8

        +lcdChar ' '
        +lcdChar ' '
        jsr lcdInt8

        clc
        adc #1
        jmp -

jmp start

        