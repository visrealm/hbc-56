; Troy's HBC-56 - 6502 - Invaders - Aliens
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
;


INVADER1_TYPE = INVADER1
INVADER2_TYPE = INVADER2 
INVADER3_TYPE = INVADER3

INVADER1_PATT = 128
INVADER2_PATT = 136
INVADER3_PATT = 144


; -----------------------------------------------------------------------------
; Aliens setup
; -----------------------------------------------------------------------------
setupAliens:

        ; setup alien types
        lda #<INVADER1_TYPE
        sta INV1_BASE_ADDR_L
        lda #>INVADER1_TYPE
        sta INV1_BASE_ADDR_H

        lda #<INVADER2_TYPE
        sta INV2_BASE_ADDR_L
        lda #>INVADER2_TYPE
        sta INV2_BASE_ADDR_H

        lda #<INVADER3_TYPE
        sta INV3_BASE_ADDR_L
        lda #>INVADER3_TYPE
        sta INV3_BASE_ADDR_H

        ; colors
        +tmsSetAddrColorTable 16
        ldy #INVADER_OFFSET_COLOR
        lda (INV1_BASE_ADDR_L), y
        +tmsPut
        lda (INV2_BASE_ADDR_L), y
        +tmsPut
        lda (INV3_BASE_ADDR_L), y
        +tmsPut

        jsr aliensSetTiles0

        rts

; -----------------------------------------------------------------------------
; aliensUpdateTileset: Update patterns for a single alien type
; -----------------------------------------------------------------------------
!macro aliensUpdateAlienTileset .patternIndex, .baseAddress, .offset {
        +tmsSetAddrPattTable .patternIndex
        +tmsSetSourceAddressIndOffset .baseAddress, .offset
        +tmsSendBytes 16
}

; -----------------------------------------------------------------------------
; aliensUpdateTileset: Update patterns for all aliens
; -----------------------------------------------------------------------------
!macro aliensUpdateTileset .offset {
        +aliensUpdateAlienTileset INVADER1_PATT, INV1_BASE_ADDR_L, .offset
        +aliensUpdateAlienTileset INVADER2_PATT, INV2_BASE_ADDR_L, .offset
        +aliensUpdateAlienTileset INVADER3_PATT, INV3_BASE_ADDR_L, .offset
}

; -----------------------------------------------------------------------------
; alienColor: Get the color for the given alien type
; -----------------------------------------------------------------------------
; Inputs:
;  A: tile index
; Outputs:
;  A: color
; -----------------------------------------------------------------------------
alien1Color:
        lda (INV1_BASE_ADDR_L), y
        +lsr4
        rts

alien2Color:
        lda (INV2_BASE_ADDR_L), y
        +lsr4
        rts

alien3Color:
        lda (INV3_BASE_ADDR_L), y
        +lsr4
        rts

alienColor:
        ldy #INVADER_OFFSET_COLOR

        cmp #INVADER2_PATT
        bcc alien1Color
        cmp #INVADER3_PATT
        bcc alien2Color

        jmp alien3Color

; -----------------------------------------------------------------------------
; Alien tileset 0: Base offset
; -----------------------------------------------------------------------------
aliensSetTiles0:
        +aliensUpdateTileset 0
        lda #0
        sta INVADER_PIXEL_OFFSET
        rts

; -----------------------------------------------------------------------------
; Alien tileset 1: 2px offset
; -----------------------------------------------------------------------------
aliensSetTiles1:
        +aliensUpdateTileset INVADER_OFFSET_2
        lda #2
        sta INVADER_PIXEL_OFFSET
        rts

; -----------------------------------------------------------------------------
; Alien tileset 2: 4px offset
; -----------------------------------------------------------------------------
aliensSetTiles2:
        +aliensUpdateTileset INVADER_OFFSET_4
        lda #4
        sta INVADER_PIXEL_OFFSET
        rts

; -----------------------------------------------------------------------------
; Alien tileset 3: 6px offset
; -----------------------------------------------------------------------------
aliensSetTiles3:
        +aliensUpdateTileset INVADER_OFFSET_6
        lda #6
        sta INVADER_PIXEL_OFFSET
        rts

