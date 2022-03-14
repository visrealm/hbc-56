; 6502 - HBC-56 Kernel Interrupt Handling
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
;

; -------------------------
; Interrupts
; -------------------------
TMS9918_IRQ            = 1      ; /INT
KB_IRQ                 = 2      ; RES1
UART_IRQ               = 3      ; RES2
VIA_IRQ                = 5      ; Onboard

TMS9918_IRQ_BIT = (1 << (TMS9918_IRQ - 1))
KB_IRQ_BIT      = (1 << (KB_IRQ - 1))
UART_IRQ_BIT    = (1 << (UART_IRQ - 1))

INT_CTRL_ADDRESS    = IO_PORT_BASE_ADDRESS | INT_IO_PORT

; -----------------------------------------------------------------------------
; HBC-56 Interrupt handler
; -----------------------------------------------------------------------------
hbc56IntHandler:
        pha
        phx
        phy

        lda INT_CTRL_ADDRESS

!ifdef HAVE_UART {
        bit #UART_IRQ_BIT
        beq +
        jsr uartIrq        
        bra @endIntHandler
+
}

!ifdef HAVE_TMS9918 {
        bit #TMS9918_IRQ_BIT
        beq +
        jsr hbc56Tms9918Int
        +tmsReadStatus
        bra @endIntHandler
+
}

!ifdef HAVE_KEYBOARD {
        bit #KB_IRQ_BIT
        beq +
        jsr kbIntHandler
        bra @endIntHandler
+
}
        
@endIntHandler:
        ply
        plx
        pla      
        rti



; -----------------------------------------------------------------------------
; HBC-56 TMS9918 VSYNC Interrupt handler
; -----------------------------------------------------------------------------
!ifdef HAVE_TMS9918 {
hbc56Tms9918Int:

        ; update ticks and seconds
        inc HBC56_TICKS
        lda HBC56_TICKS
        cmp #TMS_FPS
        bne +
        lda #0
        sta HBC56_TICKS
        +inc16 HBC56_SECONDS_L
+
        ; "tick" for sfx manager
        !ifdef HAVE_SFX_MAN {
                jsr sfxManTick
        }

        ; handle console if enabled
        bit HBC56_CONSOLE_FLAGS
        bpl +
        jsr .consoleVsyncCallback
+

        ; rely on callback rts to return
        jmp (HBC56_VSYNC_CALLBACK)


; -----------------------------------------------------------------------------
; HBC-56 TMS9918 Console update
; -----------------------------------------------------------------------------
.consoleVsyncCallback:

        lda HBC56_TICKS
        beq .doCursor
        cmp #30
        beq .doCursor
        jmp @endConsoleCallback

.doCursor:
        stx HBC56_TMP_X
        sty HBC56_TMP_Y
        jsr tmsSetPosConsole
        ldx HBC56_TMP_X
        ldy HBC56_TMP_Y
        lda HBC56_TICKS
        beq +
        lda #' '
        +tmsPut
        jmp @endConsoleCallback
+ 
        lda #$7f
        +tmsPut

@endConsoleCallback

.nullCallbackFunction:
        rts
}
