; 6502 - ASCII subroutines
;
; Copyright (c) 2022 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
;

; -----------------------------------------------------------------------------
; isLower: Is the ASCII character a lower-case letter (a-z)
; -----------------------------------------------------------------------------
; Inputs:
;   A: ASCII character
; Outputs:
;   Carry set if lower case, carry clear if not lower case
; -----------------------------------------------------------------------------
isLower:
        cmp #'a'
        bcc @notLower   ; less than 'a'?
        cmp #'z' + 1
        bcc @isLower    ; less than or equal 'z'?
        clc
@notLower:
        rts

@isLower
        sec
        rts


; -----------------------------------------------------------------------------
; isUpper: Is the ASCII character a upper-case letter (A-Z)
; -----------------------------------------------------------------------------
; Inputs:
;   A: ASCII character
; Outputs:
;   Carry set if upper case, carry clear if not upper case
; -----------------------------------------------------------------------------
isUpper:
        cmp #'A'
        bcc @notUpper   ; less than 'A'?
        cmp #'Z' + 1
        bcc @isUpper    ; less than or equal 'Z'?
        clc
@notUpper:
        rts

@isUpper
        sec
        rts

; -----------------------------------------------------------------------------
; isAlpha: Is the ASCII character alphanumeric (A-Z, a-z)
; -----------------------------------------------------------------------------
; Inputs:
;   A: ASCII character
; Outputs:
;   Carry set if alpha, carry clear if not alpha
; -----------------------------------------------------------------------------
isAlpha:
        jsr isLower
        bcc isUpper
        rts


; -----------------------------------------------------------------------------
; isDigit: Is the ASCII character a decimal digit (0-9)
; -----------------------------------------------------------------------------
; Inputs:
;   A: ASCII character
; Outputs:
;   Carry set if digit, carry clear if not digit
; -----------------------------------------------------------------------------
isDigit:
        cmp #'0'
        bcc @notDigit    ; less than '0'?
        cmp #'9' + 1
        bcc @isDigit     ; less than or equal '9'?
        clc

@notDigit:
        rts

@isDigit
        sec
        rts


; -----------------------------------------------------------------------------
; isAlNum: Is the ASCII character alphanumeric (A-Z, a-z, 0-9)
; -----------------------------------------------------------------------------
; Inputs:
;   A: ASCII character
; Outputs:
;   Carry set if alphanumeric, carry clear if not alphanumeric
; -----------------------------------------------------------------------------
isAlNum:
        jsr isAlpha
        bcc isDigit
        rts

; -----------------------------------------------------------------------------
; isDigitX: Is the ASCII character a hex digit (A-F, a-f, 0-9)
; -----------------------------------------------------------------------------
; Inputs:
;   A: ASCII character
; Outputs:
;   Carry set if hexadecimal, carry clear if not hexadecimal
; -----------------------------------------------------------------------------
isDigitX:
        jsr isDigit
        bcs @endIsDigitX
        cmp #'A'
        bcc @notHexDigit   ; less than 'A'?
        cmp #'F' + 1
        bcc @isHexDigit    ; less than or equal 'F'?
        cmp #'a'
        bcc @notHexDigit   ; less than 'a'?
        cmp #'f' + 1
        bcc @isHexDigit    ; less than or equal 'f'?
        clc
@notHexDigit:
        rts

@isHexDigit
        sec

@endIsDigitX
        rts


; -----------------------------------------------------------------------------
; isSpace: Is the ASCII character a whitespace character?
; -----------------------------------------------------------------------------
; Inputs:
;   A: ASCII character
; Outputs:
;   Carry set if space, carry clear if not space
; -----------------------------------------------------------------------------
isSpace:
        cmp #' '
        beq @isSpace
        bcs @notSpace
        cmp #'\n'
        beq @isSpace
        cmp #'\r'
        beq @isSpace
        cmp #'\t'
        beq @isSpace
        cmp #'\r'
        beq @isSpace
        cmp #$0b
        beq @isSpace
        cmp #$0c
        beq @isSpace

@notSpace:
        clc
        rts

@isSpace
        sec
        rts

; -----------------------------------------------------------------------------
; toUpper: convert an ascii character to upper case
; -----------------------------------------------------------------------------
; Inputs:
;   A: ascii character
; Outputs:
;   A: upper case ascii character
;   C: set if character was converted
; -----------------------------------------------------------------------------
toUpper:
        jsr isLower
        bcc @endToUpper
        eor #$20        ; convert (subtract $20)

@endToUpper
        rts        

; -----------------------------------------------------------------------------
; toLower: convert an ascii character to lower case
; -----------------------------------------------------------------------------
; Inputs:
;   A: ascii character
; Outputs:
;   A: lower case ascii character
;   C: set if character was converted
; -----------------------------------------------------------------------------
toLower:
        jsr isUpper
        bcc @endToUpper

        ora #$20        ; convert (add $20)

@endToUpper
        rts        