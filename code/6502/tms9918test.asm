!to "tms9918test.o", plain

!source "hbc56.asm"

!source "gfx/tms9918.asm"
!source "gfx/fonts/tms9918font1.asm"

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

main:
        lda #0

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

loop:

	jsr delay
        +tmsSpritePos 0, 42, 40
        +tmsSpritePos 1, 58, 40
        +tmsSpritePos 2, 82, 60
        +tmsSpritePos 3, 98, 60
	jsr delay
        +tmsSpritePos 0, 44, 40
        +tmsSpritePos 1, 60, 40
        +tmsSpritePos 2, 84, 60
        +tmsSpritePos 3, 100, 60
	jsr delay
        +tmsSpritePos 0, 46, 40
        +tmsSpritePos 1, 62, 40
        +tmsSpritePos 2, 86, 60
        +tmsSpritePos 3, 102, 60
	jsr delay
        +tmsSpritePos 0, 48, 40
        +tmsSpritePos 1, 64, 40
        +tmsSpritePos 2, 88, 60
        +tmsSpritePos 3, 104, 60
	jsr delay
        +tmsSpritePos 0, 50, 40
        +tmsSpritePos 1, 66, 40
        +tmsSpritePos 2, 88, 70
        +tmsSpritePos 3, 104, 70

        +tmsPrint ' ', 1, 23

	jsr delay
        +tmsSpritePos 0, 48, 40
        +tmsSpritePos 1, 64, 40
        +tmsSpritePos 2, 86, 70
        +tmsSpritePos 3, 102, 70
	jsr delay
        +tmsSpritePos 0, 46, 40
        +tmsSpritePos 1, 62, 40
        +tmsSpritePos 2, 84, 70
        +tmsSpritePos 3, 100, 70
	jsr delay
        +tmsSpritePos 0, 44, 40
        +tmsSpritePos 1, 60, 40
        +tmsSpritePos 2, 82, 70
        +tmsSpritePos 3, 98, 70
	jsr delay
        +tmsSpritePos 0, 42, 40
        +tmsSpritePos 1, 58, 40
        +tmsSpritePos 2, 80, 70
        +tmsSpritePos 3, 96, 70
	jsr delay
        +tmsSpritePos 0, 40, 40
        +tmsSpritePos 1, 56, 40
        +tmsSpritePos 2, 80, 60
        +tmsSpritePos 3, 96, 60


        +tmsPrint 127, 1, 23

        jmp loop

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
        
        sta TMS9918_RAM
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
