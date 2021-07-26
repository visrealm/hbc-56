; 6502 LCD - HBC-56
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
; Dependencies:
;  - hbc56.asm


; -------------------------
; Constants
; -------------------------
LCD_IO_ADDR	= $02


; IO Ports
LCD_CMD		= IO_PORT_BASE_ADDRESS | LCD_IO_ADDR
LCD_DATA	= IO_PORT_BASE_ADDRESS | LCD_IO_ADDR | $01

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
; lcdWaitPreserve: Wait until the LCD is no longer busy Preserves A
; -----------------------------------------------------------------------------
lcdWaitPreserve:
	pha
-
	lda LCD_CMD
	bmi -; branch if bit 7 is set
	pla
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
; lcdPrint: Print immediate text
; -----------------------------------------------------------------------------
; Inputs:
;  str: String to print
; -----------------------------------------------------------------------------
!macro lcdPrint str {
	jmp +
.textAddr
	!text str,0
+
	lda #<.textAddr
	sta STR_ADDR_L
	lda #>.textAddr
	sta STR_ADDR_H
	jsr lcdPrint
}

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
; lcdChar: Print immediate character
; -----------------------------------------------------------------------------
; Inputs:
;  c: Character to print
; -----------------------------------------------------------------------------
!macro lcdChar c {
	pha
	lda #c
	jsr lcdChar
	pla
}

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
; lcdInt8: Output an 8-bit integer
; -----------------------------------------------------------------------------
; Inputs:
;  A: The value to output
; -----------------------------------------------------------------------------
lcdInt8:

.B = R4L
.C = R4H

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
	bcs lcdLineOne
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
	jsr lcdRead
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

!ifdef LCD_BUFFER_ADDR {
	lda #<LCD_BUFFER_ADDR
	sta STR_ADDR_L
	lda #>LCD_BUFFER_ADDR
	sta STR_ADDR_H
}

	jsr lcdWait
	jsr lcdLineTwo
	jsr lcdReadLine
	jsr lcdWait
	jsr lcdLineOne
	jsr lcdPrint
	
	jsr lcdWait
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
	ldx #LCD_COLUMNS
-
	+lcdChar ' '
	dex
	bne -
	jsr lcdWait
	jsr lcdLineFour
	pla
	rts
