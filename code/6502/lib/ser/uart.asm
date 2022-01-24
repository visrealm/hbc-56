; 6502 - MC68B50 UART
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;

!src "hbc56.inc"

HAVE_UART = 1

; -------------------------
; Constants
; -------------------------
!ifndef UART_IO_PORT { UART_IO_PORT = $20
        !warn "UART_IO_PORT not provided. Defaulting to ", UART_IO_PORT
}

!ifndef UART_ZP_START { UART_ZP_START = $40
        !warn "UART_ZP_START not provided. Defaulting to ", UART_ZP_START
}

!ifndef UART_RAM_START { UART_RAM_START = $7c80
        !warn "UART_RAM_START not provided. Defaulting to ", UART_RAM_START
}


; -----------------------------------------------------------------------------
; Zero page
; -----------------------------------------------------------------------------
UART_ZP_SIZE         = 0

; -----------------------------------------------------------------------------
; High RAM
; -----------------------------------------------------------------------------
UART_RAM_SIZE        = 0


; IO Ports
UART_REG      = IO_PORT_BASE_ADDRESS | UART_IO_PORT
UART_DATA     = IO_PORT_BASE_ADDRESS | UART_IO_PORT | $01

; -----------------------------------------------------------------------------
; Constants
; -----------------------------------------------------------------------------
UART_CTL_MASTER_RESET       = %00000011
UART_CTL_CLOCK_DIV_16       = %00000001
UART_CTL_CLOCK_DIV_64       = %00000011
UART_CTL_WORD_7BIT_EPB_2SB  = %00000000
UART_CTL_WORD_7BIT_OPB_2SB  = %00000100
UART_CTL_WORD_7BIT_EPB_1SB  = %00001000
UART_CTL_WORD_7BIT_OPB_1SB  = %00001100
UART_CTL_WORD_8BIT_2SB      = %00010000
UART_CTL_WORD_8BIT_1SB      = %00010100
UART_CTL_WORD_8BIT_EPAR_1SB = %00011000
UART_CTL_WORD_8BIT_OPAR_1SB = %00011100
UART_CTL_RX_INT_ENABLE      = %10000000

UART_STATUS_RX_REG_FULL     = %00000001
UART_STATUS_TX_REG_EMPTY    = %00000010
UART_STATUS_CARRIER_DETECT  = %00000100
UART_STATUS_CLEAR_TO_SEND   = %00001000
UART_STATUS_FRAMING_ERROR   = %00010000
UART_STATUS_RCVR_OVERRUN    = %00100000
UART_STATUS_PARITY_ERROR    = %01000000
UART_STATUS_IRQ             = %10000000

; -----------------------------------------------------------------------------
; uartInit: Initialise the UART
; -----------------------------------------------------------------------------
uartInit:
        lda #UART_CTL_MASTER_RESET
        sta UART_REG
        nop
        nop

        lda #(UART_CTL_CLOCK_DIV_16 | UART_CTL_WORD_8BIT_1SB)
        sta UART_REG
        nop
        nop
        rts


; -----------------------------------------------------------------------------
; uartOut: Output a byte to the UART
; -----------------------------------------------------------------------------
; Inputs:
;   A: Value to output
; -----------------------------------------------------------------------------
uartOut:
        pha
        lda #UART_STATUS_TX_REG_EMPTY

@aciaTestSend
        bit UART_REG
        beq @aciaDelay

        pla
        pha
        cmp #$08        ; bs
        bne +
        lda #$7f        ; del
+
        sta UART_DATA
        pla
        rts

@aciaDelay
        nop
        nop
        jmp @aciaTestSend


; -----------------------------------------------------------------------------
; uartInWait: Input a byte from the UART (wait forever)
; -----------------------------------------------------------------------------
; Outputs:
;   A: Value of the buffer
; -----------------------------------------------------------------------------
uartInWait:
        jsr uartInNoWait
        bcc uartInWait
        rts

; -----------------------------------------------------------------------------
; uartInNoWait: Input a byte from the UART (don't wait)
; -----------------------------------------------------------------------------
; Outputs:
;   A: Value of the buffer
;   C: Set if a key is read
; -----------------------------------------------------------------------------
uartInNoWait:
        lda #UART_STATUS_RX_REG_FULL
        bit UART_REG
        bne +
        clc
        rts
+
        nop
        nop
        lda UART_DATA
        sec
        rts

; -----------------------------------------------------------------------------
; uartOutString: Output a string to the UART
; -----------------------------------------------------------------------------
; Inputs:
;   A: Value to output
; -----------------------------------------------------------------------------
uartOutString:
	ldy #0
-
	lda (STR_ADDR), y
	beq +
        jsr uartOut
	iny
	bne -
+
        rts
