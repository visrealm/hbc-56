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
LCD_MODEL = 12864

; -----------------------------------------------------------------------------
; metadata for the HBC-56 kernel
; -----------------------------------------------------------------------------
hbc56Meta:
        +setHbcMetaTitle "GRAPHICS LCD TEST"
        +consoleLCDMode
        rts


LCD_BASIC           = LCD_INITIALIZE
LCD_EXTENDED        = LCD_INITIALIZE | LCD_CMD_12864B_EXTENDED

DISPLAY_MODE  = <(LCD_CMD_DISPLAY | LCD_CMD_DISPLAY_ON) ; | LCD_CMD_DISPLAY_CURSOR | LCD_CMD_DISPLAY_CURSOR_BLINK)

SEED        = $0f

TMP1 = $44

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

	lda #0
	sta PIX_ADDR_L
	
	lda #>BUFFER_ADDR
	sta BITMAP_ADDR_H
	
mainLoop:

	jsr rectDemo

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
	sta TMP1
-	
	lda TMP1
	sta BITMAP_X
	sta BITMAP_Y
	jsr bitmapSetPixel
	
	jsr lcdImage
	;jsr delay
	
	dec TMP1
	bne -

	lda #63
	sta TMP1
-	
	lda TMP1
	sta BITMAP_X
	sta BITMAP_Y
	jsr bitmapClearPixel

	jsr lcdImage
	;jsr delay
	
	dec TMP1
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
	
	jsr medDelay
	
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
	
	jsr medDelay
	
	dec TMP1
	dec TMP1
	bne -
	rts


longDelay:
	jsr delay
	jsr delay
	jsr delay
	jsr delay
	jsr delay
	jsr delay
	jsr delay
	; flow through

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
