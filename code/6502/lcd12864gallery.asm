!to "lcd12864gallery.o", plain

!source "hbc56.asm"
!source "lcd/lcd.asm"
!source "lcd/lcd12864b.asm"

LCD_INITIALIZE      = LCD_CMD_FUNCTIONSET | LCD_CMD_8BITMODE | LCD_CMD_2LINE
LCD_BASIC           = LCD_INITIALIZE
LCD_EXTENDED        = LCD_INITIALIZE | LCD_CMD_12864B_EXTENDED

DISPLAY_MODE  = <(LCD_CMD_DISPLAY | LCD_CMD_DISPLAY_ON) ; | LCD_CMD_DISPLAY_CURSOR | LCD_CMD_DISPLAY_CURSOR_BLINK)

main:

	jsr lcdWait
	lda #LCD_INITIALIZE
	sta LCD_CMD

	jsr lcdWait
	lda #LCD_CMD_CLEAR
	sta LCD_CMD

	jsr lcdWait
	lda #LCD_CMD_HOME
	sta LCD_CMD

	jsr lcdWait
	lda #LCD_EXTENDED
	sta LCD_CMD

	jsr lcdWait
	lda #LCD_EXTENDED | LCD_CMD_EXT_GRAPHICS_ENABLE
	sta LCD_CMD

start:

	lda #0
	sta PIX_ADDR_L
	


mainLoop:
	lda #>LOGO_IMG
	sta IMG_ADDR_H
	jsr lcdImage
	
	jsr longDelay

	lda #>ROX_IMG
	sta IMG_ADDR_H
	jsr lcdImage
	
	jsr longDelay
	
	lda #>LIV_IMG
	sta IMG_ADDR_H
	jsr lcdImage
	
	jsr longDelay

	lda #>SELFIE_IMG
	sta IMG_ADDR_H
	jsr lcdImage
	
	jsr longDelay
	
	jmp mainLoop


longDelay:
	jsr delay
	jsr delay
	jsr delay
	jsr delay
	jsr delay
	jsr delay
	jsr delay
	jsr delay
	jsr delay
	; flow through


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
	
;IMG_DATA_OFFSET = 62  ; Paint
IMG_DATA_OFFSET = 130  ; GIMP

!align 255, 0
!fill 256 - IMG_DATA_OFFSET

livData:
	!bin "liv.bmp"

LIV_IMG = livData + IMG_DATA_OFFSET


!align 255, 0
!fill 256 - IMG_DATA_OFFSET

logoData:
	!bin "logo.bmp"

LOGO_IMG = logoData + IMG_DATA_OFFSET


!align 255, 0
!fill 256 - IMG_DATA_OFFSET

roxData:
	!bin "rox.bmp"

ROX_IMG = roxData + IMG_DATA_OFFSET


!align 255, 0
!fill 256 - IMG_DATA_OFFSET

selfieData:
	!bin "selfie.bmp"

SELFIE_IMG = selfieData + IMG_DATA_OFFSET
