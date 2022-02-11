; Troy's HBC-56 - Monitor
;
; Copyright (c) 2022 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
;

!src "hbc56kernel.inc"

COMMAND_LEN             = HBC56_USER_ZP_START
TMP_C                   = COMMAND_LEN + 1
CURR_ADDR               = TMP_C + 1
CURR_ADDR_H             = TMP_C + 2
HEX_H                   = CURR_ADDR_H + 1
HEX_L                   = CURR_ADDR_H + 2
TEMP_ADDR               = HEX_L + 1
TEMP_ADDR_H             = HEX_L + 2

DUMP_ROW_START_L        = TEMP_ADDR + 1
DUMP_ROW_START_H        = TEMP_ADDR + 2

COMMAND_BUFFER          = HBC56_KERNEL_RAM_END
COMMAND_BUFFER_LEN      = 250

UART = 1
TMS  = 0

!macro outputA {
        !if UART {
                jsr uartOut
        }
        !if TMS {
                jsr tmsConsoleOut
        }
}

!macro outputString .str {
        !if UART {
                +uartOutString .str
        }
        !if TMS {
                +tmsConsolePrint .str
        }
}

!macro outputStringAddr .addr {
        !if UART {
                +uartOutStringAddr .addr
        }
        !if TMS {
                +tmsConsolePrintAddr .addr

        }
}

!macro inputA{
        !if UART {
                jsr uartInWait
        } else {
                jsr kbWaitForKey
        }
}

FG     = TMS_GREY
BG     = TMS_BLACK


; -----------------------------------------------------------------------------
; metadata for the HBC-56 monitor
; -----------------------------------------------------------------------------
hbc56Meta:
        +setHbcMetaTitle "HBC-56 MONITOR"
        +setHbcMetaNoWait
        rts

; -----------------------------------------------------------------------------
; main entry point
; -----------------------------------------------------------------------------
hbc56Main:
        +tmsColorFgBg FG, BG
        jsr tmsSetBackground
        jsr tmsModeGraphicsI
       
!if TMS {
        jsr tmsModeText
	+tmsUpdateFont TMS_TEXT_MODE_FONT
        +consoleEnableCursor

}       
        +tmsDisableOutput
        +tmsDisableInterrupts
        +tmsReadStatus
        
!if UART {
        jsr uartInit
        +setIntHandler uartIrq
}

        cli

        stz COMMAND_LEN
        stz CURR_ADDR
        lda #$10
        sta CURR_ADDR_H

        +outputStringAddr clearCommandBytes

        +outputStringAddr welcomeMessage
        +outputStringAddr welcomeMessage2

; -----------------------------------------------------------------------------
; main loop
; -----------------------------------------------------------------------------
commandLoop
        stz COMMAND_LEN

        jsr outPrompt

inputLoop
        +inputA

        cmp #$0d        ; enter?
        beq commandEntered

        ldx COMMAND_LEN
        cmp #$08        ; backspace
        bne +
        cpx #0
        beq inputLoop
        dec COMMAND_LEN        
        +outputA
        bra inputLoop
+
        cmp #$20        ; printable?
        bcs +

        ; here, we're dealing with a non-printable character
        ; handle it?

        lda #'E'
        +outputA
        bra inputLoop
+
        sta COMMAND_BUFFER,x
        +outputA
        inc COMMAND_LEN ; TODO: check length...
        
        bra inputLoop  ; always

quit:

        rts

; -----------------------------------------------------------------------------
; parse and run a command
; -----------------------------------------------------------------------------
commandEntered:
        +outputA
        jsr outNewline

        ldx #0

@checkChar
        cpx COMMAND_LEN
        beq commandLoop

        lda COMMAND_BUFFER,x
        inx
        pha
        jsr isSpace
        bcs @checkChar
        pla

        cmp #'$'        ; move to an address?
        bne +
        jmp addressCommand
+
        cmp #'d'        ; dump memory
        bne +
        jmp dumpCommand
+
        cmp #'c'        ; clear
        bne +
        jmp clearCommand
+

        cmp #'e'        ; execute
        bne +
        jsr doExecute

        +setIntHandler uartIrq
        
        jmp commandLoop
+

        cmp #'q'        ; quit
        bne +
        jmp quit
+

        cmp #'w'        ; write
        bne +
        jmp writeCommand
+

        cmp #'s'        ; send
        bne +
        jmp sendCommand
+

        cmp #'h'        ; help!
        bne +
        jmp helpCommand
+

        jsr invalidCommand

        jmp commandLoop

; -----------------------------------------------------------------------------
; run subroutine (or code) at current address
; -----------------------------------------------------------------------------
doExecute:
        jmp (CURR_ADDR)

; -----------------------------------------------------------------------------
; read a hex byte from the buffer, store in HEXL/HEX_H
; -----------------------------------------------------------------------------
readHexByte
        lda COMMAND_BUFFER,x

        jsr isDigitX
        bcs +
        inx
        cpx COMMAND_LEN
        bne readHexByte
+
        sta HEX_H
        inx
        cpx COMMAND_LEN
        bne +
        sta HEX_L
        stz HEX_H
        rts
+
        lda COMMAND_BUFFER,x
        sta HEX_L
        inx
        rts

; -----------------------------------------------------------------------------
; invalid command message
; -----------------------------------------------------------------------------
invalidCommand:
        +outputStringAddr syntaxErrorMsg
        rts

; -----------------------------------------------------------------------------
; output the command prompt
; -----------------------------------------------------------------------------
outPrompt:
        jsr outNewline

        +outputStringAddr blueText

        lda #'$'
        +outputA
        lda CURR_ADDR_H
        jsr outHex8
        lda CURR_ADDR
        jsr outHex8
        lda #'>'
        +outputA
        lda #' '
        +outputA

        +outputStringAddr resetText
        rts


; -----------------------------------------------------------------------------
; output a newline characer
; -----------------------------------------------------------------------------
outNewline:
        lda #$0d
        +outputA
        rts
; -----------------------------------------------------------------------------
; convert 4-bit HEX ascii character to binary in accumulator
; -----------------------------------------------------------------------------
hexNibbleToAcc:
        sec
        sbc #'0'
        cmp #10
        bcc @hexVal
        sec
        sbc #'A'-'0'-10
        cmp #16
        bcc @hexVal
        sec
        sbc #$20
        cmp #16
        bcc @hexVal
        lda #0
@hexVal
        rts

; -----------------------------------------------------------------------------
; convert 8-bit HEX ascii string to binary in accumulator
; -----------------------------------------------------------------------------
hexToAcc:
        lda HEX_H
        jsr hexNibbleToAcc
        +asl4
        sta HEX_H
        lda HEX_L
        jsr hexNibbleToAcc
        ora HEX_H
        rts

; -----------------------------------------------------------------------------
; output accumulator as a hex byte
; -----------------------------------------------------------------------------
outHex8:
        phx
	pha
        +lsr4
	tax
	lda hexDigits, x
        +outputA
	pla
	and #$0f
	tax
	lda hexDigits, x
        +outputA        
        plx
	rts

!src "commands/address.asm"
!src "commands/clear.asm"
!src "commands/dump.asm"
!src "commands/write.asm"
!src "commands/help.asm"

hexDigits:
!text "0123456789abcdef"

blueText:
!text $1b,"[94m",0
resetText:
!text $1b,"[0m",0

welcomeMessage:
!text $1b,"[94m"," _    _  _____    _____   _______ _____\n"
!text "| |  | |/____ \\  / ___/  |  ____// ___/\n"
!text "| |__| | ____) || /   ___| |___ / /___\n"
!text "|  __  ||  __ < | |  /__/|____ \\|  __ \\\n"
!text "| |  | || |__) || \\____   ____) | (__) |\n"
!text "|_|  |_||_____/  \\____/  /_____/ \\____/\n\n",$1b,"[0m",0
welcomeMessage2:
!text "HBC-56 Memory Monitor (Enter ",$1b,"[1m\"h\"",$1b,"[0m for help)\n"
!text "------------------------------------------\n", 0
dumpHeader:
!text "       00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f 0123456789abcdef\n"
!text "       ----------------------------------------------- ----------------",0

syntaxErrorMsg:
!text $07,$1b,"[91m","* Syntax error *",$1b,"[0m","  Enter \"h\" for help.\n",0


!if TMS {
TMS_TEXT_MODE_FONT:
!src "gfx/fonts/tms9918font2subset.asm"
}