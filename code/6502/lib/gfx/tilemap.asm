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

TILEMAP_BUFFER_ADDR	= 0
TILEMAP_SIZE		= TILEMAP_BUFFER_ADDR + 1
TILEMAP_TILES_ADDR	= TILEMAP_SIZE + 1
TILEMAP_INVERT_ADDR	= TILEMAP_TILES_ADDR + 1
TILEMAP_DIRTY_ADDR	= TILEMAP_INVERT_ADDR + 1

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

; Tilemapview structure
; ---------------------
; TilemapAddressH
; ScrollX
; ScrollY
; TileScrollXY




; -------------------------
; Zero page
; -------------------------
TILEMAP_ADDR		= R5
TILEMAP_TMP_BUFFER_ADDR	= R6
TILEMAP_TMP_TILES_ADDR	= R7
TILEMAP_TMP_BUF_ROW	= R8L
TILEMAP_TMP_BUF_COL	= R8H
TILEMAP_TMP_TILE_ROW	= R9L
TILEMAP_TMP_OUTPUT_ROW	= R9H
TILEMAP_TMP_1		= R10L
TILEMAP_TMP_2		= R10H

; Temporary - a single instance
TILEMAP_FIXED_ADDRESS = $2f0
TILEMAP_DEFAULT_BUFFER_ADDRESS = $1000

!macro tilemapCreate .bufferAddr, .tilesetAddr, .sizeFlags, .invertAddr, .dirtyAddr {
	!if <.tilesetAddr != 0 { !error "tilemapCreate: Tileset address must be page-aligned" }
	!if >.tilesetAddr < 3 { !error "tilemapCreate: Tileset address must be greater than $2ff" }
	!if <.bufferAddr != 0 { !error "tilemapCreate: Buffer address must be page-aligned" }
	!if >.bufferAddr < 3 { !error "tilemapCreate: Buffer address must be greater than $2ff" }
	!if .invertAddr != 0 and <.invertAddr != 0  {!error "tilemapCreate: Invert address must be page-aligned"}
	!if .invertAddr != 0 and >.invertAddr < 3  {!error "tilemapCreate: Invert address must be greater than $2ff"}
	!if .dirtyAddr != 0 and <.dirtyAddr != 0  {!error "tilemapCreate: Dirty address must be page-aligned"}
	!if .dirtyAddr != 0 and >.dirtyAddr < 3  {!error "tilemapCreate: Dirty address must be greater than $2ff"}

	lda #<TILEMAP_FIXED_ADDRESS
	sta TILEMAP_ADDR
	lda #>TILEMAP_FIXED_ADDRESS
	sta TILEMAP_ADDR + 1

	lda #>.bufferAddr
	sta TILEMAP_FIXED_ADDRESS + TILEMAP_BUFFER_ADDR
	lda #.sizeFlags
	sta TILEMAP_FIXED_ADDRESS + TILEMAP_SIZE
	lda #>.tilesetAddr
	sta TILEMAP_FIXED_ADDRESS + TILEMAP_TILES_ADDR
	lda #>.invertAddr
	sta TILEMAP_FIXED_ADDRESS + TILEMAP_INVERT_ADDR
	lda #>.dirtyAddr
	sta TILEMAP_FIXED_ADDRESS + TILEMAP_DIRTY_ADDR

	jsr tilemapInit
}

!macro tilemapCreateDefault .size, .tileset {
	+tilemapCreate TILEMAP_DEFAULT_BUFFER_ADDRESS, .tileset, .size, $0, $0
}

; -----------------------------------------------------------------------------
; tilemapInit: Initialise a tilemap
; -----------------------------------------------------------------------------
; Inputs:
;  TILEMAP_ADDR: Address of tilemap structure
; -----------------------------------------------------------------------------
tilemapInit:
	ldy #0
	sty MEMSET_LEN
	sty MEMSET_LEN + 1
	sty MEMSET_DST
	sty TILEMAP_TMP_BUFFER_ADDR
	lda (TILEMAP_ADDR), y  ; buffer address H
	sta MEMSET_DST + 1
	sta TILEMAP_TMP_BUFFER_ADDR

	ldy #TILEMAP_SIZE

	lda #0
	sta MEMSET_LEN + 1
	lda #128
	sta MEMSET_LEN         ; size in bytes
	lda (TILEMAP_ADDR), y  ; size flags
	sta TILEMAP_TMP_1
	beq ++

	lda #0
	sta MEMSET_LEN
	lda #1
	sta MEMSET_LEN + 1

	; check size flags, multiple size
	lda #TILEMAP_SIZE_X_32 | TILEMAP_SIZE_X_64
	bit TILEMAP_TMP_1
	beq +
	asl MEMSET_LEN + 1
	lda #TILEMAP_SIZE_X_64
	bit TILEMAP_TMP_1
	beq +
	asl MEMSET_LEN + 1
+
	lda #TILEMAP_SIZE_Y_16 | TILEMAP_SIZE_Y_32
	bit TILEMAP_TMP_1
	beq ++
	asl MEMSET_LEN + 1
	lda #TILEMAP_SIZE_Y_32
	bit TILEMAP_TMP_1
	beq ++
	asl MEMSET_LEN + 1
++
	lsr MEMSET_LEN + 1

	; here, MEMSET_DST and MEMSET_LEN are set. clear the buffer.
	lda #$cc
	jsr memsetMultiPage

	; todo: invert & dirty

	rts


; -----------------------------------------------------------------------------
; tilemapRender: Render the tilemap
; -----------------------------------------------------------------------------
; Inputs:
;  TILEMAP_ADDR: Address of tilemap structure
; -----------------------------------------------------------------------------
tilemapRender:


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

	ldy #0
	jsr lcdGraphicsSetRow

	; iterate over the buffer rows and columns
-
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
	bne -

	; increment tile row (row within tile) and check against tile size
	lda #0
	sta TILEMAP_TMP_BUF_COL
	inc TILEMAP_TMP_TILE_ROW
	inc TILEMAP_TMP_OUTPUT_ROW
	ldy TILEMAP_TMP_OUTPUT_ROW

	jsr lcdGraphicsSetRow

	lda #TILE_SIZE
	cmp TILEMAP_TMP_TILE_ROW
	bne -

	; increment row and check against # rows
	lda #0
	sta TILEMAP_TMP_TILE_ROW
	inc TILEMAP_TMP_BUF_ROW
	lda #8
	cmp TILEMAP_TMP_BUF_ROW
	bne -

	rts

