; 6502 KB Controller Macros - HBC-56
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
; Dependencies:
;  - hbc56.asm


!macro kbBranchIfNotPressed .scancode, .addr {
        ldx #.scancode
        jsr kbReadAscii
        beq .addr
}

!macro kbBranchIfPressed .scancode, .addr {
        ldx #.scancode
        jsr kbIsPressed
        bne .addr
}

!macro kbSetEventHandlerPressed .cb {
        lda #<.cb
        sta KB_CB_PRESSED
        lda #>.cb
        sta KB_CB_PRESSED + 1
}

!macro kbSetEventHandlerReleased .cb {
        lda #<.cb
        sta KB_CB_RELEASED
        lda #>.cb
        sta KB_CB_RELEASED + 1
}