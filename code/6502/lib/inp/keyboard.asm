; 6502 KB Controller - HBC-56
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;

!ifndef KB_IO_PORT { KB_IO_PORT = $80
        !warn "KB_IO_PORT not provided. Defaulting to ", KB_IO_PORT
}

!ifndef KB_RAM_START { KB_RAM_START = $7ea1
        !warn "KB_RAM_START not provided. Defaulting to ", KB_RAM_START
}

; -------------------------
; High RAM
; -------------------------
KB_FLAGS        = KB_RAM_START
KB_TMP_X        = KB_RAM_START + 1
KB_TMP_Y        = KB_RAM_START + 2
KB_RAM_SIZE     = 3


!if KB_RAM_END < (KB_RAM_START + KB_RAM_SIZE) {
	!error "KB_RAM requires ",KB_RAM_SIZE," bytes. Allocated ",KB_RAM_END - KB_RAM_START
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

KB_SCANCODE_LEFT_SHIFT   = $12
KB_SCANCODE_RIGHT_SHIFT  = $59
KB_SCANCODE_CAPS_LOCK    = $58

; IO Ports
KB_IO_ADDR         = IO_PORT_BASE_ADDRESS | KB_IO_PORT
KB_STATUS_ADDR     = IO_PORT_BASE_ADDRESS | KB_IO_PORT | $01

; -----------------------------------------------------------------------------
; kbWaitData: Not sure how much delay we need so make a macro for now
; -----------------------------------------------------------------------------
!macro kbWaitData {
        ldy #16
        jsr hbc56CustomDelay        
}

kbWaitData:
	ldy #0
-
	dey
	bne -
        rts

; -----------------------------------------------------------------------------
; kbInit: Initialise the keyboard
; -----------------------------------------------------------------------------
kbInit:
        lda #$00
        sta KB_FLAGS

        ldx #16 ;buffer size
        
        ; ensure the keyboard buffer is clear
-
        jsr kbReadAscii
        dex
        bne -
        rts

; -----------------------------------------------------------------------------
; kbWaitForKey: Wait for a key press
; -----------------------------------------------------------------------------
kbWaitForKey:
        jsr kbReadAscii
        bcc kbWaitForKey
        rts

kbReadByte:        
        +kbWaitData
        ldx #0
        lda #$04
        bit KB_STATUS_ADDR
        beq @end

        ldy #32
-
	dey
	bne -

        ldx KB_IO_ADDR
@end
        rts

; -----------------------------------------------------------------------------
; isAlpha: Is the ASCII character a letter (A-Z or a-z)
; -----------------------------------------------------------------------------
; Inputs:
;   A: ASCII character
; Outputs:
;   Carry set if alpha, carry clear if not alpha
; -----------------------------------------------------------------------------
isAlpha:
        cmp #'A'
        bcc .notAlpha   ; less than 'A'?
        cmp #'Z' + 1
        bcc .isAlpha    ; less than or equal 'Z'?
        cmp #'a'
        bcc .notAlpha   ; less than 'a'?
        cmp #'z' + 1
        bcs .notAlpha   ; less than or equal 'z'?

.isAlpha
        sec
        rts

.notAlpha:
        clc
        rts

; -----------------------------------------------------------------------------
; kbReadAscii: Read keyboard buffer
; -----------------------------------------------------------------------------
; Outputs:
;   A: Value of the buffer
;   C: Set if a key is read
; -----------------------------------------------------------------------------
kbReadAscii:
        stx KB_TMP_X
        sty KB_TMP_Y
        jsr kbReadByte
        beq .noCharacterRead
        cpx #KB_RELEASE
        bne .keyPressed

        jsr kbReadByte  ; read the released key

        cpx #KB_SCANCODE_LEFT_SHIFT
        beq .shiftReleased
        cpx #KB_SCANCODE_RIGHT_SHIFT
        beq .shiftReleased
        jmp +

.shiftReleased:
        lda #$ff
        eor #KB_SHIFT_DOWN
        and KB_FLAGS
        sta KB_FLAGS
+
        jmp .noCharacterRead

.keyPressed:
        cpx #KB_SCANCODE_LEFT_SHIFT
        beq .shiftPressed
        cpx #KB_SCANCODE_RIGHT_SHIFT
        beq .shiftPressed
        cpx #KB_SCANCODE_CAPS_LOCK
        beq .capsLockPressed
        jmp +

.shiftPressed:
        lda #KB_SHIFT_DOWN
        ora KB_FLAGS
        sta KB_FLAGS
        jmp .noCharacterRead
.capsLockPressed:
        lda #KB_CAPS_LOCK
        eor KB_FLAGS
        sta KB_FLAGS
        jmp .noCharacterRead

+
        lda #KB_SHIFT_DOWN
        bit KB_FLAGS
        beq ++
        lda KEY_MAP_SHIFTED, x
        jmp .haveKey
++
        lda KEY_MAP, x
.haveKey
        cmp #$ff
        beq .noCharacterRead
        tax
        lda #KB_CAPS_LOCK
        bit KB_FLAGS
        beq .dontSwitchCase
        txa
        jsr isAlpha
        bcc .dontSwitchCase
        eor #$20
        sec
        ldx KB_TMP_X
        ldy KB_TMP_Y
        rts

.dontSwitchCase
        sec
        txa
        ldx KB_TMP_X
        ldy KB_TMP_Y
        rts

.noCharacterRead
        ldx KB_TMP_X
        ldy KB_TMP_Y
        clc
        rts


KEY_MAP:
;      0   1   2   3   4   5   6   7   8   9   a   b   c   d   e   f
!byte $ff,$88,$ff,$03,$82,$80,$81,$8b,$ff,$89,$87,$85,$03,$09,$60,$ff; 0
!byte $ff,$ff,$ff,$ff,$ff,$71,$31,$ff,$ff,$ff,$7a,$73,$61,$77,$32,$ff; 1
!byte $ff,$63,$78,$64,$65,$34,$33,$ff,$ff,$20,$76,$66,$74,$72,$35,$ff; 2
!byte $ff,$6e,$62,$68,$67,$79,$36,$ff,$ff,$ff,$6d,$6a,$75,$37,$38,$ff; 3
!byte $ff,$2c,$6b,$69,$6f,$30,$39,$ff,$ff,$2e,$2f,$6c,$3b,$70,$2d,$ff; 4
!byte $ff,$ff,$27,$ff,$5b,$3d,$ff,$ff,$ff,$ff,$0d,$5d,$ff,$5c,$ff,$ff; 5
!byte $ff,$ff,$ff,$ff,$ff,$ff,$08,$ff,$ff,$31,$ff,$34,$37,$ff,$ff,$ff; 6
!byte $30,$ff,$32,$35,$36,$38,$1b,$ff,$8a,$ff,$33,$2d,$ff,$39,$ff,$ff; 7

KEY_MAP_SHIFTED:
;      0   1   2   3   4   5   6   7   8   9   a   b   c   d   e   f
!byte $ff,$88,$ff,$03,$82,$80,$81,$8b,$ff,$89,$87,$85,$03,$09,$7e,$ff; 0
!byte $ff,$ff,$ff,$ff,$ff,$51,$21,$ff,$ff,$ff,$5a,$53,$41,$57,$40,$ff; 1
!byte $ff,$43,$58,$44,$45,$24,$23,$ff,$ff,$20,$56,$46,$54,$52,$25,$ff; 2
!byte $ff,$4e,$42,$48,$47,$59,$5e,$ff,$ff,$ff,$4d,$4a,$55,$26,$2a,$ff; 3
!byte $ff,$3c,$4b,$49,$4f,$29,$28,$ff,$ff,$3e,$3f,$4c,$3a,$50,$5f,$ff; 4
!byte $ff,$ff,$22,$ff,$7b,$2b,$ff,$ff,$ff,$ff,$0d,$7d,$ff,$7c,$ff,$ff; 5
!byte $ff,$ff,$ff,$ff,$ff,$ff,$08,$ff,$ff,$31,$ff,$34,$37,$ff,$ff,$ff; 6
!byte $30,$ff,$32,$35,$36,$38,$1b,$ff,$8a,$ff,$33,$2d,$ff,$39,$ff,$ff; 7
