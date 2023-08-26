; Troy's HBC-56 - VIA Test
;
; Tests VIA timer, VIA I/O (PORTA) and tests configurable RAM/ROM banks
;
; Copyright (c) 2022 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;


!src "hbc56kernel.inc"

MS_L = HBC56_USER_ZP_START
MS_H = MS_L + 1

MS_COUNT = MS_H + 1



hbc56Meta:
        +setHbcMetaTitle "VIA TEST"
        rts

hbc56Main:

        +memcpy $8000, $8000, $1000

        jsr audioInit

        lda #$01
        sta IO_PORT_BASE_ADDRESS | ROM_BANK_REG        

        lda #VIA_DIR_OUTPUT
        sta VIA_IO_ADDR_DDR_A

        lda #$40
        sta  VIA_IO_ADDR_ACR

        lda #$c0
        sta  VIA_IO_ADDR_IER

        lda #$aa
        sta VIA_IO_ADDR_PORT_A

        stz MS_L
        stz MS_H
        stz MS_COUNT

        lda #$84
        sta VIA_IO_ADDR_T1C_L
        lda #$03
        sta VIA_IO_ADDR_T1C_H


        lda #$aa
        sta selfmod-1
        lda #0

        lda #$01
selfmod:
        sta $8fff
        lda $8fff

value:
        sta VIA_IO_ADDR_PORT_A

        +hbc56SetViaCallback timerHandler

        cli

        jmp hbc56Stop


timerHandler:
        bit VIA_IO_ADDR_T1C_L

        inc MS_L
        bne +
        inc MS_H
+

        inc MS_COUNT
        lda MS_COUNT
        cmp #255
        bne .doneInput
        +nes1BranchIfNotPressed NES_LEFT, +
        jsr rotateLeft
+
        +nes1BranchIfNotPressed NES_RIGHT, +
        jsr rotateRight
+
        +nes1BranchIfNotPressed NES_A, +
        jsr audioJumpInit
+
        +nes1BranchIfNotPressed NES_B, +
        jsr audioJumpStop
+
        +nes1BranchIfNotPressed NES_SELECT, +
        jsr audioEnvTest
+
        stz MS_COUNT

.doneInput:

        jsr audioJumpTick

        rts


rotateLeft:
        asl VIA_IO_ADDR_PORT_A
        bcc +
        inc VIA_IO_ADDR_PORT_A
+        
        rts

rotateRight:
        lsr VIA_IO_ADDR_PORT_A
        bcc +
        lda #$80
        ora VIA_IO_ADDR_PORT_A
        sta VIA_IO_ADDR_PORT_A
+        
        rts


!src "audio.asm"
