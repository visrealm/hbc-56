; Troy's HBC-56 - LCD graphics tests
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
!src "hbc56kernel.inc"

BUFFER_ADDR = $1000

; -----------------------------------------------------------------------------
; metadata for the HBC-56 kernel
; -----------------------------------------------------------------------------
hbc56Meta:
        +setHbcMetaTitle "GRAPHICS MODE"
        +consoleLCDMode
        rts


LCD_BASIC           = LCD_INITIALIZE
LCD_EXTENDED        = LCD_INITIALIZE | LCD_CMD_12864B_EXTENDED

DISPLAY_MODE  = <(LCD_CMD_DISPLAY | LCD_CMD_DISPLAY_ON) ; | LCD_CMD_DISPLAY_CURSOR | LCD_CMD_DISPLAY_CURSOR_BLINK)


TMP1 	= HBC56_USER_ZP_START
TMP2 	= HBC56_USER_ZP_START + 1
SEED    = HBC56_USER_ZP_START + 2

hbc56Main:

	jsr lcdInit
	jsr lcdClear
	jsr lcdHome

	jsr lcdWait
	lda #LCD_EXTENDED
	sta LCD_CMD

	jsr lcdWait
	lda #LCD_EXTENDED | LCD_CMD_EXT_GRAPHICS_ENABLE
	sta LCD_CMD

start:
	lda #>BUFFER_ADDR
	sta BITMAP_ADDR_H

	
mainLoop:

	jsr bitmapClear
	jsr pixelDemo
	jsr medDelay

	jsr bitmapClear
	jsr lineDemo
	jsr medDelay

	jsr bitmapClear
	lda #64
	sta TMP2
.loop
	jsr randomLineDemo
	dec TMP2
	bne .loop

	jsr medDelay

	jsr bitmapClear
	jsr rectDemo
	jsr medDelay


	jmp mainLoop


ramTest:
	lda #0
	jsr bitmapFill

	jsr lcdImage

	jsr longDelay

	lda #$ff
	jsr bitmapFill

	jsr lcdImage

	jsr longDelay
	
	lda #$aa
	jsr bitmapFill

	jsr lcdImage

	jsr longDelay

	lda #$55
	jsr bitmapFill

	jsr lcdImage

	jsr longDelay
	
	inc BITMAP_ADDR_H	
	


randomLineDemo:
	jsr rand
	lsr
	sta BITMAP_X1
	
	jsr rand
	lsr
	sta BITMAP_X2
	
	jsr rand
	lsr
	lsr
	sta BITMAP_Y1
	
	jsr rand
	lsr
	lsr
	sta BITMAP_Y2
	
	jsr bitmapLine
	
	jsr lcdImage
	rts
	

pixelDemo:
	lda #63
	sta BITMAP_X
	sta BITMAP_Y
-	
	jsr bitmapSetPixel
	
	jsr lcdImage
	
	dec BITMAP_X
	dec BITMAP_Y
	bne -

	lda #63
	sta BITMAP_X
	sta BITMAP_Y
-	
	jsr bitmapClearPixel

	jsr lcdImage
	dec BITMAP_X
	dec BITMAP_Y
	bne -



	lda #63
	sta BITMAP_Y
	clc
	adc #20
	sta BITMAP_X

-	
	jsr bitmapSetPixel
	
	jsr lcdImage
	
	inc BITMAP_X
	dec BITMAP_Y
	bne -

	lda #63
	sta BITMAP_Y
	clc
	adc #20
	sta BITMAP_X
-	
	jsr bitmapClearPixel

	jsr lcdImage
	inc BITMAP_X
	dec BITMAP_Y
	bne -


	rts


rectDemo:
	lda #$cc
	sta BITMAP_LINE_STYLE
	lda #$33
	sta BITMAP_LINE_STYLE_ODD

	lda #30
	sta TMP1

-	
	lda #31
	sec
	sbc TMP1
	sta BITMAP_X1
	sta BITMAP_Y1
	lda TMP1
	clc
	adc #96	
	sta BITMAP_X2
	lda TMP1
	clc
	adc #32	
	sta BITMAP_Y2
	
	jsr bitmapRect
	
	jsr lcdImage
	
	;jsr medDelay
	
	dec TMP1
	dec TMP1
	bne -

	lda #0
	sta TMP1

-	
	lda #31
	sec
	sbc TMP1
	sta BITMAP_X1
	sta BITMAP_Y1
	lda TMP1
	clc
	adc #96	
	sta BITMAP_X2
	lda TMP1
	clc
	adc #32
	sta BITMAP_Y2
	
	jsr bitmapFilledRect
	
	jsr lcdImage
	
	;jsr medDelay
	
	inc TMP1
	inc TMP1
	lda TMP1
	cmp #30
	bne -

	rts

lineDemo:

	lda #62
	sta TMP1

-	
	lda #1
	sta BITMAP_X1
	lda #126
	sta BITMAP_X2
	lda TMP1
	sta BITMAP_Y
	
	jsr bitmapLineH
	
	jsr lcdImage
	
	dec TMP1
	dec TMP1
	bne -

	lda #126
	sta TMP1

-	
	lda #1
	sta BITMAP_Y1
	lda #62
	sta BITMAP_Y2
	lda TMP1
	sta BITMAP_X
	
	jsr bitmapLineV
	
	jsr lcdImage
	
	dec TMP1
	dec TMP1
	bne -
	rts


longDelay:
	jsr hbc56Delay
	jsr hbc56Delay
	jsr hbc56Delay
	jsr hbc56Delay
	jsr hbc56Delay
	jsr hbc56Delay
	jsr hbc56Delay
	; flow through

medDelay:
	jsr hbc56Delay
	jsr hbc56Delay

rand:
    lda SEED
    beq doEor
    clc
    asl
    beq noEor    ;if the input was $80, skip the EOR
    bcc noEor
doEor
	eor #$1d
noEor
	sta SEED
	rts
