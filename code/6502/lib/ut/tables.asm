; 6502 - Useful tables
;
; Copyright (c) 2022 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
;

tableBitFromLeft:
!byte $80,$40,$20,$10,$08,$04,$02,$01
tableInvBitFromLeft:
!byte $7f,$bf,$df,$ef,$f7,$fb,$fd,$fe
tableBitFromRight:
!byte $01,$02,$04,$08,$10,$20,$40,$80
tableInvBitFromRight:
!byte $fe,$fd,$fb,$f7,$ef,$df,$bf,$7f