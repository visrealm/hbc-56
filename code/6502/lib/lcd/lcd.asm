; 6502 LCD - HBC-56
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;

!ifndef LCD_IO_PORT { LCD_IO_PORT = $02
        !warn "LCD_IO_PORT not provided. Defaulting to ", LCD_IO_PORT
}

!ifndef LCD_ZP_START { LCD_ZP_START = $38
        !warn "LCD_ZP_START not provided. Defaulting to ", LCD_ZP_START
}

!ifndef LCD_RAM_START { LCD_RAM_START = $7c00
        !warn "LCD_RAM_START not provided. Defaulting to ", LCD_RAM_START
}

HAVE_LCD = 1

; -------------------------
; Zero page
; -------------------------
LCD_TMP1	= LCD_ZP_START
LCD_TMP2	= LCD_ZP_START + 1
LCD_ZP_SIZE	= 2


; -------------------------
; High RAM
; -------------------------
.LCD_BUFFER_ADDR	= LCD_RAM_START
.LCD_REGY_TMP		= LCD_RAM_START + 40
LCD_RAM_SIZE    	= 42


!if LCD_ZP_END < (LCD_ZP_START + LCD_ZP_SIZE) {
	!error "LCD_ZP requires ",LCD_ZP_SIZE," bytes. Allocated ",LCD_ZP_END - LCD_ZP_START
}

!if LCD_RAM_END < (LCD_RAM_START + LCD_RAM_SIZE) {
	!error "LCD_RAM requires ",LCD_RAM_SIZE," bytes. Allocated ",LCD_RAM_END - LCD_RAM_START
}



; -------------------------
; Contants
; -------------------------

; IO Ports
LCD_CMD		= IO_PORT_BASE_ADDRESS | LCD_IO_PORT
LCD_DATA	= IO_PORT_BASE_ADDRESS | LCD_IO_PORT | $01

; Commands
LCD_CMD_CLEAR			= %00000001
LCD_CMD_HOME			= %00000010

LCD_CMD_ENTRY_MODE		= %00000100
LCD_CMD_ENTRY_MODE_INCREMENT	= %00000010
LCD_CMD_ENTRY_MODE_DECREMENT	= %00000000
LCD_CMD_ENTRY_MODE_SHIFT	= %00000001

LCD_CMD_DISPLAY			= %00001000
LCD_CMD_DISPLAY_ON		= %00000100
LCD_CMD_DISPLAY_CURSOR		= %00000010
LCD_CMD_DISPLAY_CURSOR_BLINK	= %00000001

LCD_CMD_SHIFT			= %00010000
LCD_CMD_SHIFT_CURSOR		= %00000000
LCD_CMD_SHIFT_DISPLAY		= %00001000
LCD_CMD_SHIFT_LEFT		= %00000000
LCD_CMD_SHIFT_RIGHT		= %00000100

LCD_CMD_SET_CGRAM_ADDR		= $40
LCD_CMD_SET_DRAM_ADDR		= $80

LCD_CMD_FUNCTIONSET		= $20
LCD_CMD_8BITMODE		= $10
LCD_CMD_2LINE			= $08

!ifndef LCD_MODEL {
	!warn "Set LCD_MODEL to one of: 1602, 2004 or 12864. Defaulting to 1602"
	LCD_MODEL = 1602
}

!src "lcd/lcd.inc"

; -------------------------
; Constants
; -------------------------
!if LCD_MODEL = 1602 {
	LCD_ROWS = 2
	LCD_COLUMNS = 16
	LCD_GRAPHICS = 0
	LCD_ADDR_LINE1 = 0x00
	LCD_ADDR_LINE2 = 0x40
} else { !if LCD_MODEL = 2004 {
	LCD_ROWS = 4
	LCD_COLUMNS = 20
	LCD_GRAPHICS = 0
	LCD_ADDR_LINE1 = 0x00
	LCD_ADDR_LINE2 = 0x40
	LCD_ADDR_LINE3 = 0x14
	LCD_ADDR_LINE4 = 0x54
} else { !if LCD_MODEL = 12864 {
	LCD_ROWS = 4
	LCD_COLUMNS = 16
	LCD_GRAPHICS = 1
	LCD_ADDR_LINE1 = 0x00
	LCD_ADDR_LINE2 = 0x10
	LCD_ADDR_LINE3 = 0x08
	LCD_ADDR_LINE4 = 0x18
	!source "lcd/lcd12864b.asm"
} else {
	!error "Unknown LCD_MODEL. Must be one of: 1602, 2004 or 12864"
}}}


LCD_INITIALIZE	= LCD_CMD_FUNCTIONSET | LCD_CMD_8BITMODE | LCD_CMD_2LINE
DISPLAY_MODE	= LCD_CMD_DISPLAY | LCD_CMD_DISPLAY_ON

ASCII_NEWLINE = 10

; -----------------------------------------------------------------------------
; lcdInit: Initialise the LCD
; -----------------------------------------------------------------------------
lcdInit:
	jsr lcdWait
	lda #LCD_INITIALIZE
	sta LCD_CMD
	jsr lcdClear
	jsr lcdHome
	jsr lcdDisplayOff
	rts


; -----------------------------------------------------------------------------
; lcdClear: Clears the LCD
; -----------------------------------------------------------------------------
lcdClear:
	jsr lcdWait
	lda #LCD_CMD_CLEAR
	sta LCD_CMD
	rts	

; -----------------------------------------------------------------------------
; lcdHome: Return to the start address
; -----------------------------------------------------------------------------
lcdHome:
	jsr lcdWait
	lda #LCD_CMD_HOME
	sta LCD_CMD
	rts	

; -----------------------------------------------------------------------------
; lcdDisplayOn: Turn the display on
; -----------------------------------------------------------------------------
lcdDisplayOn:
	jsr lcdWait
	lda #DISPLAY_MODE
	sta LCD_CMD
	rts

; -----------------------------------------------------------------------------
; lcdDisplayOff: Turn the display off
; -----------------------------------------------------------------------------
lcdDisplayOff:
	jsr lcdWait
	lda #LCD_CMD_DISPLAY
	sta LCD_CMD
	rts

; -----------------------------------------------------------------------------
; lcdCursorOn: Show cursor
; -----------------------------------------------------------------------------
lcdCursorOn:
	jsr lcdWait
	lda #DISPLAY_MODE | LCD_CMD_DISPLAY_CURSOR
	sta LCD_CMD
	rts	

; -----------------------------------------------------------------------------
; lcdCursorOff: Hide cursor
; -----------------------------------------------------------------------------
lcdCursorOff:
	jsr lcdWait
	lda #DISPLAY_MODE
	sta LCD_CMD
	rts	

; -----------------------------------------------------------------------------
; lcdCursorBlinkOn: Show cursor
; -----------------------------------------------------------------------------
lcdCursorBlinkOn:
	jsr lcdWait
	lda #DISPLAY_MODE | LCD_CMD_DISPLAY_CURSOR | LCD_CMD_DISPLAY_CURSOR_BLINK
	sta LCD_CMD
	rts	

; -----------------------------------------------------------------------------
; lcdDetect: Do we have an LCD plugged in?
; -----------------------------------------------------------------------------
; Outputs:
;  C: 1 if exists. 0 if not
; -----------------------------------------------------------------------------
lcdDetect:
	clc
	lda LCD_CMD
	bne +
	sec
+
	rts


; -----------------------------------------------------------------------------
; lcdWait: Wait until the LCD is no longer busy
; -----------------------------------------------------------------------------
; Outputs:
;  A: Current LCD address
; -----------------------------------------------------------------------------
lcdWait:
	lda LCD_CMD
	bmi lcdWait  ; branch if bit 7 is set
	rts

; -----------------------------------------------------------------------------
; lcdWaitPreserve: Wait until the LCD is no longer busy Preserves A, address in x
; -----------------------------------------------------------------------------
lcdWaitPreserve:
	ldy LCD_CMD
	bmi lcdWaitPreserve; branch if bit 7 is set
	rts

; -----------------------------------------------------------------------------
; lcdRead: Read a character from the LCD
; -----------------------------------------------------------------------------
; Outputs:
;  A: Character read
; -----------------------------------------------------------------------------
lcdRead:
	jsr lcdWait
	lda LCD_DATA
	rts

; -----------------------------------------------------------------------------
; lcdPrint: Print a null-terminated string
; -----------------------------------------------------------------------------
; Inputs:
;  STR_ADDR: Contains address of null-terminated string
; -----------------------------------------------------------------------------
lcdPrint:
	ldy #0
-
	jsr lcdWait
	lda (STR_ADDR), y
	beq ++
	cmp #ASCII_NEWLINE ; check for newline
	bne +
	jsr lcdNextLine
	iny
	jmp -
+ 
	sta LCD_DATA
	iny
	jmp -
++
	rts

; -----------------------------------------------------------------------------
; lcdChar: Output a character
; -----------------------------------------------------------------------------
; Inputs:
;  A: The character to output
; -----------------------------------------------------------------------------
lcdChar:
	jsr lcdWaitPreserve
	sta LCD_DATA
	rts

; -----------------------------------------------------------------------------
; lcdCharScroll: Output a character, scroll if required
; -----------------------------------------------------------------------------
; Inputs:
;  A: The character to output
; -----------------------------------------------------------------------------
lcdCharScroll:
	jsr lcdWaitPreserve
	sta LCD_DATA

	; Y is previous address
	jsr lcdCurrentLine
	sta LCD_TMP1
	jsr lcdWaitPreserve
	jsr lcdCurrentLine
	eor LCD_TMP1
	beq +
	inc LCD_TMP1
	lda LCD_TMP1
	jmp lcdGotoLine
+
	rts

; -----------------------------------------------------------------------------
; lcdBackspace: Backspace a character
; -----------------------------------------------------------------------------
lcdBackspace:
	jsr lcdWaitPreserve
	; Y is previous address
	jsr lcdCurrentLine
	sta LCD_TMP1

	lda #LCD_CMD_SHIFT | LCD_CMD_SHIFT_LEFT
	sta LCD_CMD
	jsr lcdWait
	jsr lcdWaitPreserve
	jsr lcdCurrentLine
	eor LCD_TMP1
	beq +
	dec LCD_TMP1
	bmi +
	lda LCD_TMP1
	jmp lcdGotoLineEnd
+
	jsr lcdWait
	lda #' '
	sta LCD_DATA
	jsr lcdWait
	lda #LCD_CMD_SHIFT | LCD_CMD_SHIFT_LEFT
	sta LCD_CMD

	rts

; -----------------------------------------------------------------------------
; lcdInt8: Output an 8-bit integer
; -----------------------------------------------------------------------------
; Inputs:
;  A: The value to output
; -----------------------------------------------------------------------------
lcdInt8:

.B = LCD_TMP1
.C = LCD_TMP2

	pha
	ldx #1
	stx .C
	inx
	ldy #$40
--
	sty .B
	lsr
-
	rol
	bcs +
	cmp .A, x
	bcc ++
+ 
	sbc .A, x
	sec
++ 
	rol .B
	bcc -
	tay
	cpx .C
	lda .B
	bcc +
	beq ++
	stx .C
+
	eor #$30
	jsr lcdChar
++
	tya
	ldy #$10
	dex
	bpl --
	pla
	rts

.A !byte 128,160,200


; -----------------------------------------------------------------------------
; lcdHex8: Output an 8-bit byte as hexadecimal
; -----------------------------------------------------------------------------
; Inputs:
;  A: The value to output
; -----------------------------------------------------------------------------
lcdHex8:
	pha
	lsr
	lsr
	lsr
	lsr
	tax
	lda .H, x
	jsr lcdChar
	pla
	pha
	and #$0f
	tax
	lda .H, x
	jsr lcdChar
	pla
	rts

.H !text "0123456789abcdef"


!if LCD_ROWS > 2 {

lcdCurrentLine4:
	cpy #LCD_ADDR_LINE4
	bcs .lcdLine4
	cpy #LCD_ADDR_LINE2
	bcs .lcdLine2
	cpy #LCD_ADDR_LINE3
	bcs .lcdLine3
	jmp .lcdLine1

.lcdLine3
	lda #3
	rts

.lcdLine4
	lda #4
	rts

} ; LCD_ROWS > 2

lcdCurrentLine2:
	cpy #LCD_ADDR_LINE1+LCD_COLUMNS;16;LCD_ADDR_LINE2
	bcc .lcdLine1
	jmp .lcdLine2

.lcdLine1
	lda #1
	rts

.lcdLine2
	lda #2
	rts

; -----------------------------------------------------------------------------
; lcdCurrentLine: Return the current line/row
; -----------------------------------------------------------------------------
lcdCurrentLine:
!if LCD_ROWS > 2 {
	jmp lcdCurrentLine4
} else {
	jmp lcdCurrentLine2
}



; -----------------------------------------------------------------------------
; lcdGotoLineEnd: Go to end of line in 'A'
; -----------------------------------------------------------------------------
lcdGotoLineEnd:
!if LCD_ROWS > 2 {
	cmp #4
	beq lcdLineFourEnd
	cmp #3
	beq lcdLineThreeEnd
}
	cmp #2
	beq lcdLineTwoEnd
	jmp lcdLineOneEnd


; -----------------------------------------------------------------------------
; lcdLineOneEnd: Move cursor to end of line 1
; -----------------------------------------------------------------------------
lcdLineOneEnd:
	pha
!if LCD_MODEL = 12864 {
	lda #(LCD_CMD_SET_DRAM_ADDR | LCD_ADDR_LINE1) + (LCD_COLUMNS/2) - 1
	sta LCD_CMD
	jsr lcdRead
	pha
	lda #(LCD_CMD_SET_DRAM_ADDR | LCD_ADDR_LINE1) + (LCD_COLUMNS/2) - 1
	sta LCD_CMD
	lda #' '
	jsr lcdChar
	jsr lcdChar
	lda #(LCD_CMD_SET_DRAM_ADDR | LCD_ADDR_LINE1) + (LCD_COLUMNS/2) - 1
	sta LCD_CMD
	pla
	jsr lcdChar
} else {
	lda #(LCD_CMD_SET_DRAM_ADDR | LCD_ADDR_LINE1) + (LCD_COLUMNS) - 2
	sta LCD_CMD
	jsr lcdRead
	pha
	lda #(LCD_CMD_SET_DRAM_ADDR | LCD_ADDR_LINE1) + (LCD_COLUMNS) - 2
	sta LCD_CMD
	lda #' '
	jsr lcdChar
	jsr lcdChar
	lda #(LCD_CMD_SET_DRAM_ADDR | LCD_ADDR_LINE1) + (LCD_COLUMNS) - 2
	sta LCD_CMD
	pla
	jsr lcdChar
}
	pla
	rts

; -----------------------------------------------------------------------------
; lcdLineTwoEnd: Move cursor to end of line 2
; -----------------------------------------------------------------------------
lcdLineTwoEnd:
	pha
!if LCD_MODEL = 12864 {
	lda #(LCD_CMD_SET_DRAM_ADDR | LCD_ADDR_LINE2) + (LCD_COLUMNS/2) - 1
	sta LCD_CMD
	jsr lcdRead
	pha
	lda #(LCD_CMD_SET_DRAM_ADDR | LCD_ADDR_LINE2) + (LCD_COLUMNS/2) - 1
	sta LCD_CMD
	lda #' '
	jsr lcdChar
	jsr lcdChar
	lda #(LCD_CMD_SET_DRAM_ADDR | LCD_ADDR_LINE2) + (LCD_COLUMNS/2) - 1
	sta LCD_CMD
	pla
	jsr lcdChar
} else {
	lda #(LCD_CMD_SET_DRAM_ADDR | LCD_ADDR_LINE2) + (LCD_COLUMNS) - 2
	sta LCD_CMD
	jsr lcdRead
	pha
	lda #(LCD_CMD_SET_DRAM_ADDR | LCD_ADDR_LINE2) + (LCD_COLUMNS) - 2
	sta LCD_CMD
	lda #' '
	jsr lcdChar
	jsr lcdChar
	lda #(LCD_CMD_SET_DRAM_ADDR | LCD_ADDR_LINE2) + (LCD_COLUMNS) - 2
	sta LCD_CMD
	pla
	jsr lcdChar
}
	pla
	rts


 !if LCD_ROWS > 2 {
; -----------------------------------------------------------------------------
; lcdLineThreeEnd: Move cursor to end of line 3
; -----------------------------------------------------------------------------
lcdLineThreeEnd:
	pha
!if LCD_MODEL = 12864 {
	lda #(LCD_CMD_SET_DRAM_ADDR | LCD_ADDR_LINE3) + (LCD_COLUMNS/2) - 1
	sta LCD_CMD
	jsr lcdRead
	pha
	lda #(LCD_CMD_SET_DRAM_ADDR | LCD_ADDR_LINE3) + (LCD_COLUMNS/2) - 1
	sta LCD_CMD
	lda #' '
	jsr lcdChar
	jsr lcdChar
	lda #(LCD_CMD_SET_DRAM_ADDR | LCD_ADDR_LINE3) + (LCD_COLUMNS/2) - 1
	sta LCD_CMD
	pla
	jsr lcdChar
} else {
	lda #(LCD_CMD_SET_DRAM_ADDR | LCD_ADDR_LINE3) + (LCD_COLUMNS) - 2
	sta LCD_CMD
	jsr lcdRead
	pha
	lda #(LCD_CMD_SET_DRAM_ADDR | LCD_ADDR_LINE3) + (LCD_COLUMNS) - 2
	sta LCD_CMD
	lda #' '
	jsr lcdChar
	jsr lcdChar
	lda #(LCD_CMD_SET_DRAM_ADDR | LCD_ADDR_LINE3) + (LCD_COLUMNS) - 2
	sta LCD_CMD
	pla
	jsr lcdChar
}
	pla
	rts

; -----------------------------------------------------------------------------
; lcdLineFourEnd: Move cursor to end of line 4
; -----------------------------------------------------------------------------
lcdLineFourEnd:
	pha
!if LCD_MODEL = 12864 {
	lda #(LCD_CMD_SET_DRAM_ADDR | LCD_ADDR_LINE4) + (LCD_COLUMNS/2) - 1
	sta LCD_CMD
	jsr lcdRead
	pha
	lda #(LCD_CMD_SET_DRAM_ADDR | LCD_ADDR_LINE4) + (LCD_COLUMNS/2) - 1
	sta LCD_CMD
	lda #' '
	jsr lcdChar
	jsr lcdChar
	lda #(LCD_CMD_SET_DRAM_ADDR | LCD_ADDR_LINE4) + (LCD_COLUMNS/2) - 1
	sta LCD_CMD
	pla
	jsr lcdChar
} else {
	lda #(LCD_CMD_SET_DRAM_ADDR | LCD_ADDR_LINE4) + (LCD_COLUMNS) - 2
	sta LCD_CMD
	jsr lcdRead
	pha
	lda #(LCD_CMD_SET_DRAM_ADDR | LCD_ADDR_LINE4) + (LCD_COLUMNS) - 2
	sta LCD_CMD
	lda #' '
	jsr lcdChar
	jsr lcdChar
	lda #(LCD_CMD_SET_DRAM_ADDR | LCD_ADDR_LINE4) + (LCD_COLUMNS) - 2
	sta LCD_CMD
	pla
	jsr lcdChar
}
	pla
	rts


} ; LCD_ROWS > 2

; -----------------------------------------------------------------------------
; lcdGotoLine: Go to line in 'A'
; -----------------------------------------------------------------------------
lcdGotoLine:
!if LCD_ROWS > 2 {
	cmp #4
	beq lcdLineFour
	cmp #3
	beq lcdLineThree
}
	cmp #2
	beq lcdLineTwo
	cmp #1
	beq lcdLineOne
	jmp lcdScrollUp


; -----------------------------------------------------------------------------
; lcdLineOne: Move cursor to line 1
; -----------------------------------------------------------------------------
lcdLineOne:
	pha
	lda #(LCD_CMD_SET_DRAM_ADDR | LCD_ADDR_LINE1)
	sta LCD_CMD
	pla
	rts

; -----------------------------------------------------------------------------
; lcdLineTwo: Move cursor to line 2
; -----------------------------------------------------------------------------
lcdLineTwo:
	pha
	lda #(LCD_CMD_SET_DRAM_ADDR | LCD_ADDR_LINE2)
	sta LCD_CMD
	pla
	rts


 !if LCD_ROWS > 2 {
; -----------------------------------------------------------------------------
; lcdLineThree: Move cursor to line 3
; -----------------------------------------------------------------------------
lcdLineThree:
	pha
	lda #(LCD_CMD_SET_DRAM_ADDR | LCD_ADDR_LINE3)
	sta LCD_CMD
	pla
	rts

; -----------------------------------------------------------------------------
; lcdLineFour: Move cursor to line 4
; -----------------------------------------------------------------------------
lcdLineFour:
	pha
	lda #(LCD_CMD_SET_DRAM_ADDR | LCD_ADDR_LINE4)
	sta LCD_CMD
	pla
	rts
 
; -----------------------------------------------------------------------------
; lcdNextLine4: Move cursor to next line (4-row LCD version)
; -----------------------------------------------------------------------------
lcdNextLine4:
	jsr lcdWait
	; A now contains address
	cmp #LCD_ADDR_LINE4
	bcs lcdScrollUp
	cmp #LCD_ADDR_LINE2
	bcs lcdLineThree
	cmp #LCD_ADDR_LINE3
	bcs lcdLineFour
	
	jmp lcdLineTwo
 }
 

; -----------------------------------------------------------------------------
; lcdNextLine2: Move cursor to next line (2-row LCD version)
; -----------------------------------------------------------------------------
lcdNextLine2:
	jsr lcdWait
	; A now contains address
	cmp #LCD_ADDR_LINE2
	bcs lcdScrollUp
	jmp lcdLineTwo

; -----------------------------------------------------------------------------
; lcdNextLine: Move cursor to next line
; -----------------------------------------------------------------------------
lcdNextLine:
!if LCD_ROWS > 2 {
	jmp lcdNextLine4
} else {
	jmp lcdNextLine2
}

; -----------------------------------------------------------------------------
; lcdReadLine: Reads a line from the display
; -----------------------------------------------------------------------------
; Inputs:
;  STR_ADDR: Contains address to output null-terminated line to
; -----------------------------------------------------------------------------
lcdReadLine:
	ldy #0
-
	jsr lcdRead
	sta (STR_ADDR), y
	iny
	cpy #LCD_COLUMNS
	bne -
	lda #0
	sta (STR_ADDR), y
	rts

; -----------------------------------------------------------------------------
; lcdScrollUp: Scroll the LCD up one line
; -----------------------------------------------------------------------------
lcdScrollUp:
	pha

	jsr lcdCursorOff

	lda #<.LCD_BUFFER_ADDR
	sta STR_ADDR_L
	lda #>.LCD_BUFFER_ADDR
	sta STR_ADDR_H

	jsr lcdWait
	jsr lcdLineTwo
	jsr lcdReadLine
	jsr lcdWait
	jsr lcdLineOne
	jsr lcdPrint
	jsr lcdWait

!if LCD_ROWS > 2 {

	jsr lcdLineThree
	jsr lcdReadLine
	jsr lcdWait
	jsr lcdLineTwo
	jsr lcdPrint
	
	jsr lcdWait
	jsr lcdLineFour
	jsr lcdReadLine
	jsr lcdWait
	jsr lcdLineThree
	jsr lcdPrint
	
	jsr lcdWait
	jsr lcdLineFour
} else {
	jsr lcdLineTwo
}

	ldx #LCD_COLUMNS
-
	+lcdChar ' '
	dex
	bne -
	jsr lcdWait
!if LCD_ROWS > 2 {
	jsr lcdLineFour
} else {
	jsr lcdLineTwo
}

	jsr lcdCursorBlinkOn

	pla
	rts

; -----------------------------------------------------------------------------
; lcdConsoleOut: Print a null-terminated string
; -----------------------------------------------------------------------------
; Inputs:
;  'A': Character to output to console
; -----------------------------------------------------------------------------
lcdConsoleOut:
        sty .LCD_REGY_TMP
        cmp #ASCII_RETURN
        beq .newline
        cmp #ASCII_BACKSPACE
        beq .backspace
        cmp #ASCII_CR   ; omit these
        beq .endOut
        cmp #0
        beq .endOut

        ; regular character
        jsr lcdCharScroll ; outputs A to the LCD - auto-scrolls too :)

.endOut:
        ldy .LCD_REGY_TMP
        rts

.newline
        jsr lcdNextLine ; scroll to the next line... scroll screen if on last line
        jmp .endOut

.backspace
        jsr lcdBackspace 
        jmp .endOut

; -----------------------------------------------------------------------------
; lcdConsolePrint: Print a null-terminated string (console mode)
; -----------------------------------------------------------------------------
; Inputs:
;  STR_ADDR: Contains address of null-terminated string
; -----------------------------------------------------------------------------
lcdConsolePrint:
	ldy #0
-
	lda (STR_ADDR), y
	beq +
        jsr lcdConsoleOut
	iny
	bne -
+
	rts

