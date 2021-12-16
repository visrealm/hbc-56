; 6502 - Tilemap
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
;
; Tilemap structure
; ---------------------
; BufferAddressH   (Page-aligned buffer - MSB)
; Size
; TilesetAddressH  (Page-aligned tilset - MSB)
; InvertAddressH   (Page-aligned invert flags - MSB) (optional)
; DirtyAddressH    (Page-aligned dirty flags - MSB)  (optional)

!src "gfx/tilemap.inc"


!ifndef TILEMAP_ZP_START { TILEMAP_ZP_START = $f0
        !warn "TILEMAP_ZP_START not provided. Defaulting to ", TILEMAP_ZP_START
}

!ifndef TILEMAP_RAM_START { TILEMAP_RAM_START = $7d00
        !warn "TILEMAP_RAM_START not provided. Defaulting to ", TILEMAP_RAM_START
}

!if (TILEMAP_RAM_START & $ff) != 0 {
        !error "TILEMAP_RAM_START must be on a page boundary"
}

; -------------------------
; Zero page
; -------------------------
TILEMAP_ADDR		= TILEMAP_ZP_START
TILEMAP_TMP_BUFFER_ADDR	= TILEMAP_ZP_START + 2
TILEMAP_TMP_TILES_ADDR	= TILEMAP_ZP_START + 4
TILEMAP_ZP_SIZE		= 6

; -----------------------------------------------------------------------------
; High RAM
; -----------------------------------------------------------------------------
TILEMAP_DEFAULT_BUFFER_ADDRESS = TILEMAP_RAM_START

TILEMAP_TMP_BUF_ROW	= TILEMAP_RAM_START + $80
TILEMAP_TMP_BUF_COL	= TILEMAP_RAM_START + $81
TILEMAP_TMP_TILE_ROW	= TILEMAP_RAM_START + $82
TILEMAP_TMP_OUTPUT_ROW	= TILEMAP_RAM_START + $83
TILEMAP_TMP_1		= TILEMAP_RAM_START + $84
TILEMAP_TMP_2		= TILEMAP_RAM_START + $85

TILEMAP_FIXED_ADDRESS          = TILEMAP_RAM_START + $100


TILEMAP_RAM_SIZE               = $116


!if TILEMAP_ZP_END < (TILEMAP_ZP_START + TILEMAP_ZP_SIZE) {
	!error "TILEMAP_ZP requires ",TILEMAP_ZP_SIZE," bytes. Allocated ",TILEMAP_ZP_END - TILEMAP_ZP_START
}

!if TILEMAP_RAM_END < (TILEMAP_RAM_START + TILEMAP_RAM_SIZE) {
	!error "TILEMAP_RAM requires ",TILEMAP_RAM_SIZE," bytes. Allocated ",TILEMAP_RAM_END - TILEMAP_RAM_START
}

; -------------------------
; Tilemap structure
; -------------------------
TILEMAP_BUFFER_ADDR	= 0				; High byte of page-aligned buffer
TILEMAP_SIZE		= TILEMAP_BUFFER_ADDR + 1	; Size flags
TILEMAP_TILES_ADDR	= TILEMAP_SIZE + 1
TILEMAP_INVERT_ADDR	= TILEMAP_TILES_ADDR + 1	; High byte of tilemap
TILEMAP_DIRTY_ADDR	= TILEMAP_INVERT_ADDR + 1
TILEMAP_STRUCTURE_SIZE  = TILEMAP_DIRTY_ADDR

; -------------------------
; Contants
; -------------------------
TILEMAP_SIZE_X_16	= %00000000
TILEMAP_SIZE_X_32	= %00000001
TILEMAP_SIZE_X_64	= %00000010
TILEMAP_SIZE_Y_8	= %00000000
TILEMAP_SIZE_Y_16	= %00000100
TILEMAP_SIZE_Y_32	= %00001000

TILE_SIZE		= 8	; size of each tile (in px)




; -----------------------------------------------------------------------------
; tilemapInit: Initialise a tilemap
; -----------------------------------------------------------------------------
; Inputs:
;  TILEMAP_ADDR: Address of tilemap structure
; -----------------------------------------------------------------------------
tilemapInit:
	ldy #0
	sty MEM_LEN
	sty MEM_LEN + 1
	sty MEM_DST
	lda (TILEMAP_ADDR), y  ; buffer address H
	sta MEM_DST + 1
	sta TILEMAP_TMP_BUFFER_ADDR 

	ldy #TILEMAP_SIZE

	lda #0
	sta MEM_LEN + 1
	lda #128
	sta MEM_LEN         ; size in bytes
	lda (TILEMAP_ADDR), y  ; size flags
	sta TILEMAP_TMP_1
	beq ++

	lda #0
	sta MEM_LEN
	lda #1
	sta MEM_LEN + 1

	; check size flags, multiple size
	lda #TILEMAP_SIZE_X_32 | TILEMAP_SIZE_X_64
	bit TILEMAP_TMP_1
	beq +
	asl MEM_LEN + 1
	lda #TILEMAP_SIZE_X_64
	bit TILEMAP_TMP_1
	beq +
	asl MEM_LEN + 1
+
	lda #TILEMAP_SIZE_Y_16 | TILEMAP_SIZE_Y_32
	bit TILEMAP_TMP_1
	beq ++
	asl MEM_LEN + 1
	lda #TILEMAP_SIZE_Y_32
	bit TILEMAP_TMP_1
	beq ++
	asl MEM_LEN + 1
++
	lsr MEM_LEN + 1

	; here, MEM_DST and MEM_LEN are set. clear the buffer.
	lda #$cc
	jsr memsetMultiPage

	; todo: invert & dirty

	rts


; -----------------------------------------------------------------------------
; tilemapRenderRow: Render a row of the tilemap
; -----------------------------------------------------------------------------
; Inputs:
;  TILEMAP_ADDR: Address of tilemap structure
;  y: Row to render (0-7)
; -----------------------------------------------------------------------------
tilemapRenderRow:
	tya
	and #$07
	sta TILEMAP_TMP_BUF_ROW
	sta TILEMAP_TMP_2
	asl
	asl
	asl
	sta TILEMAP_TMP_OUTPUT_ROW

	inc TILEMAP_TMP_2

	; set the working tilemap buffer address
	ldy #TILEMAP_BUFFER_ADDR
	lda (TILEMAP_ADDR), y
	sta TILEMAP_TMP_BUFFER_ADDR + 1

	; reset temp variables to zero
	lda #0
	sta TILEMAP_TMP_BUFFER_ADDR ; LSB
	sta TILEMAP_TMP_TILES_ADDR  ; LSB
	sta TILEMAP_TMP_BUF_COL
	sta TILEMAP_TMP_TILE_ROW

	jmp .tilemapRenderFrom


; -----------------------------------------------------------------------------
; tilemapRender: Render the tilemap
; -----------------------------------------------------------------------------
; Inputs:
;  TILEMAP_ADDR: Address of tilemap structure
; -----------------------------------------------------------------------------
tilemapRender:


	lda #8
	sta TILEMAP_TMP_2

	; set the working tilemap buffer address
	ldy #TILEMAP_BUFFER_ADDR
	lda (TILEMAP_ADDR), y
	sta TILEMAP_TMP_BUFFER_ADDR + 1
	
	; reset temp variables to zero
	lda #0
	sta TILEMAP_TMP_BUFFER_ADDR ; LSB
	sta TILEMAP_TMP_TILES_ADDR  ; LSB
	sta TILEMAP_TMP_BUF_ROW
	sta TILEMAP_TMP_BUF_COL
	sta TILEMAP_TMP_TILE_ROW
	sta TILEMAP_TMP_OUTPUT_ROW

.tilemapRenderFrom
	ldy TILEMAP_TMP_OUTPUT_ROW
	jsr lcdGraphicsSetRow

	; iterate over the buffer rows and columns
.renderRow
	lda #0
	sta TILEMAP_TMP_1

	; set the working tileset address
	ldy #TILEMAP_TILES_ADDR
	lda (TILEMAP_ADDR), y
	sta TILEMAP_TMP_TILES_ADDR + 1

	; get tile offset
	lda TILEMAP_TMP_BUF_ROW
	asl
	asl
	asl
	asl
	clc
	adc TILEMAP_TMP_BUF_COL
	tay


	; load the tile index
	lda (TILEMAP_TMP_BUFFER_ADDR), y

	; multiply by 8 to get an offset into the tileset buffer
	; storing overflow in TILEMAP_TMP_1
	asl
	rol TILEMAP_TMP_1
	asl 
	rol TILEMAP_TMP_1
	asl
	rol TILEMAP_TMP_1

	; add the tile row offset (the row of the current tile)
	; and set as y index
	ora TILEMAP_TMP_TILE_ROW
	tay

	; load the overflow and add to the MSB of the tileset address
	lda TILEMAP_TMP_1
	clc
	adc TILEMAP_TMP_TILES_ADDR + 1
	sta TILEMAP_TMP_TILES_ADDR + 1

	jsr lcdWait

	; load the byte from the tile
	lda (TILEMAP_TMP_TILES_ADDR), y

	; output the byte
	sta LCD_DATA

	; increment column and check against # columns
	inc TILEMAP_TMP_BUF_COL
	lda #16
	cmp TILEMAP_TMP_BUF_COL
	bne .renderRow

	; increment tile row (row within tile) and check against tile size
	lda #0
	sta TILEMAP_TMP_BUF_COL
	inc TILEMAP_TMP_TILE_ROW
	inc TILEMAP_TMP_OUTPUT_ROW
	ldy TILEMAP_TMP_OUTPUT_ROW

	jsr lcdGraphicsSetRow

	lda #TILE_SIZE
	cmp TILEMAP_TMP_TILE_ROW
	bne .renderRow

	; increment row and check against # rows
	lda #0
	sta TILEMAP_TMP_TILE_ROW
	inc TILEMAP_TMP_BUF_ROW
	lda TILEMAP_TMP_2
	cmp TILEMAP_TMP_BUF_ROW
	bne .renderRow

	rts

