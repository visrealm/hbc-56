; Troy's HBC-56 - TMS9918 Multicolor mode test
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;

!src "hbc56kernel.inc"

hbc56Meta:
        +setHbcMetaTitle "TMS MULTICOLOR"
        +setHbcMetaNES
        rts

hbc56Main:
        sei

        jsr tmsModeMulticolor

        +tmsColorFgBg TMS_WHITE, TMS_BLACK
        jsr tmsSetBackground

        +tmsSetAddrNameTable
        +tmsSendData TMS_NAME_DATA, $300

        +tmsEnableOutput
        +tmsEnableInterrupts
loop:

        sei
        +tmsSetAddrPattTable
        +tmsSendData TMS_BIRD_DATA, $800
        cli

        jsr medDelay
        jsr medDelay
        jsr medDelay
        jsr medDelay

        sei
        +tmsSetAddrPattTable
        +tmsSendData TMS_PATTERN_DATA, $800
        cli

        jsr medDelay
        jsr medDelay
        jsr medDelay
        jsr medDelay

        jmp loop

medDelay:
	jsr delay
	jsr delay
	jsr delay
	jsr delay


delay:
	ldy #0
customDelay:
	ldx #0
-
	dex
	bne -
	ldx #0
	dey
	bne -
	rts



TMS_NAME_DATA:

!for .y, 0, 23 {
!for .x, 0, 31 {
        !byte .x + ((.y & $fc) << 3)
}
}

TMS_BIRD_DATA:
!bin "bird.bin"

TMS_PATTERN_DATA:
!bin "mcmode.bin"
