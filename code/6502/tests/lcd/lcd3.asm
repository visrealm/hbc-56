!cpu 65c02
!initmem $FF
!to "lcd3.o", plain

*=$8000


LCD_CMD       = $7f00
LCD_DATA      = $7f01

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

LCD_CMD_SET_CGRAM_ADDR       = %01000000
LCD_CMD_SET_DRAM_ADDR        = %10000000

LCD_CMD_FUNCTIONSET = $20
LCD_CMD_8BITMODE    = $10
LCD_CMD_2LINE       = $08

LCD_INITIALIZE      = <(LCD_CMD_FUNCTIONSET | LCD_CMD_8BITMODE | LCD_CMD_2LINE)
DISPLAY_MODE  = <(LCD_CMD_DISPLAY | LCD_CMD_DISPLAY_ON) ; | LCD_CMD_DISPLAY_CURSOR | LCD_CMD_DISPLAY_CURSOR_BLINK)

STR_ADDR = $10
STR_ADDR_L = STR_ADDR
STR_ADDR_H = STR_ADDR + 1

CHARS_WIDTH = 16

lda #<(hbcText)
sta STR_ADDR_L
lda #>(hbcText)
sta STR_ADDR_H

jsr lcdWait
lda #LCD_INITIALIZE
sta LCD_CMD

jsr lcdWait
lda #DISPLAY_MODE
sta LCD_CMD

start:

jsr outString

lda #<(helloWorld)
sta STR_ADDR_L
lda #>(helloWorld)
sta STR_ADDR_H

jsr outString

lda #<(anotherText)
sta STR_ADDR_L
lda #>(anotherText)
sta STR_ADDR_H

jsr outString

lda #<(hbcText)
sta STR_ADDR_L
lda #>(hbcText)
sta STR_ADDR_H


jmp start


printLine:
	jsr outString
	cpy #CHARS_WIDTH
	beq +
-
	jsr lcdWait
	lda #' '
	sta LCD_DATA
	
	iny
	cpy #CHARS_WIDTH
	bne -
+
	rts	
	

outString:
	ldy #0

-
	jsr lcdWait
	lda (STR_ADDR), y
	beq .end
	sta LCD_DATA
	iny
	jmp -
	
.end:
	rts
	

lcdWait:
	lda LCD_CMD
	bmi lcdWait  ; branch if bit 7 is set
	rts
	

helloWorld: !text     "Hello, World!       ", 0
hbcText: !text        "Troy's HBC-56       ", 0
anotherText: !text    "Another thing...    ", 0
	

*=$FFFC
!word $8000