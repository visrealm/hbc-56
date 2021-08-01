!cpu 6502
!initmem $FF
!to "lcd12864.o", plain

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

LCD_CMD_SET_CGRAM_ADDR       = $40
LCD_CMD_SET_DRAM_ADDR        = $80

LCD_CMD_FUNCTIONSET     = $20
LCD_CMD_8BITMODE        = $10
LCD_CMD_2LINE           = $08
LCD_CMD_12864B_EXTENDED = $02

LCD_INITIALIZE      = LCD_CMD_FUNCTIONSET | LCD_CMD_8BITMODE | LCD_CMD_2LINE
LCD_BASIC           = LCD_INITIALIZE
LCD_EXTENDED        = LCD_INITIALIZE | LCD_CMD_12864B_EXTENDED

DISPLAY_MODE  = <(LCD_CMD_DISPLAY | LCD_CMD_DISPLAY_ON) ; | LCD_CMD_DISPLAY_CURSOR | LCD_CMD_DISPLAY_CURSOR_BLINK)

STR_ADDR = $10
STR_ADDR_L = STR_ADDR
STR_ADDR_H = STR_ADDR + 1

LCD_ADDR_LINE1 = 0x00
LCD_ADDR_LINE2 = 0x10
LCD_ADDR_LINE3 = 0x08
LCD_ADDR_LINE4 = 0x18

CHARS_WIDTH = 16

jsr lcdWait
lda #LCD_INITIALIZE
sta LCD_CMD

jsr lcdWait
lda #LCD_CMD_CLEAR
sta LCD_CMD

jsr lcdWait
lda #LCD_CMD_HOME
sta LCD_CMD

jsr lcdWait
lda #DISPLAY_MODE
sta LCD_CMD

start:

jsr lcdWait

lda #<hbcText
sta STR_ADDR_L
lda #>hbcText
sta STR_ADDR_H

;jsr lcdLineTwo
jsr nextLine4

jsr outString


jsr lcdWait

lda #<helloWorld
sta STR_ADDR_L
lda #>helloWorld
sta STR_ADDR_H

;jsr lcdLineOne
jsr nextLine4

jsr outString


jsr lcdWait

lda #<anotherText
sta STR_ADDR_L
lda #>anotherText
sta STR_ADDR_H

jsr nextLine4
;jsr lcdLineOne

jsr outString

jmp start


lcdLineOne:
	lda #(LCD_CMD_SET_DRAM_ADDR | LCD_ADDR_LINE1)
	sta LCD_CMD
	rts

lcdLineTwo:
	lda #(LCD_CMD_SET_DRAM_ADDR | LCD_ADDR_LINE2)
	sta LCD_CMD
	rts
	
lcdLineThree:
	lda #(LCD_CMD_SET_DRAM_ADDR | LCD_ADDR_LINE3)
	sta LCD_CMD
	rts

lcdLineFour:
	lda #(LCD_CMD_SET_DRAM_ADDR | LCD_ADDR_LINE4)
	sta LCD_CMD
	rts


; Go to next line

nextLine4:
	jsr lcdWait
	; A now contains address
	cmp #LCD_ADDR_LINE4
	bcs lcdLineOne
	cmp #LCD_ADDR_LINE2
	bcs lcdLineThree
	cmp #LCD_ADDR_LINE3
	bcs lcdLineFour
	
	jmp lcdLineTwo

; ---------------------------------

nextLine2:
	jsr lcdWait
	; A now contains address
	cmp #LCD_ADDR_LINE2
	bcs lcdLineOne
	jmp lcdLineTwo

; ---------------------------------

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
	adc #1
	sta LCD_DATA
	iny
	jmp -
	
.end:
	rts
	

lcdWait:
	lda LCD_CMD
	bmi lcdWait  ; branch if bit 7 is set
	rts
	

helloWorld: !text     "Hello, World!", 0,0
hbcText: !text        "Troy's HBC-56", 0,0
anotherText: !text    "Another thing..", 0,0

!text    "Huh?", 0


*=$FFFC
!word $8000