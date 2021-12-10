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


!macro nesBranchIfPressed .buttonMask, addr {
        lda #.buttonMask
        jsr nesPressed
        bcs addr
}

!macro nesBranchIfNotPressed .buttonMask, addr {
        lda #.buttonMask
        jsr nesPressed
        bcc addr
}
