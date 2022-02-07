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
                lda #<.addr
                sta STR_ADDR_L
                lda #>.addr
                sta STR_ADDR_H
                jsr tmsConsolePrint        

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
        +tmsEnableOutput
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

        jsr clearScreen

        +outputStringAddr welcomeMessage
        +outputStringAddr welcomeMessage2

commandLoop
        stz COMMAND_LEN

        jsr outPrompt

        jsr uartFlowCtrlXon

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
        ;jsr isWhitespace
        ;bcs inputLoop
        sta COMMAND_BUFFER,x
        +outputA
        inc COMMAND_LEN ; TODO: check length...
        
        bra inputLoop  ; always

        rts

commandEntered:
        +outputA

        jsr uartFlowCtrlXoff

        ldx #0

@checkChar
        cpx COMMAND_LEN
        beq commandLoop

        lda COMMAND_BUFFER,x
        inx
        pha
        jsr isWhitespace
        bcs @checkChar
        pla

        cmp #'$'        ; move to an address?
        beq cmdAddr

        cmp #'d'        ; dump memory
        beq cmdDump

        cmp #'c'        ; clear
        beq cmdClear

        cmp #'e'        ; execute
        beq cmdExecute

        cmp #'r'        ; reset
        beq cmdReset

        cmp #'w'        ; write
        beq cmdWrite

        cmp #'h'        ; help!
        beq cmdHelp

        jmp commandLoop

        jmp cmdInvalid

cmdInvalid:
        jsr invalidCommand
        jmp commandLoop

cmdAddr:
        jsr addressCommand
        jmp commandLoop

cmdWrite:
        jsr writeCommand
        jmp commandLoop

cmdReset:
        jmp hbc56Reset

cmdDump:
        jsr dumpCommand
        jmp commandLoop

doExecute:
        jmp (CURR_ADDR)

cmdExecute:
        jsr doExecute
        jmp commandLoop

cmdHelp:
        jsr helpCommand
        jmp commandLoop

cmdClear:
        jsr clearScreen
        jmp commandLoop

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

addressCommand:
        lda COMMAND_BUFFER+1
        sta HEX_H
        lda COMMAND_BUFFER+2
        sta HEX_L
        jsr hexToAcc
        sta CURR_ADDR_H
        lda COMMAND_BUFFER+3
        sta HEX_H
        lda COMMAND_BUFFER+4
        sta HEX_L
        jsr hexToAcc
        sta CURR_ADDR
        rts

writeCommand:
        ;ldx #1
-
        jsr readHexByte

        jsr hexToAcc
        sta (CURR_ADDR)
        inc CURR_ADDR
        bne +
        inc CURR_ADDR_H
+
        cpx COMMAND_LEN
        bcc -
        rts        

dumpCommand:
        phx
        +outputStringAddr dumpHeader
        plx

        ldy #0
        stz TMP_C

        lda CURR_ADDR
        and #$f0
        sta DUMP_ROW_START_L
        lda CURR_ADDR_H
        sta DUMP_ROW_START_H

        ;ldx #1
;        cpx COMMAND_LEN
;        beq @newLine
;;        jsr readHexByte
 ;       jsr hexToAcc
  ;      sta TMP_C        

@newLine
        lda #$0d
        +outputA
        lda #'$'
        +outputA
        tya
        clc
        adc CURR_ADDR
        sta TEMP_ADDR
        lda CURR_ADDR_H
        bcc +
        inc 
        sta TEMP_ADDR_H
+
        jsr outHex8
        lda TEMP_ADDR
        jsr outHex8
        lda #':'
        +outputA
        ldx #0

@nextByte
        lda #' '
        +outputA
        lda (CURR_ADDR),y
        sta COMMAND_BUFFER,x
        inx
        jsr outHex8
        iny
        cpy TMP_C
        beq @doRaw
        tya
        and #$0f
        bne @nextByte

@doRaw
        lda #' '
        +outputA
        ldx #0
-
        lda COMMAND_BUFFER,x
        cmp #' '
        bcs +
        lda #'.'
+
        cmp #'~'
        bcc +
        lda #'.'
+
        +outputA
        inx
        cpx #16
        bne -
        cpy TMP_C
        bne @newLine

@endDump
        lda #$0d
        +outputA
        rts


helpCommand:
        +outputStringAddr helpMessage
        rts

invalidCommand:
        +outputString "* Syntax error *\n\nEnter \"h\" for help."
        rts

clearScreen:
!if UART {
        lda #$1b
        +outputA
        +outputString "[2J"
        lda #$1b
        +outputA
        +outputString "[H"
} 
!if TMS {
        jsr tmsInitTextTable ; clear output
        jsr tmsConsoleHome
}
        rts

outPrompt:
        jsr outNewline

        +outputStringAddr greenText

        lda #'$'
        +outputA
        lda CURR_ADDR_H
        jsr outHex8
        lda CURR_ADDR
        jsr outHex8
        lda #'>'
        +outputA

        +outputStringAddr resetText
        rts

outNewline:
        lda #$0d
        +outputA
        rts

isWhitespace:
        ldy #whitespaceCharsCount
-
        dey
        cmp whitespaceChars,y
        beq +
        cpy #0
        bne -
        clc
        rts
+
        sec
        rts

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

hexToAcc:
        lda HEX_H
        jsr hexNibbleToAcc
        +asl4
        sta HEX_H
        lda HEX_L
        jsr hexNibbleToAcc
        ora HEX_H
        rts

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

hexDigits:
!text "0123456789abcdef"

greenText:
!text $1b,"[32m",$1b,"[1m",0
resetText:
!text $1b,"[0m",0

whitespaceChars:
!byte ' ','\n','\t','\r',$0b,$0c
whitespaceCharsCount = * - whitespaceChars

helpMessage:
!text "HBC-56 - Monitor Help\n"
!text "  c        - clear screen\n"
!text "  d [#]    - output # bytes from current address\n"
!text "  h        - help\n"
!text "  r        - reset HBC-56\n"
!text "  w <xx>   - write value and increment address\n"
!text "  $ <xxxx> - set current address\n", 0

welcomeMessage:
!text " _    _  _____    _____   _______ _____\n"
!text "| |  | |/____ \\  / ___/  |  ____// ___/\n"
!text "| |__| | ____) || /   ___| |___ / /___\n"
!text "|  __  ||  __ < | |  /__/|____ \\|  __ \\\n"
!text "| |  | || |__) || \\____   ____) | (__) |\n"
!text "|_|  |_||_____/  \\____/  /_____/ \\____/\n\n",0
welcomeMessage2:
!text "HBC-56 Memory Monitor (enter \"h\" for help)\n"
!text "------------------------------------------", 0
dumpHeader:
!text "       00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f 0123456789abcdef\n"
!text "       ----------------------------------------------- ----------------",0



!if TMS {
TMS_TEXT_MODE_FONT:
!src "gfx/fonts/tms9918font2subset.asm"
}