; 6502 KB Controller - HBC-56
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github@com/visrealm/hbc-56
;

!ifndef HAVE_MATH_INC { !src "ut/math.inc" }

HAVE_KEYBOARD = 1

; -------------------------
; Constants
; -------------------------
!ifndef KB_IO_PORT { KB_IO_PORT = $80
        !warn "KB_IO_PORT not provided@ Defaulting to ", KB_IO_PORT
}

!ifndef KB_RAM_START { KB_RAM_START = $7ea1
        !warn "KB_RAM_START not provided@ Defaulting to ", KB_RAM_START
}

; -------------------------
; High RAM
; -------------------------
KB_FLAGS          = KB_RAM_START
KB_TMP_X          = KB_RAM_START + 1
KB_TMP_Y          = KB_RAM_START + 2
KB_CB_PRESSED     = KB_RAM_START + 3
KB_CB_RELEASED    = KB_RAM_START + 5
KB_CURRENT_STATE  = KB_RAM_START + 7
KB_BUFFER_HEAD    = KB_RAM_START + 8         ; head of circular buffer
KB_BUFFER_TAIL    = KB_RAM_START + 9         ; tail of circular buffer
KB_BUFFER         = KB_RAM_START + 10
KB_BUFFER_SIZE    = (1 << 4)
KB_BUFFER_MASK    = KB_BUFFER_SIZE - 1
KB_PRESSED_MAP    = KB_BUFFER + KB_BUFFER_SIZE

KB_PRESSED_MAP_SIZE = $fd + 1
KB_PRESSED_MAP_BYTES = 32

KB_RAM_SIZE     = (KB_PRESSED_MAP + KB_PRESSED_MAP_BYTES) - KB_RAM_START


!if KB_RAM_END < (KB_RAM_START + KB_RAM_SIZE) {
	!error "KB_RAM requires ",KB_RAM_SIZE," bytes@ Allocated ",KB_RAM_END - KB_RAM_START
}

; -------------------------
; Contants
; -------------------------
KB_SHIFT_DOWN   = %00000001
KB_CTRL_DOWN    = %00000010
KB_ALT_DOWN     = %00000100
KB_CAPS_LOCK    = %00001000
KB_NUM_LOCK     = %00010000

KB_RELEASE      = $f0
KB_EXT_KEY      = $e0
KB_PAUSE_KEY    = $e1

KB_SCANCODE_0 = $45
KB_SCANCODE_1 = $16
KB_SCANCODE_2 = $1E
KB_SCANCODE_3 = $26
KB_SCANCODE_4 = $25
KB_SCANCODE_5 = $2E
KB_SCANCODE_6 = $36
KB_SCANCODE_7 = $3D
KB_SCANCODE_8 = $3E
KB_SCANCODE_9 = $46
KB_SCANCODE_A = $1C
KB_SCANCODE_B = $32
KB_SCANCODE_C = $21
KB_SCANCODE_D = $23
KB_SCANCODE_E = $24
KB_SCANCODE_F = $2B
KB_SCANCODE_G = $34
KB_SCANCODE_H = $33
KB_SCANCODE_I = $43
KB_SCANCODE_J = $3B
KB_SCANCODE_K = $42
KB_SCANCODE_L = $4B
KB_SCANCODE_M = $3A
KB_SCANCODE_N = $31
KB_SCANCODE_O = $44
KB_SCANCODE_P = $4D
KB_SCANCODE_Q = $15
KB_SCANCODE_R = $2D
KB_SCANCODE_S = $1B
KB_SCANCODE_T = $2C
KB_SCANCODE_U = $3C
KB_SCANCODE_V = $2A
KB_SCANCODE_W = $1D
KB_SCANCODE_X = $22
KB_SCANCODE_Y = $35
KB_SCANCODE_Z = $1A
KB_SCANCODE_F1 = $05
KB_SCANCODE_F2 = $06
KB_SCANCODE_F3 = $04
KB_SCANCODE_F4 = $0C
KB_SCANCODE_F5 = $03
KB_SCANCODE_F6 = $0B
KB_SCANCODE_F7 = $83
KB_SCANCODE_F8 = $0A
KB_SCANCODE_F9 = $01
KB_SCANCODE_F10 = $09
KB_SCANCODE_F11 = $78
KB_SCANCODE_F12 = $07
KB_SCANCODE_NUMPAD_0 = $70
KB_SCANCODE_NUMPAD_1 = $69
KB_SCANCODE_NUMPAD_2 = $72
KB_SCANCODE_NUMPAD_3 = $7A
KB_SCANCODE_NUMPAD_4 = $6B
KB_SCANCODE_NUMPAD_5 = $73
KB_SCANCODE_NUMPAD_6 = $74
KB_SCANCODE_NUMPAD_7 = $6C
KB_SCANCODE_NUMPAD_8 = $75
KB_SCANCODE_NUMPAD_9 = $7D
KB_SCANCODE_NUMPAD_DIVIDE = $CA
KB_SCANCODE_NUMPAD_ENTER = $DA
KB_SCANCODE_NUMPAD_MINUS = $7B
KB_SCANCODE_NUMPAD_MULTIPLY = $7C
KB_SCANCODE_NUMPAD_PERIOD = $71
KB_SCANCODE_NUMPAD_PLUS = $79
KB_SCANCODE_NUM_LOCK = $77
KB_SCANCODE_ALT_LEFT = $11
KB_SCANCODE_ALT_RIGHT_ = $91
KB_SCANCODE_APOS = $52
KB_SCANCODE_ARROW_DOWN = $F2
KB_SCANCODE_ARROW_LEFT = $EB
KB_SCANCODE_ARROW_RIGHT = $F4
KB_SCANCODE_ARROW_UP = $F5
KB_SCANCODE_BACKSPACE = $66
KB_SCANCODE_CAPS_LOCK = $58
KB_SCANCODE_COMMA = $41
KB_SCANCODE_CTRL_LEFT = $14
KB_SCANCODE_CTRL_RIGHT = $94
KB_SCANCODE_DELETE = $F1
KB_SCANCODE_END = $E9
KB_SCANCODE_ENTER = $5A
KB_SCANCODE_EQUAL = $55
KB_SCANCODE_ESC = $76
KB_SCANCODE_HOME = $EC
KB_SCANCODE_INSERT = $F0
KB_SCANCODE_MENU = $AF
KB_SCANCODE_MINUS = $4E
KB_SCANCODE_PAGE_DOWN = $FA
KB_SCANCODE_PAGE_UP = $FD
KB_SCANCODE_PAUSE = $E1
KB_SCANCODE_PERIOD = $49
KB_SCANCODE_PRTSCR = $92
KB_SCANCODE_SCROLL_LOCK = $7E
KB_SCANCODE_SEMICOLON = $4C
KB_SCANCODE_SHIFT_LEFT = $12
KB_SCANCODE_SHIFT_RIGHT = $59
KB_SCANCODE_SLASH_BACK = $5D
KB_SCANCODE_SLASH_FORWARD = $4A
KB_SCANCODE_SPACEBAR = $29
KB_SCANCODE_SQUARE_LEFT = $54
KB_SCANCODE_SQUARE_RIGHT = $5B
KB_SCANCODE_TAB = $0D
KB_SCANCODE_TILDE = $0E
KB_SCANCODE_WINDOWS_LEFT = $9F
KB_SCANCODE_WINDOWS_RIGHT = $A7


KB_SHIFT_LEFT_MAP_BYTE = KB_SCANCODE_SHIFT_LEFT >> 3
KB_SHIFT_LEFT_MAP_BIT  = $80 >> (KB_SCANCODE_SHIFT_LEFT & $07)

KB_SHIFT_RIGHT_MAP_BYTE = KB_SCANCODE_SHIFT_RIGHT >> 3
KB_SHIFT_RIGHT_MAP_BIT  = $80 >> (KB_SCANCODE_SHIFT_RIGHT & $07)


; IO Ports
KB_IO_ADDR         = IO_PORT_BASE_ADDRESS | KB_IO_PORT
KB_STATUS_ADDR     = IO_PORT_BASE_ADDRESS | KB_IO_PORT | $01

; -----------------------------------------------------------------------------
; kbInit: Initialise the keyboard
; -----------------------------------------------------------------------------
kbInit:
        lda #$00
        sta KB_FLAGS

        ldx #16 ;buffer size
        
        ; ensure the hardware keyboard buffer is clear
-
        stx KB_TMP_X
        jsr .kbReadByte
        ldx KB_TMP_X
        dex
        bne -

        +memset KB_PRESSED_MAP, 0, KB_PRESSED_MAP_BYTES

        stz KB_BUFFER_HEAD
        stz KB_BUFFER_TAIL

        lda #.KB_STATE_DEFAULT
        sta KB_CURRENT_STATE

        ; flow through

kbResetCallbacks:
        lda #<.kbDummyCb
        sta KB_CB_PRESSED
        sta KB_CB_RELEASED
        
        lda #>.kbDummyCb
        sta KB_CB_PRESSED + 1
        sta KB_CB_RELEASED + 1

        ; flow through

.kbDummyCb:
        rts

; -----------------------------------------------------------------------------
; kbIntHandler: Standard keyboard interrupt handler
; -----------------------------------------------------------------------------
kbIntHandler:
        jsr .kbReadByte
        cpx #0
        beq .kbDummyCb

        txa     ; acc now holds scancode

        ldx KB_CURRENT_STATE

        jmp (.kbStateHandlers, x)

.KB_STATE_DEFAULT          = 0
.KB_STATE_RELEASE          = 2
.KB_STATE_EXTENDED         = 4
.KB_STATE_EXTENDED_RELEASE = 6
.KB_STATE_PAUSE_SEQ        = 8

.kbStateHandlers:
!word .stdKeyHandler, .relKeyHandler, .extKeyHandler, .extRelKeyHandler, .pauseKeyHandler

; default scancode handler
.stdKeyHandler
        cmp #KB_RELEASE
        bne +
        lda #.KB_STATE_RELEASE
        sta KB_CURRENT_STATE
        rts
+
        cmp #KB_EXT_KEY
        bne +
        lda #.KB_STATE_EXTENDED
        sta KB_CURRENT_STATE
        rts
+
        cmp #KB_PAUSE_KEY
        bne +
        lda #.KB_STATE_PAUSE_SEQ
        sta KB_CURRENT_STATE
        rts
+
        ; a regular key was pressed 
        ; TODO: bit field rather than a byte per key?
        jsr .kbSetKey

        jmp (KB_CB_PRESSED)
        ; subroutine returns above

; extended release scancode handler
.extRelKeyHandler:
        ora #$80
        ; flow through

;  release scancode handler
.relKeyHandler:
        tax
        jsr .kbClearKey

        lda #.KB_STATE_DEFAULT
        sta KB_CURRENT_STATE
        txa

        jmp (KB_CB_RELEASED)

; extended scancode handler
.extKeyHandler:
        cmp #KB_RELEASE
        bne +
        lda #.KB_STATE_EXTENDED_RELEASE
        sta KB_CURRENT_STATE
        rts
+
        ora #$80
        
        jsr .kbSetKey

        lda #.KB_STATE_DEFAULT
        sta KB_CURRENT_STATE
        txa

        jmp (KB_CB_PRESSED)

; pause/break sequence scancode handler
.pauseKeyHandler:
        cmp #$77
        bne @notLastByte
        tax
        lda KB_PRESSED_MAP + KB_SCANCODE_PAUSE
        bne +
        stx KB_PRESSED_MAP + KB_SCANCODE_PAUSE
        jmp (KB_CB_PRESSED)
+
        stz KB_PRESSED_MAP + KB_SCANCODE_PAUSE

        lda #.KB_STATE_DEFAULT
        sta KB_CURRENT_STATE
        txa

        jmp (KB_CB_RELEASED)

@notLastByte
        rts

; -----------------------------------------------------------------------------
; Outputs:
;   A: Value of the KB Status (0 if no key)
;   X: PS/2 Scancode byte
; -----------------------------------------------------------------------------
.kbReadByte:        
        ldx #0
        lda #$04
        bit KB_STATUS_ADDR
        beq @end

        ldy #32         ; TODO: this could probably be smaller
-
	dey
	bne -

        ldx KB_IO_ADDR
@end
        rts


; -----------------------------------------------------------------------------
; .kbSetKey: Set a key is pressed in KB_PRESSED_MAP
; Inputs:
;    A - scancode
; -----------------------------------------------------------------------------
.kbSetKey:
        ldx KB_BUFFER_HEAD      ; store at head of buffer
        sta KB_BUFFER, x

        sta KB_TMP_X            ; find byte in map
        +lsr3
        tax
        lda KB_TMP_X
        and #$07
        tay
        lda KB_PRESSED_MAP, x
        ora tableBitFromLeft, y ; set bit in map byte
        sta KB_PRESSED_MAP, x   ; update map

        ; check for toggle keys
        ldx KB_TMP_X
        cpx #KB_SCANCODE_CAPS_LOCK
        bne +
        lda #KB_CAPS_LOCK
        eor KB_FLAGS
        sta KB_FLAGS
+

        lda KB_BUFFER_HEAD      ; increment (and mask) buffer head
        inc
        and #KB_BUFFER_MASK
        sta KB_BUFFER_HEAD
        rts

; -----------------------------------------------------------------------------
; .kbClearKey: Clear a key is pressed in KB_PRESSED_MAP
; Inputs:
;    A - scancode
; -----------------------------------------------------------------------------
.kbClearKey:
        sta KB_TMP_X
        +lsr3
        tax
        lda KB_TMP_X
        and #$07
        tay
        lda KB_PRESSED_MAP, x
        and tableInvBitFromLeft, y
        sta KB_PRESSED_MAP, x
        rts


; -----------------------------------------------------------------------------
; .kbPopTail: Pop a scancode from the tail of the buffer
; Inputs:
;    A - scancode
; -----------------------------------------------------------------------------
.kbPopTail:
        lda KB_BUFFER_TAIL
        tax
        inc
        and #KB_BUFFER_MASK
        sta KB_BUFFER_TAIL
        lda KB_BUFFER, x
        rts

; -----------------------------------------------------------------------------
; kbIsPressed: Is a key pressed right now?
; Inputs:
;    X - scancode
; Returns:
;    Z - clear if pressed, set if not pressed
; -----------------------------------------------------------------------------
kbIsPressed:
        php
        sei
        stx KB_TMP_X
        txa
        +lsr3
        tax
        lda KB_TMP_X
        and #$07
        tay
        lda tableBitFromLeft, y
        and KB_PRESSED_MAP, x
        ldx KB_TMP_X
        plp
        cmp #0
        rts


; -----------------------------------------------------------------------------
; kbWaitForScancode: Wait for a key press
; Returns:
;    A - scancode
; -----------------------------------------------------------------------------
kbWaitForScancode:
        php
        sei        
        sec
        lda KB_BUFFER_HEAD
        sbc KB_BUFFER_TAIL
        plp
        cmp #0
        beq kbWaitForScancode
        php
        sei
        jsr .kbPopTail
        plp
        rts

; -----------------------------------------------------------------------------
; kbNextScancode: Return the next scancode in the buffer or zero if empty
; Returns:
;    A - scancode (or zero)
; -----------------------------------------------------------------------------
kbNextScancode:
        php
        sei
        lda KB_BUFFER_HEAD
        cmp KB_BUFFER_TAIL
        beq @noScancode
        jsr .kbPopTail
        plp
        cmp #0
        rts

@noScancode
        plp
        lda #0
        rts

; -----------------------------------------------------------------------------
; kbScancodeToAscii: Convert a scancode to ascii. shift/caps lock is honoured
; Inputs:
;    A - scancode (or zero)
; Returns:
;    A - ascii character
;    C - set if valid character in A
; -----------------------------------------------------------------------------
kbScancodeToAscii:
        phx
        sta KB_TMP_X
        clc
        bpl +
        plx
        rts
+
        php
        sei
        ldx #KB_SHIFT_LEFT_MAP_BYTE
        lda #KB_SHIFT_LEFT_MAP_BIT
        bit KB_PRESSED_MAP, x
        beq +
        sec
        bra @doneShiftCheck
+

        ldx #KB_SHIFT_RIGHT_MAP_BYTE
        lda #KB_SHIFT_RIGHT_MAP_BIT
        bit KB_PRESSED_MAP, x
        beq +
        sec
+

@doneShiftCheck:
        bcs @shiftedKeys:
        ldx KB_TMP_X
        lda KEY_MAP, x
        bra @end

@shiftedKeys:
        ldx KB_TMP_X
        lda KEY_MAP_SHIFTED, x

@end
        jsr isAlpha
        bcc @afterAlphaCheck
        sta KB_TMP_X
        lda #KB_CAPS_LOCK
        and KB_FLAGS
        beq +
        lda KB_TMP_X
        eor #$20
        bra @afterAlphaCheck
+
        lda KB_TMP_X
@afterAlphaCheck
        plp
        plx
        cmp #$ff
        sec
        bne +
        clc
+        
        rts

; -----------------------------------------------------------------------------
; kbReadAscii: Read an ASCII caharacter from the keyboard queue
; Returns:
;    A - ascii character
;    C - set if valid character in A
; -----------------------------------------------------------------------------
kbReadAscii:
        php
        sei
        phx
        jsr kbNextScancode
        beq @noKey
        plx
        plp
        jmp kbScancodeToAscii
@noKey
        plx
        plp
        clc
        rts


KEY_MAP:
;      0   1   2   3   4   5   6   7   8   9   a   b   c   d   e   f
!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$09,$60,$ff; 0
!byte $ff,$ff,$ff,$ff,$ff,$71,$31,$ff,$ff,$ff,$7a,$73,$61,$77,$32,$ff; 1
!byte $ff,$63,$78,$64,$65,$34,$33,$ff,$ff,$20,$76,$66,$74,$72,$35,$ff; 2
!byte $ff,$6e,$62,$68,$67,$79,$36,$ff,$ff,$ff,$6d,$6a,$75,$37,$38,$ff; 3
!byte $ff,$2c,$6b,$69,$6f,$30,$39,$ff,$ff,$2e,$2f,$6c,$3b,$70,$2d,$ff; 4
!byte $ff,$ff,$27,$ff,$5b,$3d,$ff,$ff,$ff,$ff,$0d,$5d,$ff,$5c,$ff,$ff; 5
!byte $ff,$ff,$ff,$ff,$ff,$ff,$08,$ff,$ff,$31,$ff,$34,$37,$ff,$ff,$ff; 6
!byte $30,$ff,$32,$35,$36,$38,$1b,$ff,$ff,$ff,$33,$2d,$ff,$39,$ff,$ff; 7

KEY_MAP_SHIFTED:
;      0   1   2   3   4   5   6   7   8   9   a   b   c   d   e   f
!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$09,$7e,$ff; 0
!byte $ff,$ff,$ff,$ff,$ff,$51,$21,$ff,$ff,$ff,$5a,$53,$41,$57,$40,$ff; 1
!byte $ff,$43,$58,$44,$45,$24,$23,$ff,$ff,$20,$56,$46,$54,$52,$25,$ff; 2
!byte $ff,$4e,$42,$48,$47,$59,$5e,$ff,$ff,$ff,$4d,$4a,$55,$26,$2a,$ff; 3
!byte $ff,$3c,$4b,$49,$4f,$29,$28,$ff,$ff,$3e,$3f,$4c,$3a,$50,$5f,$ff; 4
!byte $ff,$ff,$22,$ff,$7b,$2b,$ff,$ff,$ff,$ff,$0d,$7d,$ff,$7c,$ff,$ff; 5
!byte $ff,$ff,$ff,$ff,$ff,$ff,$08,$ff,$ff,$31,$ff,$34,$37,$ff,$ff,$ff; 6
!byte $30,$ff,$32,$35,$36,$38,$1b,$ff,$ff,$ff,$33,$2d,$ff,$39,$ff,$ff; 7
