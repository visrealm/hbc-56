; Troy's HBC-56 - TMS9918 Text mode test
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;

!src "hbc56kernel.inc"

XPOS = $44
YPOS = $45


hbc56Meta:
        +setHbcMetaTitle "TMS9918 TXT MODE"
        rts

hbc56Main:
        sei

        jsr tmsModeText
        +tmsColorFgBg TMS_BLACK, TMS_CYAN

        +tmsSetAddrNameTable
        +tmsSendData TEXT, 40*24

        +tmsEnableOutput
        +tmsDisableInterrupts

	lda #16
	sta YPOS

        cli

loop:
        ldy YPOS
        iny
        sty YPOS
	tya
        ldx #7
        jsr tmsSetRegister

        ;jsr medDelay

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
