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


!macro kbBranchIfNotPressed .buttonMask, addr {
        jsr kbReadAscii
        cmp #.buttonMask
        bne addr
}
