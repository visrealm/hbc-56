; 6502 - Bitmap
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
;

; Bitmap object has the following structure
;
; Width
; Height

HAVE_BITMAP = 1

!ifndef BITMAP_ZP_START { BITMAP_ZP_START = $28
        !warn "BITMAP_ZP_START not provided. Defaulting to ", BITMAP_ZP_START
}

!ifndef BITMAP_RAM_START { BITMAP_RAM_START = $7b80
        !warn "BITMAP_RAM_START not provided. Defaulting to ", BITMAP_RAM_START
}

; -------------------------
; Zero page
; -------------------------
PIX_ADDR		= BITMAP_ZP_START
BITMAP_ADDR_H   	= BITMAP_ZP_START+2
BITMAP_ZP_SIZE		= 4

; -----------------------------------------------------------------------------
; High RAM
; -----------------------------------------------------------------------------

BITMAP_X       = BITMAP_RAM_START + 1
BITMAP_Y       = BITMAP_RAM_START + 2
BITMAP_X1      = BITMAP_X
BITMAP_Y1      = BITMAP_Y
BITMAP_X2      = BITMAP_RAM_START + 3
BITMAP_Y2      = BITMAP_RAM_START + 4

BITMAP_LINE_STYLE     = BITMAP_RAM_START + 7
BITMAP_LINE_STYLE_ODD = BITMAP_RAM_START + 8

BITMAP_TMP1    = BITMAP_RAM_START + 9
BITMAP_TMP2    = BITMAP_RAM_START + 10
BITMAP_TMP3    = BITMAP_RAM_START + 11
BITMAP_TMP4    = BITMAP_RAM_START + 12
BITMAP_TMP5    = BITMAP_RAM_START + 13
BITMAP_TMP6    = BITMAP_RAM_START + 14

BITMAP_RAM_SIZE	= 16


!if BITMAP_ZP_END < (BITMAP_ZP_START + BITMAP_ZP_SIZE) {
	!error "BITMAP_ZP requires ",BITMAP_ZP_SIZE," bytes. Allocated ",BITMAP_ZP_END - BITMAP_ZP_START
}

!if BITMAP_RAM_END < (BITMAP_RAM_START + BITMAP_RAM_SIZE) {
	!error "BITMAP_RAM requires ",BITMAP_RAM_SIZE," bytes. Allocated ",BITMAP_RAM_END - BITMAP_RAM_START
}



; -----------------------------------------------------------------------------
; bitmapClear: Clear the bitmap
; -----------------------------------------------------------------------------
; Inputs:
;  BITMAP_ADDR_H: Contains page-aligned address of 1-bit 128x64 bitmap
; -----------------------------------------------------------------------------
bitmapClear:
    	lda #$ff
	sta BITMAP_LINE_STYLE
	lda #0
	
	; flow through.... danger?
	
	
; -----------------------------------------------------------------------------
; bitmapFill: Fill the bitmap with value in A
; -----------------------------------------------------------------------------
; Inputs:
;  BITMAP_ADDR_H: Contains page-aligned address of 1-bit 128x64 bitmap
;  A: The value to fill
; -----------------------------------------------------------------------------
bitmapFill:
	sta BITMAP_TMP1
	lda BITMAP_ADDR_H
	sta PIX_ADDR + 1
	ldx #0
	stx PIX_ADDR

	lda BITMAP_TMP1	
	ldy #0
	ldx #4
-
	sta (PIX_ADDR), y
	iny
	bne -
	inc PIX_ADDR + 1
	dex
	bne -
	
	rts
	
	
; -----------------------------------------------------------------------------
; bitmapXor: XOR (invert) the entire bitmap
; -----------------------------------------------------------------------------
; Inputs:
;  BITMAP_ADDR_H: Contains page-aligned address of 1-bit 128x64 bitmap
; -----------------------------------------------------------------------------
bitmapXor:
	lda BITMAP_ADDR_H
	sta PIX_ADDR + 1
	ldx #0
	stx PIX_ADDR

	ldy #0
	ldx #4
-
	lda #$ff
	eor (PIX_ADDR), y
	sta (PIX_ADDR), y
	
	iny
	bne -
	inc PIX_ADDR + 1
	dex
	bne -
	
	rts
	
; -----------------------------------------------------------------------------
; _bitmapOffset: Set up the offset to the buffer based on X/Y (Internal use)
; -----------------------------------------------------------------------------
; Inputs:
;  BITMAP_ADDR_H: Contains page-aligned address of 1-bit 128x64 bitmap
;  BITMAP_X: X position (0 to 127)
;  BITMAP_Y: Y position (0 to 63)
; Outputs:
;  PIX_ADDR: Set to byte at column 0 of row BITMAP_Y
;  Y: 		 Y offset of byte within row (0 to 63)
;  X: 		 Bit offset within the byte
; -----------------------------------------------------------------------------
_bitmapOffset:

	lda BITMAP_ADDR_H
	sta PIX_ADDR + 1
	ldx #0
	stx PIX_ADDR
	
	lda BITMAP_Y
	lsr
	lsr
	lsr
	lsr
	clc
	adc PIX_ADDR + 1
	sta PIX_ADDR + 1
	
	lda BITMAP_Y
	and #$0f
	asl
	asl
	asl
	asl
	sta PIX_ADDR
	
	lda BITMAP_X
	lsr
	lsr
	lsr
	tay	  ; Y contains start byte offset in row
	
	lda BITMAP_X
	and #$07
	tax   ; X contains bit offset within byte (0 - 7)	
	rts
	
; -----------------------------------------------------------------------------
; bitmapSetPixel: Set a pixel
; -----------------------------------------------------------------------------
; Inputs:
;  BITMAP_ADDR_H: Contains page-aligned address of 1-bit 128x64 bitmap
;  BITMAP_X: X position (0 to 127)
;  BITMAP_Y: Y position (0 to 63)
; -----------------------------------------------------------------------------
bitmapSetPixel:

	jsr _bitmapOffset
	
	lda tableBitFromLeft, x
	
	ora (PIX_ADDR), y
	sta (PIX_ADDR), y
	
	rts	
	
; -----------------------------------------------------------------------------
; bitmapClearPixel: Clear a pixel
; -----------------------------------------------------------------------------
; Inputs:
;  BITMAP_ADDR_H: Contains page-aligned address of 1-bit 128x64 bitmap
;  BITMAP_X: X position (0 to 127)
;  BITMAP_Y: Y position (0 to 63)
; -----------------------------------------------------------------------------
bitmapClearPixel:

	jsr _bitmapOffset
	
	lda tableInvBitFromLeft, x

	and (PIX_ADDR), y
	sta (PIX_ADDR), y
	
	rts
	
	
; -----------------------------------------------------------------------------
; bitmapXorPixel: XOR a pixel
; -----------------------------------------------------------------------------
; Inputs:
;  BITMAP_ADDR_H: Contains page-aligned address of 1-bit 128x64 bitmap
;  BITMAP_X: X position (0 to 127)
;  BITMAP_Y: Y position (0 to 63)
; -----------------------------------------------------------------------------
bitmapXorPixel:

	jsr _bitmapOffset
	
	lda tableBitFromLeft, x

	eor (PIX_ADDR), y
	sta (PIX_ADDR), y
	
	rts
	
; -----------------------------------------------------------------------------
; bitmapLineH: Output a horizontal line
; -----------------------------------------------------------------------------
; Inputs:
;  BITMAP_ADDR_H: Contains page-aligned address of 1-bit 128x64 bitmap
;  BITMAP_X1: Start X position (0 to 127)
;  BITMAP_X2: End X position (0 to 127)
;  BITMAP_Y:  Y position (0 to 63)
; -----------------------------------------------------------------------------
bitmapLineH:

	END_OFFSET   = BITMAP_TMP3
	START_BYTE   = BITMAP_TMP1
	END_BYTE     = BITMAP_TMP2
	TMP_STYLE    = BITMAP_TMP5

	lda BITMAP_X2
	lsr
	lsr
	lsr
	sta END_OFFSET  ; END_OFFSET contains end byte offset within the row

	jsr _bitmapOffset

	lda BITMAP_LINE_STYLE
	sta TMP_STYLE
	
	lda #$ff
	
; shift the bits to the right for the pixel offset
-
	cpx #0
	beq ++
	lsr TMP_STYLE
	bcc +
	pha
	lda #$80
	ora TMP_STYLE
	sta TMP_STYLE
	pla	
+
	dex
	lsr
	bcs -  ; carry is always set
++
	sta START_BYTE

	lda BITMAP_X2
	and #$07
	
	tax   ; X contains bit offset within byte (0 - 7)	
	
	lda #$ff
	
; shift the bits to the left for the pixel offset
-
	cpx #7
	beq +
	inx
	asl    
	bcs -  ; carry is always set
+
	sta END_BYTE
	
	lda START_BYTE
	cpy END_OFFSET
	bne ++
	and END_BYTE  ; combine if within the same byte
	
	pha
	eor #$ff
	and (PIX_ADDR), y
	sta BITMAP_TMP4
	pla
	and TMP_STYLE
	ora BITMAP_TMP4
	sta (PIX_ADDR), y
	
	rts
++
	pha
	eor #$ff
	and (PIX_ADDR), y
	sta BITMAP_TMP4
	pla
	and TMP_STYLE
	ora BITMAP_TMP4
	sta (PIX_ADDR), y
-
	lda #$ff
	iny
	cpy END_OFFSET
	bne +
	and END_BYTE  ; combine if within the same byte
+
	pha
	eor #$ff
	and (PIX_ADDR), y
	sta BITMAP_TMP4
	pla
	and TMP_STYLE
	ora BITMAP_TMP4
	sta (PIX_ADDR), y

	cpy END_OFFSET
	bne -	
	
	rts
	
	
; -----------------------------------------------------------------------------
; bitmapLineV: Output a horizontal line
; -----------------------------------------------------------------------------
; Inputs:
;  BITMAP_ADDR_H: Contains page-aligned address of 1-bit 128x64 bitmap
;  BITMAP_Y1: Start Y position (0 to 63)
;  BITMAP_Y2: End Y position (0 to 63)
;  BITMAP_X:  Y position (0 to 127)
; -----------------------------------------------------------------------------
bitmapLineV:

	COL_BYTE     = BITMAP_TMP1
	STYLE_BYTE   = BITMAP_TMP2

	jsr _bitmapOffset
	
	lda BITMAP_LINE_STYLE
	sta STYLE_BYTE
	
	lda tableBitFromLeft, x

	sta COL_BYTE	
	
	ldx BITMAP_Y1
-
	lda #$80
	bit STYLE_BYTE
	bne +
	; draw a 0
	lda COL_BYTE
	eor #$ff
	and (PIX_ADDR), y	
	sta (PIX_ADDR), y
	jmp ++
+	; draw a 1
	lda COL_BYTE	
	ora (PIX_ADDR), y	
	sta (PIX_ADDR), y
++
		
	cpx BITMAP_Y2
	beq ++
	asl STYLE_BYTE
	bcc +
	inc STYLE_BYTE
+
	inx
	lda #16
	clc
	adc PIX_ADDR
	bcc +
	inc PIX_ADDR + 1
+
	sta PIX_ADDR
    	clc
	bcc -
++
	
	rts

; -----------------------------------------------------------------------------
; bitmapLine: Output an arbitrary line
; -----------------------------------------------------------------------------
; Inputs:
;  BITMAP_ADDR_H: Contains page-aligned address of 1-bit 128x64 bitmap
;  BITMAP_X1: 
;  BITMAP_Y1: 
;  BITMAP_X2: 
;  BITMAP_Y2: 
; -----------------------------------------------------------------------------
bitmapLine:

	LINE_WIDTH = BITMAP_TMP1
	LINE_HEIGHT = BITMAP_TMP2
	
	; get width
	lda BITMAP_X2
	sec
	sbc BITMAP_X1
	
	bpl +
	lda BITMAP_X1
	pha
	lda BITMAP_X2
	sta BITMAP_X1
	pla
	sta BITMAP_X2
	sec
	sbc BITMAP_X1	
+	
	sta LINE_WIDTH

	; get height
	lda BITMAP_Y2
	sec
	sbc BITMAP_Y1

	bpl +
	lda BITMAP_Y1
	pha
	lda BITMAP_Y2
	sta BITMAP_Y1
	pla
	sta BITMAP_Y2
	sec
	sbc BITMAP_Y1	
+	
	sta LINE_HEIGHT
	
	cmp LINE_WIDTH
	bcs .goTall
	jmp _bitmapLineWide
.goTall
	jmp _bitmapLineTall
	
	; rts in above subroutines
	
; ----------------------------------------------------------------------------

_bitmapLineWide:  ; a line that is wider than it is tall
	
	D = BITMAP_TMP6
	
	Y = BITMAP_TMP3
	
	lda LINE_HEIGHT
	asl
	sec
	sbc LINE_WIDTH
	sta D
	
	lda BITMAP_X
	pha
	
	lda BITMAP_Y1
	sta Y
	
-
	jsr bitmapSetPixel
	lda D
	bpl +
	lda LINE_HEIGHT
	asl
	jmp ++
+
    inc BITMAP_Y1
	lda LINE_WIDTH
	sec
	sbc LINE_HEIGHT
	asl
	eor #$ff
	clc
	adc #1
++
	clc
	adc D
	sta D
	inc BITMAP_X
	lda BITMAP_X2
	cmp BITMAP_X
	bcs -
	
	lda Y
	sta BITMAP_Y1
	
	pla
	sta BITMAP_X
	
	rts
	
_bitmapLineTall:  ; a line that is taller than it is wide
	
	D = BITMAP_TMP6
	
	X = BITMAP_TMP3
	
	lda LINE_WIDTH
	asl
	sec
	sbc LINE_HEIGHT
	sta D
	
	lda BITMAP_Y
	pha
	
	lda BITMAP_X1
	sta X
	
-
	jsr bitmapSetPixel
	lda D
	bpl +
	lda LINE_WIDTH
	asl
	jmp ++
+
    inc BITMAP_X1
	lda LINE_HEIGHT
	sec
	sbc LINE_WIDTH
	asl
	eor #$ff
	clc
	adc #1
++
	clc
	adc D
	sta D
	inc BITMAP_Y
	lda BITMAP_Y2
	cmp BITMAP_Y
	bcs -

	lda X
	sta BITMAP_X1
	
	pla
	sta BITMAP_Y
	
	rts
	
; -----------------------------------------------------------------------------
; bitmapRect: Output a rectangle outline
; -----------------------------------------------------------------------------
; Inputs:
;  BITMAP_ADDR_H: Contains page-aligned address of 1-bit 128x64 bitmap
;  BITMAP_X1: 
;  BITMAP_Y1: 
;  BITMAP_X2: 
;  BITMAP_Y2: 
; -----------------------------------------------------------------------------
bitmapRect:
	jsr bitmapLineH
	jsr bitmapLineV
	
	lda BITMAP_X1
	pha
	lda BITMAP_X2
	sta BITMAP_X1

	jsr bitmapLineV
	
	pla
	sta BITMAP_X1

	lda BITMAP_Y1
	pha
	lda BITMAP_Y2
	sta BITMAP_Y1
	
	jsr bitmapLineH

	pla
	sta BITMAP_Y1
	
	rts
	
; -----------------------------------------------------------------------------
; bitmapFilledRect: Output a filled rectangle
; -----------------------------------------------------------------------------
; Inputs:
;  BITMAP_ADDR_H: Contains page-aligned address of 1-bit 128x64 bitmap
;  BITMAP_X1: 
;  BITMAP_Y1: 
;  BITMAP_X2: 
;  BITMAP_Y2: 
; -----------------------------------------------------------------------------
bitmapFilledRect:
	lda BITMAP_Y1
	pha
	lda BITMAP_LINE_STYLE
	pha
	
-
	jsr bitmapLineH
	inc BITMAP_Y1

	pla
	sta BITMAP_LINE_STYLE
	pha
	
	lda BITMAP_Y2
	cmp BITMAP_Y1
	beq +

	jsr bitmapLineH
	inc BITMAP_Y1
	
	lda BITMAP_LINE_STYLE_ODD
	sta BITMAP_LINE_STYLE
	
	lda BITMAP_Y2
	cmp BITMAP_Y1
	bne -
+	

	pla
	sta BITMAP_LINE_STYLE
	pla
	sta BITMAP_Y1
	
	rts