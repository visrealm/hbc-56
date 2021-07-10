; 6502 LCD - HBC-56
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
;

; IO Ports
LCD_CMD      				 = IO_PORT_BASE_ADDRESS | $00
LCD_DATA      				 = IO_PORT_BASE_ADDRESS | $01

; Commands
LCD_CMD_CLEAR                = %00000001
LCD_CMD_HOME                 = %00000010

LCD_CMD_ENTRY_MODE           = %00000100
LCD_CMD_ENTRY_MODE_INCREMENT = %00000010
LCD_CMD_ENTRY_MODE_DECREMENT = %00000000
LCD_CMD_ENTRY_MODE_SHIFT     = %00000001

LCD_CMD_DISPLAY              = %00001000
LCD_CMD_DISPLAY_ON           = %00000100
LCD_CMD_DISPLAY_CURSOR       = %00000010
LCD_CMD_DISPLAY_CURSOR_BLINK = %00000001

LCD_CMD_SHIFT                = %00010000
LCD_CMD_SHIFT_CURSOR         = %00000000
LCD_CMD_SHIFT_DISPLAY        = %00001000
LCD_CMD_SHIFT_LEFT           = %00000000
LCD_CMD_SHIFT_RIGHT          = %00000100

LCD_CMD_SET_CGRAM_ADDR       = $40
LCD_CMD_SET_DRAM_ADDR        = $80

LCD_CMD_FUNCTIONSET     	 = $20
LCD_CMD_8BITMODE        	 = $10
LCD_CMD_2LINE           	 = $08

STR_ADDR = $10
STR_ADDR_L = STR_ADDR
STR_ADDR_H = STR_ADDR + 1


LCD_ADDR_LINE1 = 0x00
LCD_ADDR_LINE2 = 0x10
LCD_ADDR_LINE3 = 0x08
LCD_ADDR_LINE4 = 0x18

CHARS_WIDTH = 16



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
; lcdPrint: Print a null-terminated string
; -----------------------------------------------------------------------------
; Outputs:
;  STR_ADDR: Contains address of string
; -----------------------------------------------------------------------------
lcdPrint:
	ldy #0

-
	jsr lcdWait
	lda (STR_ADDR), y
	beq .end
	adc #1
	sta LCD_DATA
	iny
	jmp -
	
.end:
	rts
	
; -----------------------------------------------------------------------------
; lcdLineOne: Move cursor to line 1
; -----------------------------------------------------------------------------
lcdLineOne:
	lda #(LCD_CMD_SET_DRAM_ADDR | LCD_ADDR_LINE1)
	sta LCD_CMD
	rts

; -----------------------------------------------------------------------------
; lcdLineTwo: Move cursor to line 2
; -----------------------------------------------------------------------------
lcdLineTwo:
	lda #(LCD_CMD_SET_DRAM_ADDR | LCD_ADDR_LINE2)
	sta LCD_CMD
	rts
	
; -----------------------------------------------------------------------------
; lcdLineThree: Move cursor to line 3
; -----------------------------------------------------------------------------
lcdLineThree:
	lda #(LCD_CMD_SET_DRAM_ADDR | LCD_ADDR_LINE3)
	sta LCD_CMD
	rts

; -----------------------------------------------------------------------------
; lcdLineFour: Move cursor to line 4
; -----------------------------------------------------------------------------
lcdLineFour:
	lda #(LCD_CMD_SET_DRAM_ADDR | LCD_ADDR_LINE4)
	sta LCD_CMD
	rts


; -----------------------------------------------------------------------------
; lcdNextLine4: Move cursor to next line (4-row LCD version)
; -----------------------------------------------------------------------------
lcdNextLine4:
	jsr lcdWait
	; A now contains address
	cmp #LCD_ADDR_LINE4
	bcs lcdLineOne
	cmp #LCD_ADDR_LINE2
	bcs lcdLineThree
	cmp #LCD_ADDR_LINE3
	bcs lcdLineFour
	
	jmp lcdLineTwo

; -----------------------------------------------------------------------------
; lcdNextLine2: Move cursor to next line (2-row LCD version)
; -----------------------------------------------------------------------------
lcdNextLine2:
	jsr lcdWait
	; A now contains address
	cmp #LCD_ADDR_LINE2
	bcs lcdLineOne
	jmp lcdLineTwo
