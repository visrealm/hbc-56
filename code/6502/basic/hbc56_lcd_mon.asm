; BASIC for the HBC-56 (LCD version)

!src "hbc56kernel.inc"

!src "basic.asm"

LCD_MODEL = 12864

LCD_BUFF_ERADDR = $7d00

!src "lcd/lcd.asm"

SAVE_X = $E0		; For saving registers
SAVE_Y = $E1
SAVE_A = $E2

; put the IRQ and NMI code in RAM so that it can be changed

IRQ_vec	= VEC_SV+2	; IRQ code vector
NMI_vec	= IRQ_vec+$0A	; NMI code vector

; reset vector points here

RES_vec
main:
        sei
        jsr kbInit
        jsr lcdInit
        jsr lcdDisplayOn
        jsr lcdCursorBlinkOn

	LDY	#END_CODE-LAB_vec	; set index/count
LAB_stlp
	LDA	LAB_vec-1,Y		; get byte from interrupt code
	STA	VEC_IN-1,Y		; save to RAM
	DEY				; decrement index/count
	BNE	LAB_stlp		; loop if more to do

        cli

	JMP	LAB_COLD		; do EhBASIC warm start

ASCII_RETURN    = $0A
ASCII_BACKSPACE = $08

; byte out to screen (TMS9918)
SCRNout
        sei     ; disable interrupts during output
        stx SAVE_X
        sty SAVE_Y
        sta SAVE_A
        cmp #ASCII_RETURN
        beq .newline
        cmp #ASCII_BACKSPACE
        beq .backspace

        ; regular character
        jsr lcdChar ; outputs A to the LCD - auto-scrolls too :)


.endOut:
        ldx SAVE_X
        ldy SAVE_Y
        lda SAVE_A
        cli
        rts


.newline
        jsr lcdNextLine ; scroll to the next line... scroll screen if on last line
        jmp .endOut

.backspace
        ; TBD... 
        jmp .endOut

	RTS

; byte in from keyboard

KBDin
        jmp kbReadAscii ; return character in 'A', set carry if set

OSIload				        ; load vector for EhBASIC
	RTS

OSIsave				        ; save vector for EhBASIC
	RTS

; vector tables

LAB_vec
	!word	KBDin                   ; byte in from keyboard
	!word	SCRNout		        ; byte out to screen
	!word	OSIload		        ; load vector for EhBASIC
	!word	OSIsave		        ; save vector for EhBASIC

END_CODE

