; Troy's HBC-56 - BASIC
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;


!src "basic_hbc56_core.asm"             ; core basic

;!src "ser/uart.asm"

!src "drivers/input_uart.asm"           ; input routines
!src "drivers/output_uart.asm"          ; output routines


; -----------------------------------------------------------------------------
; metadata for the HBC-56 kernel
; -----------------------------------------------------------------------------
hbc56Meta:
        +setHbcMetaTitle "HBC-56 BASIC"
        +setHbcMetaNoWait
        rts