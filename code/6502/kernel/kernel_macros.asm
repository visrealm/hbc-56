; 6502 - HBC-56 Kernel Macros
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
;

!macro setIntHandler .address {
        lda #<.address
        sta HBC56_INT_VECTOR + 1
        lda #>.address
        sta HBC56_INT_VECTOR + 2
        lda #JMP_OPCODE
        sta HBC56_INT_VECTOR
}

!macro setNmiHandler .address {
        lda #<.address
        sta HBC56_NMI_VECTOR + 1
        lda #>.address
        sta HBC56_NMI_VECTOR + 2
        lda #JMP_OPCODE
        sta HBC56_NMI_VECTOR
}

!macro setHbcMetaNES {
        lda HBC56_CONSOLE_FLAGS
        ora #HBC56_CONSOLE_FLAG_NES
        sta HBC56_CONSOLE_FLAGS
}

!macro setHbcMetaTitle .titleStr {
        jmp .hbcMetaTitleOut
.titleStrLabel:
        !text .titleStr
.titleStrLabelLen = * - .titleStrLabel
        !byte 0 ; nul terminator for game name

.hbcMetaTitleOut:
        +tmsPrintZ .titleStrLabel, (32 - .titleStrLabelLen) / 2, 15
}

!macro consoleEnableCursor {
        lda HBC56_CONSOLE_FLAGS
        ora #HBC56_CONSOLE_FLAG_CURSOR
        sta HBC56_CONSOLE_FLAGS
}

!macro consoleDisableCursor {
        lda HBC56_CONSOLE_FLAGS
        eor #HBC56_CONSOLE_FLAG_CURSOR
        sta HBC56_CONSOLE_FLAGS
}

!macro consoleLCDMode {
        lda HBC56_CONSOLE_FLAGS
        ora #HBC56_CONSOLE_FLAG_LCD
        sta HBC56_CONSOLE_FLAGS
}