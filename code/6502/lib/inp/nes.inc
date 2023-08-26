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


;  Safe versions of NES pressed macros (preserves accumulator)

!macro nes1BranchIfPressedSafe .buttonMask, .addr {
        pha
        lda #(.buttonMask)
        jsr nes1Pressed
        pla
        bcs .addr
}

!macro nes1BranchIfNotPressedSafe .buttonMask, .addr {
        pha
        lda #(.buttonMask)
        jsr nes1Pressed
        pla
        bcc .addr
}

!macro nes2BranchIfPressedSafe .buttonMask, addr {
        pha
        lda #(.buttonMask)
        jsr nes2Pressed
        pla
        bcs addr
}

!macro nes2BranchIfNotPressedSafe .buttonMask, addr {
        pha
        lda #(.buttonMask)
        jsr nes2Pressed
        pla
        bcc addr
}

;  NES pressed macros which stomp accumulator

!macro nes1BranchIfPressed .buttonMask, .addr {
        lda #(.buttonMask)
        bit NES1_IO_ADDR
        beq .addr
}

!macro nes1BranchIfNotPressed .buttonMask, .addr {
        lda #(.buttonMask)
        bit NES1_IO_ADDR
        bne .addr
}

!macro nes2BranchIfPressed .buttonMask, addr {
        lda #(.buttonMask)
        bit NES2_IO_ADDR
        beq addr
}

!macro nes2BranchIfNotPressed .buttonMask, addr {
        lda #(.buttonMask)
        bit NES2_IO_ADDR
        bne addr
}
