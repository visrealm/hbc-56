!to "tms9918txttest.o", plain

HBC56_INT_VECTOR = onVSync

!source "../../lib/hbc56.asm"
!source "../../lib/gfx/fonts/tms9918font2subset.asm"
!source "../../lib/gfx/tms9918.asm"


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
        sei
        lda #0
        sta TICKS_L
        sta TICKS_H
        sta YPOS

        jsr tmsInit

        lda #TMS_R0_MODE_TEXT
        jsr tmsReg0SetFields

        lda #TMS_R1_MODE_TEXT
        jsr tmsReg1SetFields

        +tmsColorFgBg TMS_BLACK, TMS_CYAN

        +tmsSetAddrNameTable
        +tmsSendData TEXT, 40*24

        cli

loop:
        lda YPOS
        clc
        adc #1
        sta YPOS
        ldx #7
        jsr tmsSetRegister

        jsr medDelay

        jmp loop

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

customDelay:
	ldx #255
-
	dex
	bne -
	ldx #255
	dey
	bne -
	rts

TEXT:
!text "----- TROY'S HBC-56 TEXT MODE TEST -----"
!text "                                        "
!text "                                        "
!text "                                        "
!text "               ****                     "
!text "               ****                     "
!text "               ******.**                "
!text "          *******_///_***               "
!text "          **** /_//_/ ***               "
!text "           * ** (__/ ***                "
!text "              *********                 "
!text "               ****                     "
!text "               ***                      "        
!text "                                        "
!text "                                        "
!text "                                        "
!text "       TEXAS INSTRUMENTS TMS9918A       "
!text "                                        "
!text "         vrEmuTms9918 Emulator          "
!text "                                        "
!text "                                        "
!text "                                        "
!text "                                        "
!text "https://github.com/visrealm/vrEmuTms9918"
