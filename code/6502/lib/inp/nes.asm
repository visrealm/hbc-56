; 6502 NES Controllers - HBC-56
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;


!ifndef NES_IO_PORT { NES_IO_PORT = $82
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
NES1_IO_ADDR     = IO_PORT_BASE_ADDRESS | NES_IO_PORT
NES2_IO_ADDR     = IO_PORT_BASE_ADDRESS | NES_IO_PORT | $01


NES_RIGHT       = %00000001
NES_LEFT        = %00000010
NES_DOWN        = %00000100
NES_UP          = %00001000
NES_START       = %00010000
NES_SELECT      = %00100000
NES_B           = %01000000
NES_A           = %10000000

; -----------------------------------------------------------------------------
; nesWaitForPress: Wait for a NES button press (either port)
; -----------------------------------------------------------------------------
nesWaitForPress:
        lda #$ff
@notPressed
        cmp NES1_IO_ADDR
        bne @pressed
        cmp NES2_IO_ADDR
        beq @notPressed
@pressed
        rts

; -----------------------------------------------------------------------------
; nes1Pressed: Is a button pressed?
; -----------------------------------------------------------------------------
; Inputs:
;   A: Button to test
; Outputs:
;   Carry set if pressed, Carry clear if not
nes1Pressed:
        bit NES1_IO_ADDR
        clc
        bne +
        sec
+
        rts

; -----------------------------------------------------------------------------
; nes2Pressed: Is a button pressed?
; -----------------------------------------------------------------------------
; Inputs:
;   A: Button to test
; Outputs:
;   Carry set if pressed, Carry clear if not
nes2Pressed:
        bit NES2_IO_ADDR
        clc
        bne +
        sec
+
        rts




