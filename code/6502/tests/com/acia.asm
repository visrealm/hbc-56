; Troy's HBC-56 - Input test
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;


!src "hbc56kernel.inc"

ACIA_PORT = $20

ACIA_REG      = IO_PORT_BASE_ADDRESS | ACIA_PORT
ACIA_DATA     = IO_PORT_BASE_ADDRESS | ACIA_PORT | $01

ACIA_MASTER_RESET = %00000011
ACIA_CLOCK_DIV_16 = %00000001
ACIA_WORD_8BITS_1STOP   = %00010100


COMMAND_ADDR = $1000
COMMAND_LEN  = HBC56_USER_ZP_START




aciaSend:
        pha
        lda #2
@aciaTestSend
        bit ACIA_REG
        beq @aciaDelay

        nop
        nop

        pla
        sta ACIA_DATA
        rts

@aciaDelay
        nop
        nop
        jmp @aciaTestSend

aciaSendString:
	ldy #0
-
	lda (STR_ADDR), y
	beq +
        jsr aciaSend
	iny
	bne -
+
        rts
        

!macro aciaSendString .str {
	jmp @afterText
@textAddr
	!text .str,0
@afterText        

        lda #<@textAddr
        sta STR_ADDR_L
        lda #>@textAddr
        sta STR_ADDR_H
        jsr aciaSendString        
}





hbc56Meta:
        +setHbcMetaTitle "UART TEST"
        rts

hbc56Main:
        +tmsEnableOutput

        +tmsPrint "HBC-56 UART Test",0,0

        lda #ACIA_MASTER_RESET
        sta ACIA_REG

        jsr hbc56Delay
        lda #(ACIA_CLOCK_DIV_16 | ACIA_WORD_8BITS_1STOP)
        sta ACIA_REG

        +aciaSendString "HBC-56 Monitor\r\nREADY\r\n> "

loop:
        nop
        nop
        nop
        nop

        lda #1
        bit ACIA_REG
        beq loop

        nop
        nop

        lda ACIA_DATA
        beq loop

        pha
        jsr tmsConsoleOut
        pla
        jsr aciaSend
        cmp #'\n'
        beq .eol

        jmp loop

.eol
        +aciaSendString "OK.\r\n> "
        jmp loop
