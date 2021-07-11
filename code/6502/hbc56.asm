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

jmp main