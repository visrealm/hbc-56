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
        lda #HBC56_CONSOLE_FLAG_NES
        ora HBC56_CONSOLE_FLAGS
        sta HBC56_CONSOLE_FLAGS
}

!macro hbc56SetVsyncCallback .vsync {
        lda #<.vsync
        sta HBC56_VSYNC_CALLBACK
        lda #>.vsync
        sta HBC56_VSYNC_CALLBACK + 1
}

!macro setHbcMetaTitle .titleStr {
        jmp .hbcMetaTitleOut
.titleStrLabel:
        !text .titleStr
.titleStrLabelLen = * - .titleStrLabel
        !byte 0 ; nul terminator for game name

!if .titleStrLabelLen > HBC56_META_TITLE_MAX_LEN {
        !error "setHbcMetaTitle: Title metadata limited to ",HBC56_META_TITLE_MAX_LEN,"bytes"
}
.hbcMetaTitleOut:
        +memcpy HBC56_META_TITLE + (HBC56_META_TITLE_MAX_LEN-.titleStrLabelLen)/2, .titleStrLabel, .titleStrLabelLen
        lda #.titleStrLabelLen
        sta HBC56_META_TITLE_LEN
}

!macro consoleEnableCursor {
        lda HBC56_CONSOLE_FLAGS
        ora #HBC56_CONSOLE_FLAG_CURSOR
        sta HBC56_CONSOLE_FLAGS
}

!macro consoleDisableCursor {
        lda HBC56_CONSOLE_FLAGS
        and #!HBC56_CONSOLE_FLAG_CURSOR & $ff
        sta HBC56_CONSOLE_FLAGS
}

!macro consoleLCDMode {
        lda HBC56_CONSOLE_FLAGS
        ora #HBC56_CONSOLE_FLAG_LCD
        sta HBC56_CONSOLE_FLAGS
}

!macro setBreakpoint {
       !byte $db 
}

!macro hbc56CustomDelay .delay {
        ldy #.delay
        jsr hbc56CustomDelay
}