; 6502 KB Controller - HBC-56
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
; Dependencies:
;  - hbc56.asm


; -------------------------
; Constants
; -------------------------
KB_IO_PORT	= $81

; IO Ports
KB_IO_ADDR     = IO_PORT_BASE_ADDRESS | KB_IO_PORT

!macro kbBranchIfNotPressed .buttonMask, addr {
        jsr kbReadAscii
        cmp #.buttonMask
        bne addr
}

; -----------------------------------------------------------------------------
; kbWaitData: Not sure how much delay we need so make a macro for now
; -----------------------------------------------------------------------------
!macro kbWaitData {
        jsr kbWaitData
        jsr kbWaitData
        jsr kbWaitData
        jsr kbWaitData
        jsr kbWaitData
        jsr kbWaitData
        jsr kbWaitData
        jsr kbWaitData
        jsr kbWaitData
        jsr kbWaitData
}

kbWaitData:
	ldy #0
-
	dey
	bne -
        rts


; -----------------------------------------------------------------------------
; kbRead: Read keyboard buffer
; -----------------------------------------------------------------------------
; Outputs:
;   A: Value of the buffer
kbReadAscii:
        ldx KB_IO_ADDR
        cpx #$f0
        bne +
        +kbWaitData
        ldx KB_IO_ADDR   ; read the released key
        +kbWaitData
        jmp kbReadAscii
        rts
+
        lda KEY_MAP, x
        +kbWaitData
        rts


KEY_MAP:
;      0   1   2   3   4   5   6   7   8   9   a   b   c   d   e   f
!byte $ff,$88,$ff,$84,$82,$80,$81,$8b,$ff,$89,$87,$85,$83,$09,$40,$ff; 0
!byte $ff,$ff,$ff,$ff,$ff,$51,$31,$ff,$ff,$ff,$5a,$53,$41,$57,$32,$ff; 1
!byte $ff,$43,$58,$44,$45,$34,$33,$ff,$ff,$20,$56,$46,$54,$52,$35,$ff; 2
!byte $ff,$4e,$42,$48,$47,$59,$36,$ff,$ff,$ff,$4d,$4a,$55,$37,$38,$ff; 3
!byte $ff,$2c,$4b,$49,$4f,$30,$39,$ff,$ff,$2e,$2f,$4c,$3b,$50,$2d,$ff; 4
!byte $ff,$ff,$27,$ff,$5b,$3d,$ff,$ff,$ff,$ff,$0d,$5d,$ff,$5c,$ff,$ff; 5
!byte $ff,$ff,$ff,$ff,$ff,$ff,$08,$ff,$ff,$31,$ff,$34,$37,$ff,$ff,$ff; 6
!byte $30,$ff,$32,$35,$36,$38,$1b,$ff,$8a,$ff,$33,$ff,$ff,$39,$ff,$ff; 7
