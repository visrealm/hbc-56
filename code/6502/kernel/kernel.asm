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

TMS_MODEL = 9918
RTI_OPCODE = $40
JMP_OPCODE = $4c

!ifndef LCD_MODEL {
        LCD_MODEL = 12864
}

; -------------------------
; I/O devices
; -------------------------
LCD_IO_PORT             = $02
TMS9918_IO_PORT         = $10
AY_IO_PORT              = $40
KB_IO_PORT              = $81
NES_IO_PORT             = $81

; -------------------------
; Kernel Zero Page
; -------------------------
HBC56_KERNEL_ZP_START   = $18

TILEMAP_ZP_START = HBC56_KERNEL_ZP_START
TILEMAP_ZP_END  = TILEMAP_ZP_START + 6

BITMAP_ZP_START = TILEMAP_ZP_END
BITMAP_ZP_END   = BITMAP_ZP_START + 6

TMS9918_ZP_START = BITMAP_ZP_END
TMS9918_ZP_END  = TMS9918_ZP_START + 4

LCD_ZP_START    = TMS9918_ZP_END
LCD_ZP_END      = LCD_ZP_START + 2

MEMORY_ZP_START = LCD_ZP_END
MEMORY_ZP_END   = MEMORY_ZP_START + 6

STR_ADDR        = MEMORY_ZP_END
STR_ADDR_L      = MEMORY_ZP_END
STR_ADDR_H      = MEMORY_ZP_END + 1

HBC56_USER_ZP_START   = STR_ADDR_H + 2

;!warn "Total ZP used: ",STR_ADDR_H-HBC56_KERNEL_ZP_START


; -------------------------
; Kernel RAM
; -------------------------
HBC56_KERNEL_RAM_START  = $7800

TILEMAP_RAM_START       = HBC56_KERNEL_RAM_START
TILEMAP_RAM_END         = TILEMAP_RAM_START + $116

BITMAP_RAM_START        = TILEMAP_RAM_END
BITMAP_RAM_END          = BITMAP_RAM_START + 16

TMS9918_RAM_START       = BITMAP_RAM_END
TMS9918_RAM_END         = TMS9918_RAM_START + 50

LCD_RAM_START           = TMS9918_RAM_END
LCD_RAM_END             = LCD_RAM_START + 40

SFXMAN_RAM_START        = LCD_RAM_END
SFXMAN_RAM_END          = SFXMAN_RAM_START + 18

BCD_RAM_START           = SFXMAN_RAM_END
BCD_RAM_END             = BCD_RAM_START + 3

KB_RAM_START            = BCD_RAM_END
KB_RAM_END              = KB_RAM_START + 3

NES_RAM_START            = KB_RAM_END
NES_RAM_END              = NES_RAM_START + 3


LAST_MODULE_RAM_END = NES_RAM_END

HBC56_TICKS         = LAST_MODULE_RAM_END
HBC56_SECONDS_L     = LAST_MODULE_RAM_END + 1
HBC56_SECONDS_H     = LAST_MODULE_RAM_END + 2
HBC56_TMP           = LAST_MODULE_RAM_END + 3

HBC56_CONSOLE_FLAGS = LAST_MODULE_RAM_END + 4
HBC56_CONSOLE_FLAG_CURSOR = $80
HBC56_CONSOLE_FLAG_NES    = $40
HBC56_CONSOLE_FLAG_LCD    = $20

HBC56_TMP_X     = LAST_MODULE_RAM_END + 5
HBC56_TMP_Y     = LAST_MODULE_RAM_END + 6

HBC56_META_TITLE_MAX_LEN = 16
HBC56_META_TITLE         = LAST_MODULE_RAM_END + 7
HBC56_META_TITLE_END     = HBC56_META_TITLE + HBC56_META_TITLE_MAX_LEN + 1
HBC56_META_TITLE_LEN     = HBC56_META_TITLE_END + 1

; callback function on vsync
HBC56_VSYNC_CALLBACK = HBC56_META_TITLE_LEN + 1



;!warn "Total RAM used: ",NES_RAM_END-HBC56_KERNEL_RAM_START

!src "hbc56.asm"
*=HBC56_KERNEL_START

+hbc56Title "github.com/visrealm/hbc-56"

!src "ut/bcd.asm"
!src "ut/memory.asm"
!src "ut/memory.inc"


!src "gfx/tms9918.asm"
!src "sfx/ay3891x.asm"
!src "sfx/sfxman.asm"
!src "gfx/bitmap.asm"
!src "lcd/lcd.asm"
!src "gfx/tilemap.asm"

!src "inp/nes.asm"
!src "inp/keyboard.asm"

!src "bootscreen.asm"

!src "kernel.inc"

.vsyncCallback:
        bit HBC56_CONSOLE_FLAGS
        bpl ++

        lda HBC56_TICKS
        beq .doCursor
        cmp #30
        beq .doCursor
        jmp ++

.doCursor:
        stx HBC56_TMP_X
        sty HBC56_TMP_Y
        jsr tmsSetPosConsole
        ldx HBC56_TMP_X
        ldy HBC56_TMP_Y
        lda HBC56_TICKS
        beq +
        lda #' '
        +tmsPut
        jmp ++
+ 
        lda #$7f
        +tmsPut
++
        jsr sfxManTick

        jmp (HBC56_VSYNC_CALLBACK)

.nullCallbackFunction:
        rts

onVSync:
        pha
        inc HBC56_TICKS
        lda HBC56_TICKS
        cmp #TMS_FPS
        bne +
        lda #0
        sta HBC56_TICKS
        +inc16 HBC56_SECONDS_L
+

        jsr .vsyncCallback

        +tmsReadStatus
        pla      
        rti

consoleEnableCursor:
        +consoleEnableCursor
        rts

consoleDisableCursor:
        +consoleDisableCursor
        rts

hbc56HighBell:
        +ayToneEnable AY_PSG0, AY_CHC
        +aySetVolume AY_PSG0, AY_CHC, $ff
        +ayPlayNote AY_PSG0, AY_CHC, NOTE_F5
        jmp .noteTimeout

hbc56Bell:
        +ayToneEnable AY_PSG0, AY_CHC
        +aySetVolume AY_PSG0, AY_CHC, $ff
        +ayPlayNote AY_PSG0, AY_CHC, NOTE_E3
        jmp .noteTimeout

.noteTimeout
        lda HBC56_CONSOLE_FLAGS
        and #HBC56_CONSOLE_FLAG_LCD
        bne .skipSfxMan
        +sfxManSetChannelTimeout  AY_PSG0, AY_CHC, 0.16
        rts
.skipSfxMan
        jsr hbc56Delay
        jsr hbc56Delay
        +ayStop AY_PSG0, AY_CHC
        rts


kernelMain:
        cld     ; make sure we're not in decimal mode
        ldx #$ff
        txs
        
        sei
        
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

        ; dummy callback
        +hbc56SetVsyncCallback .nullCallbackFunction

        jsr HBC56_META_VECTOR   ; user program metadata

        jsr kbInit
        jsr ayInit
        jsr sfxManInit

        !ifdef tmsInit { jsr tmsInit }
        !ifdef lcdInit { jsr lcdInit }

        jsr lcdDisplayOn
        jsr hbc56BootScreen

        +tmsEnableOutput
        +tmsDisableInterrupts

        lda #20
        sta HBC56_TMP
-
        jsr hbc56Delay
        dec HBC56_TMP
        bne -

        +setIntHandler onVSync
       
        jsr hbc56HighBell
        +tmsEnableInterrupts
        cli

        lda #4
        sta HBC56_TMP
-
        jsr hbc56Delay
        dec HBC56_TMP
        bne -

        lda #HBC56_CONSOLE_FLAG_NES
        and HBC56_CONSOLE_FLAGS
        beq .keyboardInput


        ; NES input
        sei
        +tmsPrintZ HBC56_PRESS_ANY_NES_TEXT, (32 - HBC56_PRESS_ANY_NES_TEXT_LEN) / 2, 15
        +memcpy TILEMAP_DEFAULT_BUFFER_ADDRESS + 16*6, HBC56_PRESS_ANY_NES_TEXT, 16
        ldy #6
        jsr tilemapRenderRow
        cli
        jsr nesWaitForPress
        jmp .afterInput

.keyboardInput
        ; Keyboard  input
        sei
        +tmsPrintZ HBC56_PRESS_ANY_KEY_TEXT, (32 - HBC56_PRESS_ANY_KEY_TEXT_LEN) / 2, 15
        +memcpy TILEMAP_DEFAULT_BUFFER_ADDRESS + 16*6, HBC56_PRESS_ANY_KEY_TEXT, 16
        ldy #6
        jsr tilemapRenderRow
        cli
        jsr kbWaitForKey

.afterInput

        jsr lcdTextMode
        jsr lcdInit
        jsr lcdClear
        jsr lcdHome
        jsr tmsInitTextTable ; clear output
        +tmsDisableOutput
        +tmsDisableInterrupts

        ; no interrupts until the user code says so
        sei

        jsr DEFAULT_HBC56_RST_VECTOR

hbc56Stop:
        jmp hbc56Stop

;!warn "Kernel size: ", *-$f000
;!warn "Bytes remaining: ", DEFAULT_HBC56_INT_VECTOR-*