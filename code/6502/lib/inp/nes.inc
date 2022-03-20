; 6502 NES Controller Macros - HBC-56
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
; Dependencies:
;  - hbc56.asm


!macro nes1BranchIfPressed .buttonMask, .addr {
        pha
        lda #(.buttonMask)
        jsr nes1Pressed
        pla
        bcs .addr
}

!macro nes1BranchIfNotPressed .buttonMask, .addr {
        pha
        lda #(.buttonMask)
        jsr nes1Pressed
        pla
        bcc .addr
}

!macro nes2BranchIfPressed .buttonMask, addr {
        pha
        lda #(.buttonMask)
        jsr nes2Pressed
        pla
        bcs addr
}

!macro nes2BranchIfNotPressed .buttonMask, addr {
        pha
        lda #(.buttonMask)
        jsr nes2Pressed
        pla
        bcc addr
}
