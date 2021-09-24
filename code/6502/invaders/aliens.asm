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
; Alien tileset 0: Base offset
; -----------------------------------------------------------------------------
aliensSetTiles0:
        +tmsSetAddrPattTableInd INVADER1_PATT
        +tmsSetSourceAddressInd INV1_BASE_ADDR_L
        +tmsSendBytes 16
        +tmsSetAddrPattTableInd INVADER2_PATT
        +tmsSetSourceAddressInd INV2_BASE_ADDR_L
        +tmsSendBytes 16
        +tmsSetAddrPattTableInd INVADER3_PATT
        +tmsSetSourceAddressInd INV3_BASE_ADDR_L
        +tmsSendBytes 16

        lda #0
        sta INVADER_PIXEL_OFFSET
        rts

; -----------------------------------------------------------------------------
; Alien tileset 1: 2px offset
; -----------------------------------------------------------------------------
aliensSetTiles1:
        +tmsSetAddrPattTableInd INVADER1_PATT
        +tmsSetSourceAddressIndOffset INV1_BASE_ADDR_L, INVADER_OFFSET_2
        +tmsSendBytes 16
        +tmsSetAddrPattTableInd INVADER2_PATT
        +tmsSetSourceAddressIndOffset INV2_BASE_ADDR_L, INVADER_OFFSET_2
        +tmsSendBytes 16
        +tmsSetAddrPattTableInd INVADER3_PATT
        +tmsSetSourceAddressIndOffset INV3_BASE_ADDR_L, INVADER_OFFSET_2
        +tmsSendBytes 16
        lda #2
        sta INVADER_PIXEL_OFFSET
        rts

; -----------------------------------------------------------------------------
; Alien tileset 2: 4px offset
; -----------------------------------------------------------------------------
aliensSetTiles2:
        +tmsSetAddrPattTableInd INVADER1_PATT
        +tmsSetSourceAddressIndOffset INV1_BASE_ADDR_L, INVADER_OFFSET_4
        +tmsSendBytes 16
        +tmsSetAddrPattTableInd INVADER2_PATT
        +tmsSetSourceAddressIndOffset INV2_BASE_ADDR_L, INVADER_OFFSET_4
        +tmsSendBytes 16
        +tmsSetAddrPattTableInd INVADER3_PATT
        +tmsSetSourceAddressIndOffset INV3_BASE_ADDR_L, INVADER_OFFSET_4
        +tmsSendBytes 16
        lda #4
        sta INVADER_PIXEL_OFFSET
        rts

; -----------------------------------------------------------------------------
; Alien tileset 3: 6px offset
; -----------------------------------------------------------------------------
aliensSetTiles3:
        +tmsSetAddrPattTableInd INVADER1_PATT
        +tmsSetSourceAddressIndOffset INV1_BASE_ADDR_L, INVADER_OFFSET_6
        +tmsSendBytes 16
        +tmsSetAddrPattTableInd INVADER2_PATT
        +tmsSetSourceAddressIndOffset INV2_BASE_ADDR_L, INVADER_OFFSET_6
        +tmsSendBytes 16
        +tmsSetAddrPattTableInd INVADER3_PATT
        +tmsSetSourceAddressIndOffset INV3_BASE_ADDR_L, INVADER_OFFSET_6
        +tmsSendBytes 16
        lda #6
        sta INVADER_PIXEL_OFFSET
        rts

