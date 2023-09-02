; 6502 - HBC-56 Kernel Jump table
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
;

; The purpose of this jump table is to keep the kernel API stable. 

hbc56ClearScreen       jmp tmsInitTextTable
hbc56SetVramAddrRead   jmp tmsSetAddressRead
hbc56SetVramAddrWrite  jmp tmsSetAddressWrite