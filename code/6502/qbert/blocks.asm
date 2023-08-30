; Troy's HBC-56 - Q*Bert
;
; Copyright (c) 2023 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;

BLOCKS_PATTERN_INDEX_R1 = 128
BLOCKS_PATTERN_INDEX_R2 = BLOCKS_PATTERN_INDEX_R1 + 32
BLOCKS_LEFT_PATTERN_INDEX = 251
BLOCKS_RIGHT_PATTERN_INDEX = BLOCKS_LEFT_PATTERN_INDEX + 1

BLOCK_COUNT = 28 ; 1 + 2 + 3 + 4 + 5 + 6 + 7

BLOCKS_BLAH = BLOCKS_ADDR
BLOCKS_BLAH2 = BLOCKS_ADDR + 32


blocksInit:
        lda #TMS_LT_BLUE
        sta COLOR_TOP1
        lda #TMS_MED_GREEN
        sta COLOR_TOP2
        lda #TMS_LT_YELLOW
        sta COLOR_TOP3
        lda #TMS_WHITE
        sta COLOR_LEFT
        lda #TMS_GREY
        sta COLOR_RIGHT

        jsr .buildBlockPatterns

        jsr .buildBlockColors

        rts

blocksTick:
        rts

        lda BLOCKS_BLAH
        inc 
        and #$03
        cmp #3
        bne +
        lda #0
+
        sta BLOCKS_BLAH
        +asl3
        sta BLOCKS_BLAH + 1

        +tmsSetPosWrite 14, 2
        clc
        lda #$80
        adc BLOCKS_BLAH + 1
        +tmsPut
        inc
        +tmsPut
        inc
        +tmsPut
        inc
        +tmsPut

        +tmsSetPosWrite 14, 3

        lda #$a4
        clc
        adc BLOCKS_BLAH + 1
        +tmsPut
        inc
        +tmsPut
        inc
        +tmsPut
        inc
        +tmsPut

        +tmsSetPosWrite 12, 5


        rts

.buildBlockPatterns:
        +tmsSetAddrPattTableIIBank0 BLOCKS_PATTERN_INDEX_R1
        jsr .buildTopBlocks
        +tmsSetAddrPattTableIIBank0 BLOCKS_PATTERN_INDEX_R2
        jsr .buildBottomBlocks
        +tmsSetAddrPattTableIIBank0 BLOCKS_LEFT_PATTERN_INDEX
        jsr .buildFullBlocks

       +tmsSetAddrPattTableIIBank1 BLOCKS_PATTERN_INDEX_R1
       jsr .buildTopBlocks
       +tmsSetAddrPattTableIIBank1 BLOCKS_PATTERN_INDEX_R2
       jsr .buildBottomBlocks
       +tmsSetAddrPattTableIIBank1 BLOCKS_LEFT_PATTERN_INDEX
       jsr .buildFullBlocks

       +tmsSetAddrPattTableIIBank2 BLOCKS_PATTERN_INDEX_R1
       jsr .buildTopBlocks
       +tmsSetAddrPattTableIIBank2 BLOCKS_PATTERN_INDEX_R2
       jsr .buildBottomBlocks
       +tmsSetAddrPattTableIIBank2 BLOCKS_LEFT_PATTERN_INDEX
       jsr .buildFullBlocks
        rts

.buildBlockColors:
        +tmsSetAddrColorTableIIBank0 BLOCKS_PATTERN_INDEX_R1
        jsr .buildTopBlocksColor
        +tmsSetAddrColorTableIIBank0 BLOCKS_PATTERN_INDEX_R2
        jsr .buildBottomBlocksColor
        +tmsSetAddrColorTableIIBank0 BLOCKS_LEFT_PATTERN_INDEX
        jsr .buildFullBlocksColor


       +tmsSetAddrColorTableIIBank1 BLOCKS_PATTERN_INDEX_R1
       jsr .buildTopBlocksColor
       +tmsSetAddrColorTableIIBank1 BLOCKS_PATTERN_INDEX_R2
       jsr .buildBottomBlocksColor
       +tmsSetAddrColorTableIIBank1 BLOCKS_LEFT_PATTERN_INDEX
       jsr .buildFullBlocksColor
        
       +tmsSetAddrColorTableIIBank2 BLOCKS_PATTERN_INDEX_R1
       jsr .buildTopBlocksColor
       +tmsSetAddrColorTableIIBank2 BLOCKS_PATTERN_INDEX_R2
       jsr .buildBottomBlocksColor
       +tmsSetAddrColorTableIIBank2 BLOCKS_LEFT_PATTERN_INDEX
       jsr .buildFullBlocksColor

        rts

.buildFullBlocks:
        ldx #8
        lda #0
-
        sec
        rol
        +tmsPut
        dex
        bne -

        ldx #8
        lda #0
-
        sec
        ror
        +tmsPut
        dex
        bne -

        +tmsPutRpt $ff, 16
        +tmsPutRpt $00, 8
        rts

.buildFullBlocksColor:
        lda COLOR_TOP2
        +tmsPutAccRpt 16
        +asl4
        +tmsPutAccRpt 8
        lda COLOR_LEFT
        +asl4
        ora COLOR_RIGHT
        +tmsPutAccRpt 8 * 2
        rts


.buildTopBlocks:
        +tmsSendDataRpt .blockPatt, 8 * 4, 8
        rts

.buildBottomBlocks:
        +tmsSendDataRpt .blockPatt2, 8 * 4, 8
        rts

; Using COLOR_TOP, COLOR_LEFT, COLOR_RIGHT 


.buildTopBlocksColor:
        lda COLOR_TOP1
        sta COLOR_TMP
        jsr .buildTopBlock1Color
        lda COLOR_TOP2
        sta COLOR_TMP
        jsr .buildTopBlock1Color
        lda COLOR_TOP3
        sta COLOR_TMP
        jmp .buildTopBlock1Color

.buildTopBlock1Color:
        lda COLOR_TMP
        +asl4
        +tmsPutAccRpt 8 * 4
        ora COLOR_RIGHT
        +tmsPutAccRpt 8 * 2
        and #$f0
        ora COLOR_LEFT
        +tmsPutAccRpt 8 * 2
        rts

.buildBottomBlocksColor
        lda COLOR_TOP1
        sta COLOR_TMP
        jsr .buildBottomBlocks1Color
        lda COLOR_TOP2
        sta COLOR_TMP
        jsr .buildBottomBlocks1Color
        lda COLOR_TOP3
        sta COLOR_TMP
        jmp .buildBottomBlocks1Color

.buildBottomBlocks1Color:
        lda COLOR_LEFT
        +asl4
        +tmsPutAccRpt 8 * 2
        lda COLOR_RIGHT
        +asl4
        +tmsPutAccRpt 8 * 2
        lda COLOR_TMP
        +asl4
        ora COLOR_LEFT
        +tmsPutAccRpt 8 * 2
        and #$f0
        ora COLOR_RIGHT
        +tmsPutAccRpt 8 * 2
        rts



.blockPatt:
!byte $00,$00,$00,$00,$01,$07,$1F,$7F
!byte $01,$07,$1F,$7F,$FF,$FF,$FF,$FF
!byte $80,$E0,$F8,$FE,$FF,$FF,$FF,$FF
!byte $00,$00,$00,$00,$80,$E0,$F8,$FE

.blockPatt2:
!byte $7F,$1F,$07,$01,$00,$00,$00,$00   
!byte $FF,$FF,$FF,$FF,$7F,$1F,$07,$01   
!byte $FF,$FF,$FF,$FF,$FE,$F8,$E0,$80
!byte $FE,$F8,$E0,$80,$00,$00,$00,$00
