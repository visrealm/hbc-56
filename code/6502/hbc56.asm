; 6502 - HBC-56
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
;

!cpu 6502
!initmem $FF
cputype = $6502

*=$FFFC
!word $8000
*=$8000

; Base address of the 256 IO port memory range
IO_PORT_BASE_ADDRESS	= $7f00

R0  = $02
R0L = R0
R0H = R0 + 1
R1  = $04
R1L = R1
R1H = R1 + 1
R2  = $06
R2L = R2
R2H = R2 + 1
R3  = $08
R3L = R3
R3H = R3 + 1
R4  = $0a
R4L = R4
R4H = R4 + 1
R5  = $0c
R5L = R5
R5H = R5 + 1
R6  = $0e
R6L = R6
R6H = R6 + 1
R7  = $10
R7L = R7
R7H = R7 + 1


jmp main