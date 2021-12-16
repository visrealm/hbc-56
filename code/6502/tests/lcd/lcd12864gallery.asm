; Troy's HBC-56 - LCD picture gallery
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
!src "hbc56kernel.inc"

BUFFER_ADDR = $1000

TMP1 	= HBC56_KERNEL_RAM_START

; -----------------------------------------------------------------------------
; metadata for the HBC-56 kernel
; -----------------------------------------------------------------------------
hbc56Meta:
        +setHbcMetaTitle "PICTURE GALLERY"
        +consoleLCDMode
        rts

hbc56Main:

	jsr lcdInit
	jsr lcdClear
	jsr lcdGraphicsMode

start:

	lda #0
	sta PIX_ADDR
	


mainLoop:
	lda #>LOGO_IMG
	sta BITMAP_ADDR_H
	jsr lcdImageVflip
	
	jsr longDelay

	lda #>ROX_IMG
	sta BITMAP_ADDR_H
	jsr lcdImageVflip
	
	jsr longDelay
	
	lda #>LIV_IMG
	sta BITMAP_ADDR_H
	jsr lcdImageVflip
	
	jsr longDelay

	lda #>SELFIE_IMG
	sta BITMAP_ADDR_H
	jsr lcdImageVflip
	
	jsr longDelay
	
	jsr rectDemo
	
	jmp mainLoop

rectDemo:

	lda #>BUFFER_ADDR
	sta BITMAP_ADDR_H

	jsr bitmapClear

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



longDelay:
	jsr hbc56Delay
	jsr hbc56Delay
	jsr hbc56Delay
	jsr hbc56Delay
	jsr hbc56Delay
	jsr hbc56Delay
	jsr hbc56Delay
	jsr hbc56Delay

	jmp hbc56Delay

	
;IMG_DATA_OFFSET = 62  ; Paint
IMG_DATA_OFFSET = 130  ; GIMP

!align 255, 0
!fill 256 - IMG_DATA_OFFSET

livData:
	!bin "img/liv.bmp"

LIV_IMG = livData + IMG_DATA_OFFSET


!align 255, 0
!fill 256 - IMG_DATA_OFFSET

logoData:
	!bin "img/logo.bmp"

LOGO_IMG = logoData + IMG_DATA_OFFSET


!align 255, 0
!fill 256 - IMG_DATA_OFFSET

roxData:
	!bin "img/rox.bmp"

ROX_IMG = roxData + IMG_DATA_OFFSET


!align 255, 0
!fill 256 - IMG_DATA_OFFSET

selfieData:
	!bin "img/selfie.bmp"

SELFIE_IMG = selfieData + IMG_DATA_OFFSET
