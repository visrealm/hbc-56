; Troy's HBC-56 - 6502 - Invaders - Bunker
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
;

COLOR_BUNKER = TMS_DK_BLUE << 4 | TMS_BLACK

bunkerLayout:
!byte 176
!fill 22, 177
!byte 178
!fill 8, 0
!byte 179
!fill 22, 0
!byte 180
!fill 8, 0
!byte 181
!fill 22, 182
!byte 183
BUNKER_BYTES = * - bunkerLayout


; -----------------------------------------------------------------------------
; Setup the bunker
; -----------------------------------------------------------------------------
setupBunker:
        +tmsSetAddrPattTable 176
        +tmsSendData BBORDR, 8 * 8
        
        +tmsSetPosWrite 4, 21
        +tmsSendData bunkerLayout, BUNKER_BYTES
        rts