!to "invaders.o", plain

HBC56_INT_VECTOR = onVSync

!source "../lib/hbc56.asm"

TMS_MODEL = 9929
!source "../lib/gfx/tms9918.asm"
!source "../lib/gfx/fonts/tms9918font1.asm"

!source "../lib/gfx/bitmap.asm"
!source "../lib/inp/nes.asm"

TICKS_L = $48
TICKS_H = $49


onVSync:
        pha
        lda TICKS_L
        clc
        adc #1
        cmp #TMS_FPS
        bne +
        lda #0
        inc TICKS_H
+  
        sta TICKS_L
        +tmsReadStatus
        pla      
        rti


main:
        jsr tmsInit

        +tmsSetAddrColorTable
        +tmsSendData COLORTAB, 32

        +tmsSetAddrFontTableInd 128
        +tmsSendData INVADER1, 16 * 8 * 3  ; first 3 invaders

        +tmsColorFgBg TMS_WHITE, TMS_BLACK
        jsr tmsSetBackground


        +tmsPrint "SCORE 00000   HI SCORE 00000", 2, 0
.loop:
       

!for i, 6 {       
        +tmsSetPos i, 4
        +tmsSendData SETUP31, 24
        +tmsSetPos i, 6
        +tmsSendData SETUP21, 24
        +tmsSetPos i, 8
        +tmsSendData SETUP21, 24
        +tmsSetPos i, 10
        +tmsSendData SETUP11, 24
        +tmsSetPos i, 12
        +tmsSendData SETUP11, 24

        jsr medDelay

        +tmsSetPos i, 4
        +tmsSendData SETUP32, 24
        +tmsSetPos i, 6
        +tmsSendData SETUP22, 24
        +tmsSetPos i, 8
        +tmsSendData SETUP22, 24
        +tmsSetPos i, 10
        +tmsSendData SETUP12, 24
        +tmsSetPos i, 12
        +tmsSendData SETUP12, 24

        jsr medDelay

        +tmsSetPos i, 4
        +tmsSendData SETUP33, 24
        +tmsSetPos i, 6
        +tmsSendData SETUP23, 24
        +tmsSetPos i, 8
        +tmsSendData SETUP23, 24
        +tmsSetPos i, 10
        +tmsSendData SETUP13, 24
        +tmsSetPos i, 12
        +tmsSendData SETUP13, 24
        jsr medDelay

        +tmsSetPos i, 4
        +tmsSendData SETUP34, 24
        +tmsSetPos i, 6
        +tmsSendData SETUP24, 24
        +tmsSetPos i, 8
        +tmsSendData SETUP24, 24
        +tmsSetPos i, 10
        +tmsSendData SETUP14, 24
        +tmsSetPos i, 12
        +tmsSendData SETUP14, 24

        jsr medDelay
}


!for i, 6 {       
        +tmsSetPos 7 - i, 4
        +tmsSendData SETUP34, 24
        +tmsSetPos 7 - i, 6
        +tmsSendData SETUP24, 24
        +tmsSetPos 7 - i, 8
        +tmsSendData SETUP24, 24
        +tmsSetPos 7 - i, 10
        +tmsSendData SETUP14, 24
        +tmsSetPos 7 - i, 12
        +tmsSendData SETUP14, 24

        jsr medDelay

        +tmsSetPos 7 - i, 4
        +tmsSendData SETUP33, 24
        +tmsSetPos 7 - i, 6
        +tmsSendData SETUP23, 24
        +tmsSetPos 7 - i, 8
        +tmsSendData SETUP23, 24
        +tmsSetPos 7 - i, 10
        +tmsSendData SETUP13, 24
        +tmsSetPos 7 - i, 12
        +tmsSendData SETUP13, 24

        jsr medDelay

        +tmsSetPos 7 - i, 4
        +tmsSendData SETUP32, 24
        +tmsSetPos 7 - i, 6
        +tmsSendData SETUP22, 24
        +tmsSetPos 7 - i, 8
        +tmsSendData SETUP22, 24
        +tmsSetPos 7 - i, 10
        +tmsSendData SETUP12, 24
        +tmsSetPos 7 - i, 12
        +tmsSendData SETUP12, 24
        jsr medDelay

        +tmsSetPos 7 - i, 4
        +tmsSendData SETUP31, 24
        +tmsSetPos 7 - i, 6
        +tmsSendData SETUP21, 24
        +tmsSetPos 7 - i, 8
        +tmsSendData SETUP21, 24
        +tmsSetPos 7 - i, 10
        +tmsSendData SETUP11, 24
        +tmsSetPos 7 - i, 12
        +tmsSendData SETUP11, 24

        jsr medDelay
}

        jmp .loop


medDelay:
	jsr delay
	jsr delay


delay:
	ldx #255
	ldy #255
-
	dex
	bne -
	ldx #255
	dey
	bne -
	rts

COLORTAB:
       !byte $00,$00,$00,$00
       !byte $F0,$F0,$F0,$00      ; SHIELDS
       !byte $F0,$F0            ; NUMBERS
       !byte $F0,$F0,$F0,$F0      ; LETTERS
       !byte $00,$00
       !byte $30,$30            ; INVADER 3
       !byte $50,$50            ; INVADER 2
       !byte $60,$60            ; INVADER 1
       !byte $40,$00            ; BOTTOM SCREEN
       !byte $00,$00,$00,$00      ; TOP SCREEN
       !byte $00,$00            ; TOP SCREEN

SETUP11: !byte 32
 
!for i, 11 { !byte 128, 129 } 
 !byte 32
SETUP21: !byte 32
 
!for i, 11 { !byte 144, 145 } 
 !byte 32
SETUP31: !byte 32
 
!for i, 11 { !byte 160, 161 } 
 !byte 32
SETUP12: !byte 32 
!for i, 11 { !byte 130, 131 }
!byte 32
SETUP22: !byte 32 
!for i, 11 { !byte 146, 147 }
!byte 32
SETUP32: !byte 32 
!for i, 11 { !byte 162, 163 }
!byte 32
SETUP13: !byte 32 
!for i, 11 { !byte 132, 133 }
!byte 32
SETUP23: !byte 32 
!for i, 11 { !byte 148, 149 }
!byte 32
SETUP33: !byte 32 
!for i, 11 { !byte 164, 165 }
!byte 32
SETUP14: !byte 32 
!for i, 11 { !byte 134, 135 }
!byte 32
SETUP24: !byte 32 
!for i, 11 { !byte 150, 151 }
!byte 32
SETUP34: !byte 32 
!for i, 11 { !byte 166, 167 }
!byte 32

INVADER1:
IP10L  !byte $1E,$FF,$CC,$FF,$FF,$12,$21,$C0
IP10R  !byte $00,$C0,$C0,$C0,$C0,$00,$00,$C0
IP12L  !byte $07,$3F,$33,$3F,$3F,$04,$08,$0C
IP12R  !byte $80,$F0,$30,$F0,$F0,$80,$40,$C0
IP14L  !byte $01,$0F,$0C,$0F,$0F,$01,$02,$0C
IP14R  !byte $E0,$FC,$CC,$FC,$FC,$20,$10,$0C
IP16L  !byte $00,$03,$03,$03,$03,$00,$00,$00
IP16R  !byte $78,$FF,$33,$FF,$FF,$48,$84,$CC
IP18LT !byte $00,$00,$00,$00,$1E,$FF,$CC,$FF
IP18RT !byte $00,$00,$00,$00,$00,$C0,$C0,$C0
IP18LB !byte $FF,$12,$21,$33,$00,$00,$00,$00
IP18RB !byte $C0,$00,$00,$00,$00,$00,$00,$00
       !byte $00,$00,$33,$00,$00,$21,$1E,$00
       !byte $00,$00,$00,$00,$00,$00,$00,$00
       !byte $00,$00,$33,$00,$00,$00,$1E,$21
       !byte $00,$00,$00,$00,$00,$00,$00,$00

INVADER2:
IP20L  !byte $63,$22,$3E,$6B,$FF,$BE,$A2,$36
IP20R  !byte $00,$00,$00,$00,$80,$80,$80,$00
IP22L  !byte $18,$08,$2F,$2A,$3F,$0F,$08,$30
IP22R  !byte $C0,$80,$A0,$A0,$E0,$80,$80,$60
IP24L  !byte $06,$02,$03,$06,$0F,$0B,$0A,$03
IP24R  !byte $30,$20,$E0,$B0,$F8,$E8,$28,$60
IP26L  !byte $01,$00,$02,$02,$03,$00,$00,$03
IP26R  !byte $8C,$88,$FA,$AA,$FE,$F8,$88,$06
IP28LT !byte $00,$00,$00,$00,$63,$22,$BE,$AA
IP28RT !byte $00,$00,$00,$00,$00,$00,$80,$80
IP28LB !byte $FF,$3E,$22,$C1,$00,$00,$00,$00
IP28RB !byte $80,$00,$00,$80,$00,$00,$00,$00
       !byte $00,$00,$00,$14,$00,$22,$1C,$00
       !byte $00,$00,$00,$00,$00,$00,$00,$00
       !byte $00,$00,$00,$14,$00,$00,$1C,$22
       !byte $00,$00,$00,$00,$00,$00,$00,$00

INVADER3:
IP30L  !byte $08,$1C,$3E,$6B,$7F,$14,$22,$41
IP30R  !byte $00,$00,$00,$00,$00,$00,$00,$00
IP32L  !byte $02,$07,$0F,$1A,$1F,$05,$08,$05
IP32R  !byte $00,$00,$80,$C0,$C0,$00,$80,$00
IP34L  !byte $00,$01,$03,$06,$07,$01,$02,$04
IP34R  !byte $80,$C0,$E0,$B0,$F0,$40,$20,$10
IP36L  !byte $00,$00,$00,$01,$01,$00,$00,$00
IP36R  !byte $20,$70,$F8,$AC,$FC,$50,$88,$50
IP38LT !byte $00,$00,$00,$00,$08,$1C,$3E,$6B
IP38RT !byte $00,$00,$00,$00,$00,$00,$00,$00
IP38LB !byte $7F,$14,$22,$14,$00,$00,$00,$00
IP38RB !byte $00,$00,$00,$00,$00,$00,$00,$00
       !byte $00,$00,$00,$14,$00,$22,$1C,$00
       !byte $00,$00,$00,$00,$00,$00,$00,$00
       !byte $00,$00,$00,$14,$00,$00,$1C,$22
       !byte $00,$00,$00,$00,$00,$00,$00,$00

SHIELD !byte $30,$31,$32,$FE,$FF,3
       !byte $36,$37,$38,$FE,$FF,4
       !byte $3C,$3D,$3E,$FE,$FF,3
       !byte $42,$43,$44,$FE,$FF,10
       !byte $33,$34,$35,$FE,$FF,3
       !byte $39,$3A,$3B,$FE,$FF,4
       !byte $3F,$40,$41,$FE,$FF,3
       !byte $45,$46,$47,$FD
TITLES !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$E4,$D9,$B0,$D9,$DE
       !byte $E6,$D1,$D4,$D5,$E2,$E3,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$A0,$9F,$99
       !byte $9E,$A4,$A3,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$22,$23,$85,$7F,$81,$80,$FF,$FF,$FF,$10,$11,$81,$80
       !byte $7F,$82,$80,$FF,$FF,$FF,$06,$07,$81,$85,$7F,$83,$80,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$98,$99,$A4,$70,$A4,$98,$95,$70,$A9,$95,$9C,$9C,$9F,$A7
       !byte $70,$A3,$91,$A5,$93,$95,$A2,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$99,$9E,$70,$A4,$98,$95,$70,$93,$95,$9E,$A4,$95,$A2,$70
       !byte $96,$9F,$A2,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$9D,$91,$A8,$99,$9D,$A5,$9D,$70,$A0,$9F,$99,$9E,$A4,$A3
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$8F,$8F,$8F,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$95,$A8,$A4,$A2,$91,$70,$9D,$99,$A3,$A3,$99,$9C,$95,$70
       !byte $92,$91,$A3,$95,$70,$91,$A7,$91,$A2,$94,$95,$94,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$91,$A4,$70,$83,$80,$80,$80,$70,$A0,$9F,$99,$9E,$A4,$A3
       !byte $7E,$70,$70,$9F,$9E,$95,$70,$92,$91,$A3,$95,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$A2,$95,$A0,$91,$99,$A2,$95,$94,$70,$95,$A6,$95,$A2,$A9
       !byte $70,$81,$80,$7C,$80,$80,$80,$70,$A0,$9F,$99,$9E,$A4,$A3,$7E,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$D9,$DE,$E6,$D1,$D4,$D5,$E2
       !byte $B0,$DF,$E0,$E4,$D9,$DF,$DE,$E3,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$C1,$BE,$B0,$DD,$D5,$E2,$D5,$DC,$E9,$B0
       !byte $D1,$D7,$D7,$E2,$D5,$E3,$E3,$D9,$E6,$D5,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$C2,$BE,$B0,$D4,$DF,$E7,$DE,$E2,$D9,$D7
       !byte $D8,$E4,$B0,$DE,$D1,$E3,$E4,$E9,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$69,$5F,$65,$62,$30,$53
       !byte $58,$5F,$59,$53,$55,$4F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$90,$81,$89,$88,$81,$70,$A4,$95,$A8,$91,$A3
       !byte $70,$99,$9E,$A3,$A4,$A2,$A5,$9D,$95,$9E,$A4,$A3,$FF,$FF,$FF,$FF