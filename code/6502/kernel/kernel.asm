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

TMS_MODEL = 9918

RTI_OPCODE = $40
JMP_OPCODE = $4c

!src "hbc56.asm"

*=$f000

+hbc56Title "github.com/visrealm/hbc-56"

!src "ut/bcd.asm"
!src "ut/memory.asm"

!src "inp/keyboard.asm"

!src "gfx/tms9918.asm"

!src "bootscreen.asm"
!src "memtest.asm"

kernelMain:
        cld     ; make sure we're not in decimal mode
        ldx #$ff
        txs

        lda #RTI_OPCODE
        sta HBC56_INT_VECTOR
        sta HBC56_NMI_VECTOR

        sei
        jsr kbInit
        !ifdef tmsInit { jsr tmsInit }
        !ifdef lcdInit { jsr lcdInit }

        jsr hbc56BootScreen

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

        +tmsPrintZ HBC56_PRESS_ANY_KEY_TEXT, (32 - HBC56_PRESS_ANY_KEY_TEXT_LEN) / 2, 15

        jsr kbWaitForKey

        cli

        +tmsDisableOutput

        jmp DEFAULT_HBC56_RST_VECTOR
