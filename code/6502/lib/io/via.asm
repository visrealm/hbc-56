; 65(C)22 VIA - HBC-56
;
; Copyright (c) 2022 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;


!ifndef VIA_IO_PORT { VIA_IO_PORT = $f0
        !warn "VIA_IO_PORT not provided. Defaulting to ", VIA_IO_PORT
}

!ifndef VIA_RAM_START { VIA_RAM_START = $7d80
        !warn "VIA_RAM_START not provided. Defaulting to ", VIA_RAM_START
}

; -------------------------
; High RAM
; -------------------------
VIA_TMP        = VIA_RAM_START
VIA_RAM_SIZE   = 1


!if VIA_RAM_END < (VIA_RAM_START + VIA_RAM_SIZE) {
	!error "VIA_RAM requires ",VIA_RAM_SIZE," bytes. Allocated ",VIA_RAM_END - VIA_RAM_START
}


VIA_REG_PORT_B  = $00
VIA_REG_PORT_A  = $01
VIA_REG_DDR_B   = $02
VIA_REG_DDR_A   = $03
VIA_REG_T1C_L   = $04
VIA_REG_T1C_H   = $05
VIA_REG_T1L_L   = $06
VIA_REG_T1L_H   = $07
VIA_REG_T2C_L   = $08
VIA_REG_T2C_H   = $09
VIA_REG_ACR     = $0b
VIA_REG_IFR     = $0d
VIA_REG_IER     = $0e

; IO Ports
VIA_IO_ADDR     = IO_PORT_BASE_ADDRESS | VIA_IO_PORT

VIA_IO_ADDR_PORT_B      = VIA_IO_ADDR | VIA_REG_PORT_B
VIA_IO_ADDR_PORT_A      = VIA_IO_ADDR | VIA_REG_PORT_A
VIA_IO_ADDR_DDR_B       = VIA_IO_ADDR | VIA_REG_DDR_B
VIA_IO_ADDR_DDR_A       = VIA_IO_ADDR | VIA_REG_DDR_A
VIA_IO_ADDR_T1C_L       = VIA_IO_ADDR | VIA_REG_T1C_L
VIA_IO_ADDR_T1C_H       = VIA_IO_ADDR | VIA_REG_T1C_H
VIA_IO_ADDR_T1L_L       = VIA_IO_ADDR | VIA_REG_T1L_L
VIA_IO_ADDR_T1L_H       = VIA_IO_ADDR | VIA_REG_T1L_H
VIA_IO_ADDR_T2C_L       = VIA_IO_ADDR | VIA_REG_T2C_L
VIA_IO_ADDR_T2C_H       = VIA_IO_ADDR | VIA_REG_T2C_H
VIA_IO_ADDR_ACR         = VIA_IO_ADDR | VIA_REG_ACR
VIA_IO_ADDR_IFR         = VIA_IO_ADDR | VIA_REG_IFR
VIA_IO_ADDR_IER         = VIA_IO_ADDR | VIA_REG_IER

; Constants
VIA_DIR_INPUT   = $00
VIA_DIR_OUTPUT  = $ff



viaIntHandler:
        jmp (HBC56_VIA_CALLBACK)
