; Troy's HBC-56 - Monitor
;
; Copyright (c) 2022 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
;

; -----------------------------------------------------------------------------
; output the help message
; -----------------------------------------------------------------------------
helpCommand:
        +outputStringAddr helpMessage
        +outputStringAddr helpMessage2
        jmp commandLoop


helpMessage:
!text "HBC-56 - Monitor Help\n\n"
!text " c         - clear screen\n"
!text " d [#]     - output # bytes from current address\n"
!text " e         - execute code from current address\n",0
helpMessage2:
!text " h         - help\n"
!text " q         - quit\n"
!text " w <xx>[+] - write value(s) and increment address if +\n"
!text " s <xx>    - send value(s) to current address\n"
!text " $ <xxxx>  - set current address\n", 0
