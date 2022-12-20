; 6502 - HBC-56 Kernel
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
;

HBC56_INT_VECTOR = $7e00
HBC56_NMI_VECTOR = $7e04
HBC56_RST_VECTOR = kernelMain

HBC56_KERNEL_START = $e000
HBC56_META_VECTOR  = HBC56_KERNEL_START-4

RTI_OPCODE = $40
JMP_OPCODE = $4c

; -------------------------
; I/O devices
; -------------------------
LCD_IO_PORT             = $02
TMS9918_IO_PORT         = $10
UART_IO_PORT            = $20
AY_IO_PORT              = $40
KB_IO_PORT              = $80
NES_IO_PORT             = $82
INT_IO_PORT             = $df
VIA_IO_PORT             = $f0
ROM_BANK_REG            = $08

; -------------------------
; Kernel Zero Page
; -------------------------
HBC56_KERNEL_ZP_START   = $18

TILEMAP_ZP_START        = HBC56_KERNEL_ZP_START
TILEMAP_ZP_END          = TILEMAP_ZP_START + 6

BITMAP_ZP_START         = TILEMAP_ZP_END
BITMAP_ZP_END           = BITMAP_ZP_START + 6

!ifdef HBC56_DISABLE_TMS9918 { .TMS_ZP_SIZE = 0 } else { .TMS_ZP_SIZE = 4 }
TMS9918_ZP_START        = BITMAP_ZP_END
TMS9918_ZP_END          = TMS9918_ZP_START + .TMS_ZP_SIZE

!ifdef HBC56_DISABLE_LCD { .LCD_ZP_SIZE = 0 } else { .LCD_ZP_SIZE = 2 }
LCD_ZP_START            = TMS9918_ZP_END
LCD_ZP_END              = LCD_ZP_START + .LCD_ZP_SIZE

!ifdef HBC56_DISABLE_UART { .UART_ZP_SIZE = 0 } else { .UART_ZP_SIZE = 4 }
UART_ZP_START            = LCD_ZP_END
UART_ZP_END              = UART_ZP_START + .UART_ZP_SIZE

MEMORY_ZP_START         = UART_ZP_END
MEMORY_ZP_END           = MEMORY_ZP_START + 6

STR_ADDR                = MEMORY_ZP_END
STR_ADDR_L              = MEMORY_ZP_END
STR_ADDR_H              = MEMORY_ZP_END + 1

DELAY_L                 = STR_ADDR_H + 1
DELAY_H                 = DELAY_L + 1

HBC56_KERNEL_ZP_END     = DELAY_H + 1
HBC56_USER_ZP_START     = HBC56_KERNEL_ZP_END

;!warn "Total ZP used: ",STR_ADDR_H-HBC56_KERNEL_ZP_START


!ifndef HAVE_TMS9918 { HBC56_DISABLE_SFXMAN=1 }

; -------------------------
; Kernel RAM
; -------------------------
HBC56_KERNEL_RAM_START  = $7a00

TILEMAP_RAM_START       = HBC56_KERNEL_RAM_START
TILEMAP_RAM_END         = TILEMAP_RAM_START + $116

BITMAP_RAM_START        = TILEMAP_RAM_END
BITMAP_RAM_END          = BITMAP_RAM_START + 16

!ifdef HBC56_DISABLE_TMS9918 { .TMS_RAM_SIZE = 0 } else { .TMS_RAM_SIZE = 50 }
TMS9918_RAM_START       = BITMAP_RAM_END
TMS9918_RAM_END         = TMS9918_RAM_START + .TMS_RAM_SIZE

!ifdef HBC56_DISABLE_LCD { .LCD_RAM_SIZE = 0 } else { .LCD_RAM_SIZE = 42 }
LCD_RAM_START           = TMS9918_RAM_END
LCD_RAM_END             = LCD_RAM_START + .LCD_RAM_SIZE

!ifdef HBC56_DISABLE_UART { .UART_RAM_SIZE = 0 } else { .UART_RAM_SIZE = 256 }
UART_RAM_START            = LCD_RAM_END
UART_RAM_END              = UART_RAM_START + .UART_RAM_SIZE

VIA_RAM_START             = UART_RAM_END
VIA_RAM_END               = VIA_RAM_START + 1

!ifdef HBC56_DISABLE_SFXMAN { .SFXMAN_RAM_SIZE = 0 } else { .SFXMAN_RAM_SIZE = 18 }
SFXMAN_RAM_START        = VIA_RAM_END
SFXMAN_RAM_END          = SFXMAN_RAM_START + .SFXMAN_RAM_SIZE

BCD_RAM_START           = SFXMAN_RAM_END
BCD_RAM_END             = BCD_RAM_START + 3

KB_RAM_START            = BCD_RAM_END
KB_RAM_END              = KB_RAM_START + 64

NES_RAM_START            = KB_RAM_END
NES_RAM_END              = NES_RAM_START + 3

LAST_MODULE_RAM_END     = NES_RAM_END

HBC56_TICKS             = LAST_MODULE_RAM_END
HBC56_SECONDS_L         = LAST_MODULE_RAM_END + 1
HBC56_SECONDS_H         = LAST_MODULE_RAM_END + 2
HBC56_TMP               = LAST_MODULE_RAM_END + 3

HBC56_CONSOLE_FLAGS     = LAST_MODULE_RAM_END + 4
HBC56_CONSOLE_FLAG_CURSOR = $80
HBC56_CONSOLE_FLAG_NES    = $40
HBC56_CONSOLE_FLAG_LCD    = $20
HBC56_CONSOLE_FLAG_NOWAIT = $10

HBC56_TMP_X             = LAST_MODULE_RAM_END + 5
HBC56_TMP_Y             = LAST_MODULE_RAM_END + 6

HBC56_META_TITLE_MAX_LEN = 16
HBC56_META_TITLE        = LAST_MODULE_RAM_END + 7
HBC56_META_TITLE_END    = HBC56_META_TITLE + HBC56_META_TITLE_MAX_LEN + 1
HBC56_META_TITLE_LEN    = HBC56_META_TITLE_END + 1

; callback function on vsync
HBC56_VSYNC_CALLBACK = HBC56_META_TITLE_LEN + 1
HBC56_VIA_CALLBACK   = HBC56_VSYNC_CALLBACK + 2


HBC56_KERNEL_RAM_END    = HBC56_VIA_CALLBACK + 2
HBC56_KERNEL_RAM_SIZE   = HBC56_KERNEL_RAM_END - HBC56_KERNEL_RAM_START
;!warn "Total RAM used: ",HBC56_KERNEL_RAM_SIZE

!src "hbc56.asm"
*=HBC56_KERNEL_START

!src "ut/ascii.asm"
!src "ut/bcd.asm"
!src "ut/memory.asm"
!src "ut/tables.asm"

!ifndef HBC56_DISABLE_AY3891X {
        !src "sfx/ay3891x.asm"
}

!ifndef HBC56_DISABLE_TMS9918 {
        !ifndef TMS_MODEL { TMS_MODEL = 9918 }
        !src "gfx/tms9918.asm"
}

!ifndef HBC56_DISABLE_SFXMAN {
        !src "sfx/sfxman.asm"
}

!ifndef HBC56_DISABLE_LCD {
        !ifndef LCD_MODEL { LCD_MODEL = 12864 }
        !src "gfx/bitmap.asm"
        !src "lcd/lcd.asm"
        !src "gfx/tilemap.asm"
}

!ifndef HBC56_DISABLE_UART {
        !src "ser/uart.asm"
}

!ifndef HBC56_DISABLE_NES {
        !src "inp/nes.asm"
}

!ifndef HBC56_DISABLE_KEYBOARD {
        !src "inp/keyboard.asm"
}

!src "io/via.asm"

+hbc56Title "github.com/visrealm/hbc-56"

!src "bootscreen.asm"
!src "kernel.inc"
!src "interrupts.asm"

; -----------------------------------------------------------------------------
; HBC-56 Main entry point (reset vector)
; -----------------------------------------------------------------------------
kernelMain:
        sei
        cld     ; make sure we're not in decimal mode
        ldx #$ff
        txs
        
        lda #RTI_OPCODE
        sta HBC56_INT_VECTOR
        sta HBC56_NMI_VECTOR

        +memset HBC56_META_TITLE, ' ', HBC56_META_TITLE_MAX_LEN

        lda #0
        sta HBC56_TICKS
        sta HBC56_SECONDS_L
        sta HBC56_SECONDS_H
        sta HBC56_CONSOLE_FLAGS

        sta HBC56_META_TITLE + HBC56_META_TITLE_MAX_LEN


        jsr HBC56_META_VECTOR   ; user program metadata

        !ifdef HAVE_KEYBOARD {
                jsr kbInit
        }

        !ifdef HAVE_AY3891X {
                jsr ayInit
        }

        !ifdef HAVE_SFXMAN {
                jsr sfxManInit  ; requires TMS interrupts
        }

        !ifdef HAVE_TMS9918 {
                jsr tmsInit

                +tmsDisableOutput

                ; dummy callback
                +hbc56SetVsyncCallback .nullCallbackFunction
        }

        +hbc56SetViaCallback .nullCallbackFunction

        !ifdef HAVE_LCD {
                jsr lcdDetect
                bcc @noLcd1                
                jsr lcdInit
                jsr hbc56Delay
                jsr lcdDisplayOn
                jsr hbc56Delay
@noLcd1:
        }

        jsr hbc56BootScreen

        +setIntHandler hbc56IntHandler

        !ifdef HAVE_TMS9918 {
                +tmsEnableOutput
                +tmsDisableInterrupts
        }

        lda #20
        sta HBC56_TMP
-
        jsr hbc56Delay
        dec HBC56_TMP
        bne -
       
        !ifdef HAVE_TMS9918 {
                +tmsEnableInterrupts
        }
        cli

        jsr hbc56HighBell

        lda #HBC56_CONSOLE_FLAG_NOWAIT
        bit HBC56_CONSOLE_FLAGS
        bne .afterInput

        lda #HBC56_CONSOLE_FLAG_NES
        and HBC56_CONSOLE_FLAGS
        beq .keyboardInput


        ; NES input
        sei
        !ifdef HAVE_TMS9918 {
                +tmsPrintZ .HBC56_PRESS_ANY_NES_TEXT, (32 - .HBC56_PRESS_ANY_NES_TEXT_LEN) / 2, 17
        }

        !ifdef HAVE_LCD {
                jsr lcdDetect
                bcc @noLcd2
                !ifdef HAVE_GRAPHICS_LCD {
                        +memcpy TILEMAP_DEFAULT_BUFFER_ADDRESS + 16*6, .HBC56_PRESS_ANY_NES_TEXT, 16
                        ldy #6
                        jsr tilemapRenderRowToLcd
                } else {
                        lda #<.HBC56_PRESS_ANY_NES_TEXT
                        sta STR_ADDR_L
                        lda #>.HBC56_PRESS_ANY_NES_TEXT
                        sta STR_ADDR_H
                        jsr lcdPrint
                }
@noLcd2:
        }
        cli
        jsr nesWaitForPress
        jmp .afterInput

.keyboardInput
!ifdef HAVE_KEYBOARD {
        ; Keyboard  input
        sei
        !ifdef HAVE_TMS9918 {
                +tmsPrintZ .HBC56_PRESS_ANY_KEY_TEXT, (32 - .HBC56_PRESS_ANY_KEY_TEXT_LEN) / 2, 17
        }

        !ifdef HAVE_LCD {
                jsr lcdDetect
                bcc @noLcd3
                !ifdef HAVE_GRAPHICS_LCD {
                        +memcpy TILEMAP_DEFAULT_BUFFER_ADDRESS + 16*6, .HBC56_PRESS_ANY_KEY_TEXT, 16
                        ldy #6
                        jsr tilemapRenderRowToLcd
                } else {
                        lda #<.HBC56_PRESS_ANY_KEY_TEXT
                        sta STR_ADDR_L
                        lda #>.HBC56_PRESS_ANY_KEY_TEXT
                        sta STR_ADDR_H
                        jsr lcdPrint        
                }
@noLcd3:
        }
        cli
        jsr kbWaitForScancode
}

.afterInput

        !ifdef HAVE_LCD {
                ;jsr lcdDetect
                ;bcc @noLcd4
                jsr lcdInit
                !ifdef HAVE_GRAPHICS_LCD {
                        jsr lcdTextMode
                }
                jsr lcdClear
                jsr lcdHome
@noLcd4:
        }

        !ifdef HAVE_TMS9918 {
                jsr tmsInitTextTable ; clear output
                +tmsDisableOutput
                +tmsDisableInterrupts
        }
        ; no interrupts until the user code says so
        sei

        jsr DEFAULT_HBC56_RST_VECTOR

; -----------------------------------------------------------------------------
; Beep (higher tone)
; -----------------------------------------------------------------------------
hbc56HighBell:
        !ifdef HAVE_AY3891X {
                +ayToneEnable AY_PSG0, AY_CHC
                +aySetVolume AY_PSG0, AY_CHC, $ff
                +ayPlayNote AY_PSG0, AY_CHC, NOTE_FREQ_F5
        }
        bra .noteTimeout

; -----------------------------------------------------------------------------
; Beep (lower tone)
; -----------------------------------------------------------------------------
hbc56Bell:
        !ifdef HAVE_AY3891X {
                +ayToneEnable AY_PSG0, AY_CHC
                +aySetVolume AY_PSG0, AY_CHC, $ff
                +ayPlayNote AY_PSG0, AY_CHC, NOTE_FREQ_E3
        }
        bra .noteTimeout

.noteTimeout
        !ifdef HAVE_SFXMAN {
                lda HBC56_CONSOLE_FLAGS
                and #HBC56_CONSOLE_FLAG_LCD
                bne @skipSfxMan
                +sfxManSetChannelTimeout  AY_PSG0, AY_CHC, 0.16
                rts
        }
@skipSfxMan
        !ifdef HAVE_AY3891X {
                jsr hbc56Delay
                jsr hbc56Delay
                +ayStop AY_PSG0, AY_CHC
        }

        rts

; -----------------------------------------------------------------------------
; Software reset
; -----------------------------------------------------------------------------
hbc56Reset:
        jmp kernelMain

; -----------------------------------------------------------------------------
; Stop (loop forever)
; -----------------------------------------------------------------------------
hbc56Stop:
        wai
        jmp hbc56Stop

; -----------------------------------------------------------------------------
; Delay function
; -----------------------------------------------------------------------------
hbc56CustomDelayMs:
        inc DELAY_H
-
        ldy #3
        jsr hbc56CustomDelay
	dec DELAY_L
	bne -
	lda #0
        sta DELAY_L
	dec DELAY_H
	bne -
	rts


;!warn "Kernel size: ", *-$f000
;!warn "Bytes remaining: ", DEFAULT_HBC56_INT_VECTOR-*