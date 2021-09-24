; 6502 - HBC-56
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
;

!cpu 6502
!initmem $FF
cputype = $6502

DEFAULT_HBC56_NMI_VECTOR = $FFF0
DEFAULT_HBC56_INT_VECTOR = $FFF0

HBC56_BORDER     = TMS_LT_BLUE 
HBC56_BACKGROUND = TMS_LT_BLUE
HBC56_LOGO       = TMS_WHITE 
HBC56_TEXT       = TMS_WHITE

!macro hbc56Title .title {
HBC56_TITLE_TEXT:
        !text .title
HBC56_TITLE_TEXT_LEN = * - HBC56_TITLE_TEXT
        !byte 0 ; nul terminator for game name
}

!ifdef HBC56_TITLE_TEXT {
HBC56_TITLE     = HBC56_TITLE_TEXT
HBC56_TITLE_LEN = HBC56_TITLE_TEXT_LEN
}

*=$F800
!ifdef tmsInit {
hbc56BootScreen:
        +tmsColorFgBg TMS_GREY, HBC56_BORDER
        jsr tmsSetBackground
        +tmsColorFgBg HBC56_LOGO, HBC56_BACKGROUND
        jsr tmsInitEntireColorTable
        +tmsColorFgBg HBC56_TEXT, HBC56_BACKGROUND
        ldx #16
        jsr tmsInitColorTable

        +tmsSetPosWrite 5,5
        +tmsSendData hbc56LogoInd, 22
        +tmsSetPosWrite 5,6
        +tmsSendData hbc56LogoInd + 22, 22
        +tmsSetPosWrite 5,7
        +tmsSendData hbc56LogoInd + 44, 22

        +tmsSetAddrPattTableInd 200
        +tmsSendData hbc56LogoPatt, $178

!ifdef HBC56_TITLE_TEXT {
        +tmsPrintZ HBC56_TITLE, (32 - HBC56_TITLE_LEN) / 2, 15
}

!ifndef HBC56_SKIP_POST {
        jsr checkRAM
}
        lda #8
        sta $00
-
        jsr hbc56Delay
        dec $00
        bne -

!ifndef HBC56_SKIP_POST {
        jsr checkVRAM
}

        lda #8
        sta $00
-
        jsr hbc56Delay
        dec $00
        bne -

        +tmsPrintCentre "PRESS START...", 23

.waitForInput        
        +nesBranchIfNotPressed NES_START, .waitForInput

        ; Disable the display
        lda #TMS_R1_DISP_ACTIVE
        jsr tmsReg1ClearFields

        jmp main

checkRAM:
        +tmsPrint "Checking RAM...", 6, 11

        lda #2
        sta $00
        lda #2
        sta $01
        ldy #0
.nextByte
        +tmsSetPosWrite 24, 11
.nextByte2
        lda $00
        jsr tmsHex8

        lda #$55
        sta ($00), y
        lda #00
        lda ($00), y
        cmp #$55
        bne .error
        lda #$aa
        sta ($00), y
        lda #00
        lda ($00), y
        cmp #$aa
        lda #00
        sta ($00), y
        +inc16 $00
        lda $00
        cmp #<IO_PORT_BASE_ADDRESS
        bne .nextByte
        +tmsSetPosWrite 22, 11
        lda $01
        jsr tmsHex8
        lda $01
        cmp #>IO_PORT_BASE_ADDRESS
        bne .nextByte2

        +tmsPrint "PASS", 22, 11
        rts


.error:
        jsr hbc56Delay
        jsr hbc56Delay
        jsr hbc56Delay
        jsr hbc56Delay
        jmp .nextByte

checkVRAM:
        +tmsPrint "Checking VRAM...", 6, 12

        lda #$00
        sta TMS_TMP_ADDRESS
        sta TMS_TMP_ADDRESS + 1

.nextVByte
        +tmsSetPosWrite 24, 12
        lda TMS_TMP_ADDRESS
        jsr tmsHex8

        jsr tmsSetAddressRead
        +tmsGet
        ;!byte $DB
        pha
        jsr tmsSetAddressWrite
        +tmsPut $aa
        jsr tmsSetAddressRead
        +tmsGet
        cmp #$aa
        bne .errorV
.backFromErrorV        
        jsr tmsSetAddressWrite
        pla
        +tmsPut

        +inc16 TMS_TMP_ADDRESS
        lda TMS_TMP_ADDRESS
        cmp #$00
        bne .nextVByte
        +tmsSetPosWrite 22, 12
        lda TMS_TMP_ADDRESS + 1
        jsr tmsHex8
        lda TMS_TMP_ADDRESS + 1
        cmp #$40
        bne .nextVByte

        +tmsPrint "PASS", 22, 12
        rts


.errorV:
        jsr hbc56Delay
        jsr hbc56Delay
        jsr hbc56Delay
        jsr hbc56Delay
        jmp .backFromErrorV

hbc56Delay:
	ldy #0
hbc56DCustomDelay:
	ldx #0
-
	dex
	bne -
	ldx #0
	dey
	bne -
	rts

hbc56LogoInd:
!bin "../lib/hbc56.ind"
hbc56LogoPatt:
!bin "../lib/hbc56.patt"
hbc56LogoPattEnd:
}

*=$FF00
hbc56Init:
        cld     ; make sure we're not in decimal mode
        ldx #$ff
        txs

        sei
        !ifdef tmsInit { jsr tmsInit }
        !ifdef lcdInit { jsr lcdInit }

        !ifdef tmsInit {
        +tmsDisableInterrupts

                jmp hbc56BootScreen
        }

        cli

        ; Disable the display
        lda #TMS_R1_DISP_ACTIVE
        jsr tmsReg1ClearFields
        
        jmp main



*=$FFF0
        rti

*=$FFFA
!ifdef HBC56_NMI_VECTOR { !word HBC56_NMI_VECTOR } else { !word DEFAULT_HBC56_NMI_VECTOR }
!word hbc56Init
!ifdef HBC56_INT_VECTOR { !word HBC56_INT_VECTOR } else { !word DEFAULT_HBC56_INT_VECTOR }
*=$8000

; Base address of the 256 IO port memory range
IO_PORT_BASE_ADDRESS	= $7f00

; Virtual registers
; ----------------------------------------------------------------------------
R0  = $02
R0L = R0
R0H = R0 + 1
R1  = $04
R1L = R1
R1H = R1 + 1
R2  = $06
R2L = R2
R2H = R2 + 1
R3  = $08
R3L = R3
R3H = R3 + 1
R4  = $0a
R4L = R4
R4H = R4 + 1
R5  = $0c
R5L = R5
R5H = R5 + 1
R6  = $0e
R6L = R6
R6H = R6 + 1
R7  = $10
R7L = R7
R7H = R7 + 1
R8  = $12
R8L = R8
R8H = R8 + 1
R9  = $14
R9L = R9
R9H = R9 + 1
R10  = $16
R10L = R10
R10H = R10 + 1


; -------------------------
; Zero page
; -------------------------
STR_ADDR = $20
STR_ADDR_L = STR_ADDR
STR_ADDR_H = STR_ADDR + 1

