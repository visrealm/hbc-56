; 6502 - HBC-56 - Memory tests
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
;

; can be anywhere. we own the place at this stage
LOGO_BUFFER = $3000     

!ifdef HAVE_TMS9918 {
        HBC56_BORDER     = TMS_DK_BLUE 
        HBC56_BACKGROUND = TMS_DK_BLUE
        HBC56_LOGO       = TMS_WHITE 
        HBC56_TEXT       = TMS_WHITE
}

!ifdef HBC56_TITLE_TEXT {
        HBC56_TITLE     = HBC56_TITLE_TEXT
        HBC56_TITLE_LEN = HBC56_TITLE_TEXT_LEN
}

.HBC56_PRESS_ANY_KEY_TEXT:
        !text "PRESS ANY KEY...",0
.HBC56_PRESS_ANY_KEY_TEXT_LEN = *-.HBC56_PRESS_ANY_KEY_TEXT-1

.HBC56_PRESS_ANY_NES_TEXT:
        !text "PRESS A TO BEGIN...",0
.HBC56_PRESS_ANY_NES_TEXT_LEN = *-.HBC56_PRESS_ANY_NES_TEXT-1

!ifdef HAVE_GRAPHICS_LCD {
        !align 255, 0
hbc56FontLcd:
        !bin "lcd/fonts/c64-alnum.bin"
hbc56LogoLcd:
        !bin "res/hbc56lcd.bin"
}

!ifdef HAVE_TMS9918 {
hbc56LogoInd:
        !bin "res/hbc56boot.ind"
hbc56LogoPatt:
        !bin "res/hbc56boot.patt"
hbc56LogoPattEnd:        
}

hbc56BootScreen:

!ifdef HAVE_TMS9918 {
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

        +tmsPrintZ HBC56_META_TITLE, 8, 15


        !ifdef HBC56_TITLE_TEXT {
                +tmsPrintZ HBC56_TITLE, (32 - HBC56_TITLE_LEN) / 2, 23
        }

        +tmsColorFgBg TMS_GREY, HBC56_BORDER
        jsr tmsSetBackground
}

!ifdef HAVE_LCD {
        jsr lcdDetect
        bcc @noLcd
        !ifdef HAVE_GRAPHICS_LCD {
                jsr lcdGraphicsMode
                +memset LOGO_BUFFER, $00, 1024
                +memcpy LOGO_BUFFER + 128, hbc56LogoLcd, 256
                lda #>LOGO_BUFFER
                sta BITMAP_ADDR_H
                jsr lcdImage

                +memset LOGO_BUFFER, $0, 128
                +tilemapCreateDefault (TILEMAP_SIZE_X_16 | TILEMAP_SIZE_Y_8), hbc56FontLcd-(32*8)
                +memset TILEMAP_DEFAULT_BUFFER_ADDRESS, ' ', 128

                +memcpy TILEMAP_DEFAULT_BUFFER_ADDRESS + 16*6, HBC56_META_TITLE, 16

                ldy #6
                jsr tilemapRenderRowToLcd

        } else {
                !if LCD_ROWS > 2 { +lcdPrint "\n" }
                !if LCD_COLUMNS > 16 { +lcdPrint "  " }
                +lcdPrint "     HBC-56\n"
                !if LCD_COLUMNS > 16 { +lcdPrint "  " }
                lda #<HBC56_META_TITLE
                sta STR_ADDR_L
                lda #>HBC56_META_TITLE
                sta STR_ADDR_H
                !if LCD_ROWS = 2 {
                        jsr lcdLineTwo
                }                
                jsr lcdPrint
                !if LCD_ROWS = 2 {
                        jsr lcdLineTwo
                } else {
                        jsr lcdLineThree
                }                
                !if LCD_COLUMNS > 16 { +lcdConsolePrint "  " }
        }
@noLcd:
}
        rts
