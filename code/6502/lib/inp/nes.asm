; 6502 NES Controllers - HBC-56
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;


!ifndef NES_IO_PORT { NES_IO_PORT = $81
        !warn "NES_IO_PORT not provided. Defaulting to ", NES_IO_PORT
}

!ifndef NES_RAM_START { NES_RAM_START = $7ea1
        !warn "NES_RAM_START not provided. Defaulting to ", NES_RAM_START
}

; -------------------------
; High RAM
; -------------------------
NES_TMP        = NES_RAM_START
NES_RAM_SIZE   = 1


!if NES_RAM_END < (NES_RAM_START + NES_RAM_SIZE) {
	!error "NES_RAM requires ",NES_RAM_SIZE," bytes. Allocated ",NES_RAM_END - NES_RAM_START
}


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

; -----------------------------------------------------------------------------
; nesWaitForPress: Wait for a NES button press
; -----------------------------------------------------------------------------
nesWaitForPress:
        lda NES_IO_ADDR
        cmp #$ff
        beq nesWaitForPress
        rts

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
        and NES_TMP
        clc
        beq +
        sec
+
        lda NES_TMP
        rts




