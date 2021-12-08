; 6502 - HBC-56 - Memory tests
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
;

;!src "gfx/tms9918macros.asm"

HBC56_BORDER     = TMS_DK_BLUE 
HBC56_BACKGROUND = TMS_DK_BLUE
HBC56_LOGO       = TMS_WHITE 
HBC56_TEXT       = TMS_WHITE

!ifdef HBC56_TITLE_TEXT {
HBC56_TITLE     = HBC56_TITLE_TEXT
HBC56_TITLE_LEN = HBC56_TITLE_TEXT_LEN
}

HBC56_PRESS_ANY_KEY_TEXT:
        !text "PRESS ANY KEY..."
HBC56_PRESS_ANY_KEY_TEXT_LEN = * - HBC56_PRESS_ANY_KEY_TEXT
        !byte 0 ; nul terminator for game name


hbc56BootScreen:
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
        +tmsPrintZ HBC56_TITLE, (32 - HBC56_TITLE_LEN) / 2, 23
}

        +tmsColorFgBg TMS_GREY, HBC56_BORDER
        jsr tmsSetBackground

        rts


hbc56LogoInd:
!bin "hbc56boot.ind"
hbc56LogoPatt:
!bin "hbc56boot.patt"
hbc56LogoPattEnd: