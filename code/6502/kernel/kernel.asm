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

HBC56_META_VECTOR = $eff0

TMS_MODEL = 9918

RTI_OPCODE = $40
JMP_OPCODE = $4c

!src "hbc56.asm"

*=$f000

+hbc56Title "github.com/visrealm/hbc-56"

!src "ut/bcd.asm"
!src "ut/memory.asm"

!src "inp/nes.asm"
!src "inp/keyboard.asm"

!src "gfx/tms9918.asm"

!src "kernel_macros.asm"

!src "bootscreen.asm"
!src "memtest.asm"

HBC56_TICKS         = $7e80
HBC56_SECONDS_L     = HBC56_TICKS + 1
HBC56_SECONDS_H     = HBC56_SECONDS_L + 1

HBC56_CONSOLE_FLAGS = HBC56_SECONDS_H + 1
HBC56_CONSOLE_FLAG_CURSOR = $80
HBC56_CONSOLE_FLAG_NES    = $40
HBC56_CONSOLE_FLAG_LCD    = $20

HBC56_TMP_X     = HBC56_CONSOLE_FLAGS + 1
HBC56_TMP_Y     = HBC56_CONSOLE_FLAGS + 2

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
        bit HBC56_CONSOLE_FLAGS
        bpl ++
        stx HBC56_TMP_X
        sty HBC56_TMP_Y
        jsr tmsSetPosConsole
        ldx HBC56_TMP_X
        ldy HBC56_TMP_Y
        lda HBC56_TICKS
        cmp #30
        bcc +
        lda #' '
        +tmsPut
        jmp ++
+ 
        lda #$7f
        +tmsPut
++
        +tmsReadStatus
        pla      
        rti


kernelMain:
        cld     ; make sure we're not in decimal mode
        ldx #$ff
        txs

        lda #RTI_OPCODE
        sta HBC56_INT_VECTOR
        sta HBC56_NMI_VECTOR

        lda #0
        sta HBC56_TICKS
        sta HBC56_SECONDS_L
        sta HBC56_SECONDS_H
        sta HBC56_CONSOLE_FLAGS

        sei
        jsr kbInit
        !ifdef tmsInit { jsr tmsInit }
        !ifdef lcdInit { jsr lcdInit }

        jsr hbc56BootScreen

        jsr HBC56_META_VECTOR   ; user program metadata

        +tmsEnableOutput

        jsr hbc56Delay
        jsr hbc56Delay
        jsr hbc56Delay
        jsr hbc56Delay
        jsr hbc56Delay
        jsr hbc56Delay
        jsr hbc56Delay
        jsr hbc56Delay
        jsr hbc56Delay
        jsr hbc56Delay
        jsr hbc56Delay
        jsr hbc56Delay
        jsr hbc56Delay
        jsr hbc56Delay
        jsr hbc56Delay
        jsr hbc56Delay
        jsr hbc56Delay
        jsr hbc56Delay
        jsr hbc56Delay
        jsr hbc56Delay
        jsr hbc56Delay
        jsr hbc56Delay

        lda HBC56_CONSOLE_FLAG_LCD
        bit HBC56_CONSOLE_FLAGS
        bne .afterInput         ; LCD - skip input
        bvc .keyboardInput

        ; NES input
        +tmsPrintZ HBC56_PRESS_ANY_NES_TEXT, (32 - HBC56_PRESS_ANY_NES_TEXT_LEN) / 2, 15
        jsr nesWaitForPress
        jmp .afterInput

.keyboardInput
        ; Keyboard  input
        +tmsPrintZ HBC56_PRESS_ANY_KEY_TEXT, (32 - HBC56_PRESS_ANY_KEY_TEXT_LEN) / 2, 15
        jsr kbWaitForKey

.afterInput

        cli

        +tmsDisableOutput

        +setIntHandler onVSync

        jmp DEFAULT_HBC56_RST_VECTOR
