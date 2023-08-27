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
BLOCKS_LEFT_PATTERN_INDEX = 254
BLOCKS_RIGHT_PATTERN_INDEX = BLOCKS_LEFT_PATTERN_INDEX + 1

blocksInit:
        lda #TMS_LT_BLUE
        sta COLOR_TOP1
        lda #TMS_CYAN
        sta COLOR_TOP2
        lda #TMS_LT_GREEN
        sta COLOR_TOP3
        lda #TMS_LT_YELLOW
        sta COLOR_LEFT
        lda #TMS_DK_YELLOW
        sta COLOR_RIGHT

        +tmsSetAddrPattTableIIBank0 BLOCKS_PATTERN_INDEX_R1
        jsr .buildTopBlocks
        +tmsSetAddrPattTableIIBank0 BLOCKS_PATTERN_INDEX_R2
        jsr .buildBottomBlocks

        +tmsSetAddrColorTableIIBank0 BLOCKS_PATTERN_INDEX_R1
        jsr .buildTopBlocksColor
        +tmsSetAddrColorTableIIBank0 BLOCKS_PATTERN_INDEX_R2
        jsr .buildBottomBlocksColor

        +tmsSetAddrPattTableIIBank0 BLOCKS_LEFT_PATTERN_INDEX
        +tmsSendData .clearPatt, 8 * 2
        +tmsSetAddrColorTableIIBank0 BLOCKS_LEFT_PATTERN_INDEX
        lda COLOR_LEFT
        +asl4
        ora COLOR_RIGHT
        +tmsPutAccRpt 8 * 2

        +tmsSetAddrPattTableIIBank1 BLOCKS_PATTERN_INDEX_R1
        jsr .buildTopBlocks
        +tmsSetAddrPattTableIIBank1 BLOCKS_PATTERN_INDEX_R2
        jsr .buildBottomBlocks

        +tmsSetAddrColorTableIIBank1 BLOCKS_PATTERN_INDEX_R1
        jsr .buildTopBlocksColor
        +tmsSetAddrColorTableIIBank1 BLOCKS_PATTERN_INDEX_R2
        jsr .buildBottomBlocksColor

        +tmsSetAddrPattTableIIBank1 BLOCKS_LEFT_PATTERN_INDEX
        +tmsSendData .clearPatt, 8 * 2
        +tmsSetAddrColorTableIIBank1 BLOCKS_LEFT_PATTERN_INDEX
        
        lda COLOR_LEFT
        +asl4
        ora COLOR_RIGHT
        +tmsPutAccRpt 8 * 2

        +tmsSetAddrPattTableIIBank2 BLOCKS_PATTERN_INDEX_R1
        jsr .buildTopBlocks
        +tmsSetAddrPattTableIIBank2 BLOCKS_PATTERN_INDEX_R2
        jsr .buildBottomBlocks

        +tmsSetAddrColorTableIIBank2 BLOCKS_PATTERN_INDEX_R1
        jsr .buildTopBlocksColor
        +tmsSetAddrColorTableIIBank2 BLOCKS_PATTERN_INDEX_R2
        jsr .buildBottomBlocksColor

        +tmsSetAddrPattTableIIBank2 BLOCKS_LEFT_PATTERN_INDEX
        +tmsSendData .clearPatt, 8 * 2
        +tmsSetAddrColorTableIIBank2 BLOCKS_LEFT_PATTERN_INDEX

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

.clearPatt:
!byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
!byte $00,$00,$00,$00,$00,$00,$00,$00

