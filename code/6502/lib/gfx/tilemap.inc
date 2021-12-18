; 6502 - Tilemap
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
;



!macro tilemapCreate .tilemapStructAddr, .bufferAddr, .tilesetAddr, .sizeFlags, .tileSizePx, .invertAddr, .dirtyAddr {
	!if <.tilesetAddr != 0 { !error "tilemapCreate: Tileset address must be page-aligned",.tilesetAddr }
	!if >.tilesetAddr < 3 { !error "tilemapCreate: Tileset address must be greater than $2ff",.tilesetAddr }
	!if <.bufferAddr != 0 { !error "tilemapCreate: Buffer address must be page-aligned",.bufferAddr }
	!if >.bufferAddr < 3 { !error "tilemapCreate: Buffer address must be greater than $2ff",.bufferAddr }
	!if .invertAddr != 0 and <.invertAddr != 0  {!error "tilemapCreate: Invert address must be page-aligned", .invertAddr}
	!if .invertAddr != 0 and >.invertAddr < 3  {!error "tilemapCreate: Invert address must be greater than $2ff", .invertAddr}
	!if .dirtyAddr != 0 and <.dirtyAddr != 0  {!error "tilemapCreate: Dirty address must be page-aligned", .dirtyAddr}
	!if .dirtyAddr != 0 and >.dirtyAddr < 3  {!error "tilemapCreate: Dirty address must be greater than $2ff", .dirtyAddr}
	!if .tileSizePx != 4 and .tileSizePx != 8 {!error "tilemapCreate: Tile size must be 4 or 8 pixels",.tileSizePx}

	lda #<.tilemapStructAddr
	sta TILEMAP_ADDR
	lda #>.tilemapStructAddr
	sta TILEMAP_ADDR + 1

	lda #>.bufferAddr
	sta .tilemapStructAddr + TILEMAP_BUFFER_ADDR
	lda #.sizeFlags
	sta .tilemapStructAddr + TILEMAP_SIZE
	lda #>.tilesetAddr
	sta .tilemapStructAddr + TILEMAP_TILES_ADDR
	lda #>.invertAddr
	sta .tilemapStructAddr + TILEMAP_INVERT_ADDR
	lda #>.dirtyAddr
	sta .tilemapStructAddr + TILEMAP_DIRTY_ADDR
	lda #.tileSizePx
	sta .tilemapStructAddr + TILEMAP_TILE_SIZE_PX

	jsr tilemapInit
}

!macro tilemapCreateDefault .sizeFlags, .tilesetAddr {
	+tilemapCreate TILEMAP_FIXED_ADDRESS, TILEMAP_DEFAULT_BUFFER_ADDRESS, .tilesetAddr, .sizeFlags, 8, $0, $0
}

!macro tilemapSetActive .tilemapStructAddr {
	lda #<.tilemapStructAddr
	sta TILEMAP_ADDR
	lda #>.tilemapStructAddr
	sta TILEMAP_ADDR + 1

	jsr tilemapSetActive
}