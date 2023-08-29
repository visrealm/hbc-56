; Troy's HBC-56 - Q*Bert
;
; Copyright (c) 2023 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;


PLATFORM_COLOR_BASE_LEFT  = TMS_WHITE
PLATFORM_COLOR_BASE_RIGHT = TMS_GREY
PLATFORM_COLOR_A     = TMS_MED_RED
PLATFORM_COLOR_B     = TMS_MED_GREEN
PLATFORM_COLOR_C     = TMS_LT_YELLOW
PLATFORM_COLOR_D     = TMS_LT_BLUE

PLATFORM_PATTERN_INDEX = 1


platformsInit:

        ; platform patterns (for each bank)
        +tmsSetAddrPattTableIIBank0 PLATFORM_PATTERN_INDEX
        jsr .platformInitSendPatterns

        +tmsSetAddrPattTableIIBank1 PLATFORM_PATTERN_INDEX
        jsr .platformInitSendPatterns

        +tmsSetAddrPattTableIIBank2 PLATFORM_PATTERN_INDEX
        jsr .platformInitSendPatterns


        ; platform colors (for each bank)
        jsr .setPlatformColorBank0
        jsr .updatePlatformColor2

        jsr .setPlatformColorBank1
        jsr .updatePlatformColor2

        jsr .setPlatformColorBank2
        jsr .updatePlatformColor2
        rts

platformsTick:
        lda HBC56_TICKS
        cmp #1
        bne +
        jsr .setPlatformColorBank0
        jsr .updatePlatformColor1
        rts
+
        cmp #2
        bne +
        jsr .setPlatformColorBank1
        jsr .updatePlatformColor1
        rts
+
        cmp #3
        bne +
        jsr .setPlatformColorBank2
        jsr .updatePlatformColor1
        rts
+
        cmp #16
        bne +
        jsr .setPlatformColorBank0
        jsr .updatePlatformColor2
        rts
+
        cmp #17
        bne +
        jsr .setPlatformColorBank1
        jsr .updatePlatformColor2
        rts
+
        cmp #18
        bne +
        jsr .setPlatformColorBank2
        jsr .updatePlatformColor2
        rts
+
        cmp #31
        bne +
        jsr .setPlatformColorBank0
        jsr .updatePlatformColor3
        rts
+
        cmp #32
        bne +
        jsr .setPlatformColorBank1
        jsr .updatePlatformColor3
        rts
+
        cmp #33
        bne +
        jsr .setPlatformColorBank2
        jsr .updatePlatformColor3
        rts
+
        cmp #46
        bne +
        jsr .setPlatformColorBank0
        jsr .updatePlatformColor4
        rts
+
        cmp #47
        bne +
        jsr .setPlatformColorBank1
        jsr .updatePlatformColor4
        rts
+
        cmp #48
        bne +
        jsr .setPlatformColorBank2
        jsr .updatePlatformColor4
+
        rts

.platformInitSendPatterns:
        +tmsSendData .platformPatt, 8 * 4
        rts

.setPlatformColorBank0
        +tmsSetAddrColorTableIIBank0 PLATFORM_PATTERN_INDEX
        rts

.setPlatformColorBank1
        +tmsSetAddrColorTableIIBank1 PLATFORM_PATTERN_INDEX
        rts

.setPlatformColorBank2
        +tmsSetAddrColorTableIIBank2 PLATFORM_PATTERN_INDEX
        rts

.updatePlatformColor1:
        +tmsSendData .platformPal1, 8 * 4
        rts

.updatePlatformColor2:
        +tmsSendData .platformPal2, 8 * 4
        rts

.updatePlatformColor3:
        +tmsSendData .platformPal3, 8 * 4
        rts

.updatePlatformColor4:
        +tmsSendData .platformPal4, 8 * 4
        rts


.platformPatt:
!byte $00,$00,$00,$00,$00,$07,$3F,$80
!byte $00,$07,$3F,$FE,$3F,$07,$C0,$F8
!byte $00,$00,$00,$00,$00,$E0,$FC,$FE
!byte $7F,$F8,$C0,$01,$03,$1F,$FC,$E0


!macro platformColorTable c1, c2, c3, c4 {
+byteTmsColorFgBg TMS_TRANSPARENT, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_TRANSPARENT, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_TRANSPARENT, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_TRANSPARENT, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_TRANSPARENT, TMS_TRANSPARENT
+byteTmsColorFgBg c1, TMS_TRANSPARENT
+byteTmsColorFgBg c1, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_TRANSPARENT, c2
+byteTmsColorFgBg TMS_TRANSPARENT, c2
+byteTmsColorFgBg c3, c2
+byteTmsColorFgBg c3, c2
+byteTmsColorFgBg c3, c4
+byteTmsColorFgBg c3, PLATFORM_COLOR_BASE_LEFT
+byteTmsColorFgBg c3, PLATFORM_COLOR_BASE_LEFT
+byteTmsColorFgBg TMS_TRANSPARENT, PLATFORM_COLOR_BASE_LEFT
+byteTmsColorFgBg TMS_TRANSPARENT, PLATFORM_COLOR_BASE_LEFT


+byteTmsColorFgBg TMS_TRANSPARENT, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_TRANSPARENT, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_TRANSPARENT, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_TRANSPARENT, TMS_TRANSPARENT
+byteTmsColorFgBg TMS_TRANSPARENT, TMS_TRANSPARENT
+byteTmsColorFgBg c1, TMS_TRANSPARENT
+byteTmsColorFgBg c1, TMS_TRANSPARENT
+byteTmsColorFgBg c1, TMS_TRANSPARENT
+byteTmsColorFgBg c1, c2
+byteTmsColorFgBg c1, c4
+byteTmsColorFgBg c1, c4
+byteTmsColorFgBg PLATFORM_COLOR_BASE_RIGHT, c4
+byteTmsColorFgBg PLATFORM_COLOR_BASE_RIGHT, c4
+byteTmsColorFgBg PLATFORM_COLOR_BASE_RIGHT, c3
+byteTmsColorFgBg PLATFORM_COLOR_BASE_RIGHT, TMS_TRANSPARENT
+byteTmsColorFgBg PLATFORM_COLOR_BASE_RIGHT, TMS_TRANSPARENT
}

.platformPal1:
+platformColorTable PLATFORM_COLOR_A, PLATFORM_COLOR_B, PLATFORM_COLOR_C, PLATFORM_COLOR_D
.platformPal2:
+platformColorTable PLATFORM_COLOR_B, PLATFORM_COLOR_C, PLATFORM_COLOR_D, PLATFORM_COLOR_A
.platformPal3:
+platformColorTable PLATFORM_COLOR_C, PLATFORM_COLOR_D, PLATFORM_COLOR_A, PLATFORM_COLOR_B
.platformPal4:
+platformColorTable PLATFORM_COLOR_D, PLATFORM_COLOR_A, PLATFORM_COLOR_B, PLATFORM_COLOR_C

