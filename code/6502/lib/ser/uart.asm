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
UART_RX_BUFFER_HEAD  = UART_ZP_START            ; head of circular buffer
UART_RX_BUFFER_TAIL  = UART_ZP_START + 1        ; tail of circular buffer
UART_RX_BUFFER_BYTES = UART_ZP_START + 2        ; bytes in buffer
UART_RX_FLAGS        = UART_ZP_START + 3        ; flags
@UART_ZP_END         = UART_ZP_START + 4

!if (.UART_ZP_SIZE < @UART_ZP_END - UART_ZP_START) {
        !error "UART ZP allocation insufficient. Allocated: ", .UART_ZP_SIZE, " Require: ", (@UART_ZP_END - UART_ZP_START)
}

; -----------------------------------------------------------------------------
; High RAM
; -----------------------------------------------------------------------------
UART_RX_BUFFER       = UART_RAM_START
UART_RX_BUFFER_SIZE  = $100

@UART_RAM_END        = UART_RAM_START + UART_RX_BUFFER_SIZE

!if (.UART_RAM_SIZE < @UART_RAM_END - UART_RAM_START) {
        !error "UART RAM allocation insufficient. Allocated: ", .UART_RAM_SIZE, " Require: ", (@UART_RAM_END - UART_RAM_START)
}


; IO Ports
UART_REG      = IO_PORT_BASE_ADDRESS | UART_IO_PORT
UART_DATA     = IO_PORT_BASE_ADDRESS | UART_IO_PORT | $01

; -----------------------------------------------------------------------------
; Constants
; -----------------------------------------------------------------------------
UART_CTL_MASTER_RESET       = %00000011
UART_CTL_CLOCK_DIV_16       = %00000001
UART_CTL_CLOCK_DIV_64       = %00000010
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

UART_FLOWCTRL_XON           = $11
UART_FLOWCTRL_XOFF          = $13

UART_RX_BUFFER_XOFF_SIZE    = UART_RX_BUFFER_SIZE - 64
UART_RX_BUFFER_XON_SIZE     = UART_RX_BUFFER_SIZE - 128


; -----------------------------------------------------------------------------
; uartInit: Initialise the UART
; -----------------------------------------------------------------------------
uartInit:
        lda #0
        sta UART_RX_BUFFER_HEAD
        sta UART_RX_BUFFER_TAIL
        sta UART_RX_BUFFER_BYTES
        sta UART_RX_FLAGS

        lda #UART_CTL_MASTER_RESET
        sta UART_REG
        nop
        nop

        lda #(UART_CTL_CLOCK_DIV_64 | UART_CTL_WORD_8BIT_2SB | UART_CTL_RX_INT_ENABLE)
        sta UART_REG
        nop
        nop

        jsr uartFlowCtrlXon

        rts

; -----------------------------------------------------------------------------
; uartIrq: Standard UART IRQ handler
; -----------------------------------------------------------------------------
uartIrq:
        pha
        phx
@testForMoreData
        lda #UART_STATUS_RX_REG_FULL
        bit UART_REG
        beq @flowControlCheck
        lda UART_DATA
        ldx UART_RX_BUFFER_HEAD
        sta UART_RX_BUFFER, x
        inc UART_RX_BUFFER_HEAD
        inc UART_RX_BUFFER_BYTES
        bra @testForMoreData

@flowControlCheck
        ; check flow control
        ;bbs7 UART_RX_FLAGS, @endFlowControlCheck    ; if already xoff, just leave
        ;lda #UART_RX_BUFFER_XOFF_SIZE               ; otherwise, shouild we ask for xoff?
        ;cmp UART_RX_BUFFER_BYTES
        ;bcs @endFlowControlCheck                    ; all good
        ;jsr uartFlowCtrlXoff                        ; stop please.

@endFlowControlCheck
        plx
        pla
        rti

; -----------------------------------------------------------------------------
; uartFlowCtrlXon: Allow client to send data
; -----------------------------------------------------------------------------
uartFlowCtrlXon:
        rmb7 UART_RX_FLAGS
        lda #UART_FLOWCTRL_XON
        jmp uartOut

; -----------------------------------------------------------------------------
; uartFlowCtrlXoff: Stop client to sending data
; -----------------------------------------------------------------------------
uartFlowCtrlXoff
        smb7 UART_RX_FLAGS
        lda #UART_FLOWCTRL_XOFF
        jmp uartOut

; -----------------------------------------------------------------------------
; uartInWait: Input a byte from the UART (wait forever)
; -----------------------------------------------------------------------------
; Outputs:
;   A: Value of the buffer
; -----------------------------------------------------------------------------
uartInWait:
        lda UART_RX_BUFFER_HEAD
        cmp UART_RX_BUFFER_TAIL
        beq uartInWait
        bra .readUartValue

; -----------------------------------------------------------------------------
; uartInNoWait: Input a byte from the UART (don't wait)
; -----------------------------------------------------------------------------
; Outputs:
;   A: Value of the buffer
;   C: Set if a key is read
; -----------------------------------------------------------------------------
uartInNoWait:
        lda UART_RX_BUFFER_HEAD
        cmp UART_RX_BUFFER_TAIL
        beq @noData

.readUartValue
        ldx UART_RX_BUFFER_TAIL
        lda UART_RX_BUFFER, x
        inc UART_RX_BUFFER_TAIL
        dec UART_RX_BUFFER_BYTES

        ; check flow control
        ;bbr7 UART_RX_FLAGS, @done       ; if already xon, just exit again
        ;lda #UART_RX_BUFFER_XON_SIZE    ; otherwise, show we ask for xon?
        ;cmp UART_RX_BUFFER_BYTES
        ;bcc @done                       ; all good
        ;jsr uartFlowCtrlXon             ; continue sending please.
@done
        sec
        rts
@noData
        clc
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
