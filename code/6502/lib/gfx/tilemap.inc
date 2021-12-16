; 6502 - Tilemap
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
;



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