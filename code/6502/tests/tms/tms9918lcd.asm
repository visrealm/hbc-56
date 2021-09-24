!to "tms9918lcd.o", plain

HBC56_INT_VECTOR = onVSync

!source "hbc56.asm"

!source "gfx/tms9918.asm"
!source "gfx/fonts/tms9918font1.asm"

!source "gfx/bitmap.asm"

LCD_MODEL = 12864
!source "lcd/lcd.asm"

!source "inp/nes.asm"

BUFFER_ADDR = $1000

sprite1:
!byte %00001000
!byte %00000100
!byte %00001111
!byte %00011011
!byte %00111111
!byte %00101111
!byte %00101000
!byte %00000110

sprite2:
!byte %00100000
!byte %01000000
!byte %11100000
!byte %10110000
!byte %11111000
!byte %11101000
!byte %00101000
!byte %11000000

XPOS = $44
YPOS = $45

TICKS_L = $46
TICKS_H = $47


onVSync:
        pha
        lda TICKS_L
        clc
        adc #1
        cmp #60
        bne +
        lda #0
        inc TICKS_H
+  
        sta TICKS_L
        +tmsReadStatus
        pla      
        rti


main:
        jsr lcdDetect
        beq +
	jsr lcdInit
	jsr lcdClear
	jsr lcdGraphicsMode
+

	lda #0
	sta PIX_ADDR_L

        sei
        lda #0
        sta TICKS_L
        sta TICKS_H

        jsr tmsInit

        +tmsPrint "TROY'S HBC-56 BASIC READY", 1, 15
        +tmsPrint ">10 PRINT \"HELLO WORLD!\"", 0, 17
        +tmsPrint ">RUN", 0, 18
        +tmsPrint "HELLO WORLD!", 1, 19
        +tmsPrint "** DONE **", 1, 21
        +tmsPrint ">", 0, 23
        +tmsPrint 127, 1, 23

        lda #40
        sta XPOS
        sta YPOS

        +tmsCreateSpritePattern 0, sprite1
        +tmsCreateSpritePattern 1, sprite2

        +tmsCreateSprite 0, 0, 40, 40, TMS_MAGENTA
        +tmsCreateSprite 1, 1, 56, 40, TMS_MAGENTA
        +tmsCreateSprite 2, 0, 80, 60, TMS_MED_RED
        +tmsCreateSprite 3, 1, 96, 60, TMS_MED_RED

        cli


loop:

	jsr delay
        +tmsSpritePos 0, 42, 40
        +tmsSpritePos 1, 58, 40
        +tmsSpritePos 2, 82, 60
        +tmsSpritePos 3, 98, 60
        jsr outputSeconds
	jsr delay
        +tmsSpritePos 0, 44, 40
        +tmsSpritePos 1, 60, 40
        +tmsSpritePos 2, 84, 60
        +tmsSpritePos 3, 100, 60
        jsr outputSeconds
	jsr delay
        +tmsSpritePos 0, 46, 40
        +tmsSpritePos 1, 62, 40
        +tmsSpritePos 2, 86, 60
        +tmsSpritePos 3, 102, 60
        jsr outputSeconds
	jsr delay
        +tmsSpritePos 0, 48, 40
        +tmsSpritePos 1, 64, 40
        +tmsSpritePos 2, 88, 60
        +tmsSpritePos 3, 104, 60
        jsr outputSeconds
	jsr delay
        +tmsSpritePos 0, 50, 40
        +tmsSpritePos 1, 66, 40
        +tmsSpritePos 2, 88, 70
        +tmsSpritePos 3, 104, 70

        +tmsPrint ' ', 1, 23

        jsr outputSeconds
	jsr delay
        +tmsSpritePos 0, 48, 40
        +tmsSpritePos 1, 64, 40
        +tmsSpritePos 2, 86, 70
        +tmsSpritePos 3, 102, 70
        jsr outputSeconds
	jsr delay
        +tmsSpritePos 0, 46, 40
        +tmsSpritePos 1, 62, 40
        +tmsSpritePos 2, 84, 70
        +tmsSpritePos 3, 100, 70
        jsr outputSeconds
	jsr delay
        +tmsSpritePos 0, 44, 40
        +tmsSpritePos 1, 60, 40
        +tmsSpritePos 2, 82, 70
        +tmsSpritePos 3, 98, 70
        jsr outputSeconds
	jsr delay
        +tmsSpritePos 0, 42, 40
        +tmsSpritePos 1, 58, 40
        +tmsSpritePos 2, 80, 70
        +tmsSpritePos 3, 96, 70
        jsr outputSeconds
	jsr delay
        +tmsSpritePos 0, 40, 40
        +tmsSpritePos 1, 56, 40
        +tmsSpritePos 2, 80, 60
        +tmsSpritePos 3, 96, 60


        +tmsPrint 127, 1, 23

        jmp loop

COLOR = $89
IMG = $8a
LAST_TICKS_H = $8b

outputSeconds:
        sei

        +tmsSetPosWrite 8, 1
        +nesBranchIfNotPressed NES_LEFT, +
        +tmsPut 'L'
+
        +nesBranchIfNotPressed NES_RIGHT, +
        +tmsPut 'R'
+
        +nesBranchIfNotPressed NES_UP, +
        +tmsPut 'U'
+
        +nesBranchIfNotPressed NES_DOWN, +
        +tmsPut 'D'
+
        +nesBranchIfNotPressed NES_SELECT, +
        +tmsPut 'S'
        +tmsPut 'e'
+
        +nesBranchIfNotPressed NES_START, +
        +tmsPut 'S'
        +tmsPut 't'
+
        +nesBranchIfNotPressed NES_B, +
        +tmsPut 'B'
+
        +nesBranchIfNotPressed NES_A, +
        +tmsPut 'A'
+
        +tmsPut ' '
        +tmsPut ' '
        +tmsPut ' '
        +tmsPut ' '
        +tmsPut ' '
        +tmsPut ' '
        +tmsPut ' '
        +tmsPut ' '
        +tmsPut ' '
        +tmsPut ' '

        +tmsSetPosWrite 1, 1
        lda TICKS_H
        jsr tmsHex8  ; calls cli
        sei

        cmp LAST_TICKS_H
        beq .endSec
        sta LAST_TICKS_H

        jsr lcdDetect
        beq .endSec

        inc IMG
        lda IMG
        and #$03
        cmp #3
        bne +        
	lda #>LOGO_IMG
	sta BITMAP_ADDR_H
	jsr lcdImageVflip
        jmp .endSec
+	
        cmp #2
        bne +        
	lda #>ROX_IMG
	sta BITMAP_ADDR_H
	jsr lcdImageVflip
        jmp .endSec
+	
        cmp #1
        bne +        
	lda #>LIV_IMG
	sta BITMAP_ADDR_H
	jsr lcdImageVflip
        jmp .endSec
+	
	lda #>SELFIE_IMG
	sta BITMAP_ADDR_H
	jsr lcdImageVflip
.endSec
        cli
        rts

fillRam:
        ; font table
        lda #<$4000
        sta TMS9918_REG
        lda #>$4000
        sta TMS9918_REG

        lda #$00

	ldx #255
	ldy #64
-
	dex
        tya
        
        +tmsPut 
	bne -
	ldx #255
	dey
	bne -
	rts


medDelay:
	jsr delay
	jsr delay
	jsr delay
	jsr delay


delay:
	ldx #255
	ldy #255
-
	dex
	bne -
	ldx #255
	dey
	bne -
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
