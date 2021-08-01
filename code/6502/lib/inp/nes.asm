; 6502 NES Controllers - HBC-56
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
; Dependencies:
;  - hbc56.asm


; -------------------------
; Constants
; -------------------------
NES_IO_PORT	= $80

; IO Ports
NES_IO_ADDR     = IO_PORT_BASE_ADDRESS | NES_IO_PORT


NES_RIGHT       = %10000000
NES_LEFT        = %01000000
NES_DOWN        = %00100000
NES_UP          = %00010000
NES_START       = %00001000
NES_SELECT      = %00000100
NES_B           = %00000010
NES_A           = %00000001

NES_TMP = R7L

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

; -----------------------------------------------------------------------------
; nesPressed: Is a button pressed?
; -----------------------------------------------------------------------------
; Inputs:
;   A: Button to test
; Outputs:
;   Carry set if pressed, Carry clear if not
nesPressed:
        sta NES_TMP
        lda NES_IO_ADDR
        eor #$ff
        clc
        bit NES_TMP
        beq +
        sec
+
        lda NES_TMP
        rts




