; Troy's HBC-56 - BASIC
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;


!src "basic_hbc56_core.asm"             ; core basic
!src "functions/basic_functions.asm"    ; custom functions

!src "drivers/input.asm"                        ; input routines
!src "drivers/output_tms9918.asm"               ; output routines


; -----------------------------------------------------------------------------
; metadata for the HBC-56 kernel
; -----------------------------------------------------------------------------
hbc56Meta:      
        +setHbcMetaTitle "HBC-56 BASIC"
        rts