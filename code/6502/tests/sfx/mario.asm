; Troy's HBC-56 - Mario bros tune
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;

!src "hbc56kernel.inc"


hbc56Meta:
        +setHbcMetaTitle "MARIO BROS AUDIO"
        rts


TONE0 = $60
TONE1 = $61
NOISE0 = $62


hbc56Main:

        jsr tmsModeGraphicsII

        +tmsColorFgBg TMS_WHITE, TMS_BLACK
        jsr tmsSetBackground

        +tmsDisableInterrupts
        +tmsDisableOutput

        +tmsSetAddrPattTable
        +tmsSendData marioPatt, $1800

        +tmsSetAddrColorTable
        +tmsSendData marioCol, $1800

        +tmsSetAddrNameTable
	+tmsPutSeq 0, 256
	+tmsPutSeq 0, 256
	+tmsPutSeq 0, 256

        +tmsEnableOutput


	jsr ayInit
        lda #0
        sta TONE0
        sta TONE1
        sta NOISE0

	

        +ayWrite AY_PSG0, AY_ENABLES, $3b
        +ayWrite AY_PSG0, AY_CHA_AMPL, $00
        +ayWrite AY_PSG0, AY_CHB_AMPL, $00
        +ayWrite AY_PSG0, AY_CHC_AMPL, $0f


.loop:

	!macro playNote .note {
		+ayPlayNote AY_PSG0, AY_CHC, .note
		jsr toneDelay
		+ayStop AY_PSG0, AY_CHC
		jsr shortDelay
	}


	+playNote NOTE_FREQ_E4
	+playNote NOTE_FREQ_E4
	jsr toneDelay
	+playNote NOTE_FREQ_E4

	jsr toneDelay
	+playNote NOTE_FREQ_C4
	+playNote NOTE_FREQ_E4
	jsr toneDelay

	+playNote NOTE_FREQ_G4
	jsr toneDelay
	jsr toneDelay
	jsr toneDelay

	+playNote NOTE_FREQ_G3
	jsr toneDelay
	jsr toneDelay
	jsr toneDelay

	+playNote NOTE_FREQ_C4
	jsr toneDelay
	jsr toneDelay
	+playNote NOTE_FREQ_G3

	jsr toneDelay
	jsr toneDelay
	+playNote NOTE_FREQ_E3
	jsr toneDelay

	jsr toneDelay
	+playNote NOTE_FREQ_A3
	jsr toneDelay
	+playNote NOTE_FREQ_B3

	jsr toneDelay
	+playNote NOTE_FREQ_AS3
	+playNote NOTE_FREQ_A3
	jsr toneDelay

	+playNote NOTE_FREQ_G3
	+playNote NOTE_FREQ_E4
	+playNote NOTE_FREQ_G4

	+playNote NOTE_FREQ_A4
	jsr toneDelay
	+playNote NOTE_FREQ_F4
	+playNote NOTE_FREQ_G4

	jsr toneDelay
	+playNote NOTE_FREQ_E4
	jsr toneDelay
	+playNote NOTE_FREQ_C4

	+playNote NOTE_FREQ_D4
	+playNote NOTE_FREQ_B3
	jsr toneDelay
	jsr toneDelay

	+playNote NOTE_FREQ_C4
	jsr toneDelay
	jsr toneDelay
	+playNote NOTE_FREQ_G3

	jsr toneDelay
	jsr toneDelay
	+playNote NOTE_FREQ_E3
	jsr toneDelay

	jsr toneDelay
	+playNote NOTE_FREQ_A3
	jsr toneDelay
	+playNote NOTE_FREQ_B3

	jsr toneDelay
	+playNote NOTE_FREQ_AS3
	+playNote NOTE_FREQ_A3
	jsr toneDelay

	+playNote NOTE_FREQ_G3
	+playNote NOTE_FREQ_E4
	+playNote NOTE_FREQ_G4

	+playNote NOTE_FREQ_A4
	jsr toneDelay
	+playNote NOTE_FREQ_F4
	+playNote NOTE_FREQ_G4

	jsr toneDelay
	+playNote NOTE_FREQ_E4
	jsr toneDelay
	+playNote NOTE_FREQ_C4

	+playNote NOTE_FREQ_D4
	+playNote NOTE_FREQ_B3
	jsr toneDelay
	jsr medDelay

        jmp .loop

toneDelay:
	ldy #200
	jsr customDelay
	ldy #200
	jmp customDelay

shortDelay:
	ldy #128
	jmp customDelay

medDelay:
	jsr delay
	jsr delay
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

customDelay:
	ldx #255
-
	dex
	bne -
	ldx #255
	dey
	bne -
	rts


marioPatt:
!bin "mario.gfx2p"
marioCol:
!bin "mario.gfx2c"