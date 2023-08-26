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

MIDI1ADDR = $70
MIDI2ADDR = $72
MIDI3ADDR = $74
MIDI1DELAY = $76
MIDI2DELAY = $77
MIDI3DELAY = $78


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

        +ayWrite AY_PSG0, AY_CHA_AMPL, $0f
        +ayWrite AY_PSG0, AY_CHB_AMPL, $0f
        +ayWrite AY_PSG0, AY_CHC_AMPL, $0f
        ;+ayWrite AY_PSG0, AY_NOISE_GEN, 31
        +ayWrite AY_PSG0, AY_ENABLES, $38

        +aySetEnvShape AY_PSG0, AY_ENV_SHAPE_FADE_OUT
        +aySetEnvelopePeriod AY_PSG0, 1200

        lda #$40
        sta  VIA_IO_ADDR_ACR

        lda #$c0
        sta  VIA_IO_ADDR_IER

        lda #$b7
        sta VIA_IO_ADDR_T1C_L
        lda #$55
        sta VIA_IO_ADDR_T1C_H
        +hbc56SetViaCallback timerHandler

        +store16 MIDI1ADDR, tones1
        +store16 MIDI2ADDR, tones2
        +store16 MIDI3ADDR, tones3

        lda (MIDI1ADDR)
        sta MIDI1DELAY
        lda (MIDI2ADDR)
        sta MIDI2DELAY
        lda (MIDI3ADDR)
        sta MIDI3DELAY

        cli

        jmp hbc56Stop

timerHandler:
        bit VIA_IO_ADDR_T1C_L
        lda MIDI1DELAY
        bne +
        jsr playNote1
+
        dec MIDI1DELAY
        lda MIDI2DELAY
        bne +
        jsr playNote2
+
        dec MIDI2DELAY
        lda MIDI3DELAY
        bne +
        jsr playNote3

+
        dec MIDI3DELAY
        lda MIDI3DELAY
        cmp #$fe
        beq +
        rts
+
        +store16 MIDI1ADDR, tones1
        +store16 MIDI2ADDR, tones2
        +store16 MIDI3ADDR, tones3

        lda (MIDI1ADDR)
        sta MIDI1DELAY
        lda (MIDI2ADDR)
        sta MIDI2DELAY
        lda (MIDI3ADDR)
        sta MIDI3DELAY

        
        rts

playNote1:
        +inc16 MIDI1ADDR
        lda (MIDI1ADDR)
        beq @stopNote1
        tay
        lda midiNotesL, y
        +ayWriteA AY_PSG0, AY_CHA_TONE_L
        lda midiNotesH, y
        +ayWriteA AY_PSG0, AY_CHA_TONE_H
        +ayWrite AY_PSG0, AY_CHA_AMPL, 0x1f
        +aySetEnvShape AY_PSG0, AY_ENV_SHAPE_FADE_OUT
        bra @setupNext        
@stopNote1:
        +ayWrite AY_PSG0, AY_CHA_TONE_L, 0
        +ayWrite AY_PSG0, AY_CHA_TONE_H, 0
        +ayWrite AY_PSG0, AY_CHA_AMPL, 0
@setupNext:
        +inc16 MIDI1ADDR
        lda (MIDI1ADDR)
        sta MIDI1DELAY
        rts

playNote2:
        +inc16 MIDI2ADDR
        lda (MIDI2ADDR)
        beq @stopNote2
        tay
        lda midiNotesL, y
        +ayWriteA AY_PSG0, AY_CHB_TONE_L
        lda midiNotesH, y
        +ayWriteA AY_PSG0, AY_CHB_TONE_H
        +ayWrite AY_PSG0, AY_CHB_AMPL, 0x1f
        +aySetEnvShape AY_PSG0, AY_ENV_SHAPE_FADE_OUT
        bra @setupNext        
@stopNote2:
        +ayWrite AY_PSG0, AY_CHB_TONE_L, 0
        +ayWrite AY_PSG0, AY_CHB_TONE_H, 0
        +ayWrite AY_PSG0, AY_CHB_AMPL, 0
@setupNext:
        +inc16 MIDI2ADDR
        lda (MIDI2ADDR)
        sta MIDI2DELAY
        rts


playNote3:
        +inc16 MIDI3ADDR
        lda (MIDI3ADDR)
        beq @stopNote3
        tay
        lda midiNotesL, y
        +ayWriteA AY_PSG0, AY_CHC_TONE_L
        lda midiNotesH, y
        +ayWriteA AY_PSG0, AY_CHC_TONE_H
        +ayWrite AY_PSG0, AY_CHC_AMPL, 0x1f
        +aySetEnvShape AY_PSG0, AY_ENV_SHAPE_FADE_OUT
        bra @setupNext        
@stopNote3:
        +ayWrite AY_PSG0, AY_CHC_TONE_L, 0
        +ayWrite AY_PSG0, AY_CHC_TONE_H, 0
        +ayWrite AY_PSG0, AY_CHC_AMPL, 0
@setupNext:
        +inc16 MIDI3ADDR
        lda (MIDI3ADDR)
        sta MIDI3DELAY
        rts

toneDelay:
	ldy #255
	jsr customDelay
	ldy #255
	jmp customDelay

shortDelay:
	ldy #16
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

tones1:
!bin "overworld.mid.t01.bin"
tones2:
!bin "overworld.mid.t02.bin"
tones3:
!bin "overworld.mid.t03.bin"


; midi notes id to frequency. f=440 * 2^((n-69)/12)

midiNotesL:
+ayToneByteL 8.17579891564371
+ayToneByteL 8.66195721802725
+ayToneByteL 9.17702399741899
+ayToneByteL 9.72271824131503
+ayToneByteL 10.3008611535272
+ayToneByteL 10.9133822322814
+ayToneByteL 11.5623257097386
+ayToneByteL 12.2498573744297
+ayToneByteL 12.9782717993733
+ayToneByteL 13.75
+ayToneByteL 14.5676175474403
+ayToneByteL 15.4338531642539
+ayToneByteL 16.3515978312874
+ayToneByteL 17.3239144360545
+ayToneByteL 18.354047994838
+ayToneByteL 19.4454364826301
+ayToneByteL 20.6017223070544
+ayToneByteL 21.8267644645627
+ayToneByteL 23.1246514194772
+ayToneByteL 24.4997147488593
+ayToneByteL 25.9565435987466
+ayToneByteL 27.5
+ayToneByteL 29.1352350948806
+ayToneByteL 30.8677063285078
+ayToneByteL 32.7031956625748
+ayToneByteL 34.647828872109
+ayToneByteL 36.7080959896759
+ayToneByteL 38.8908729652601
+ayToneByteL 41.2034446141088
+ayToneByteL 43.6535289291255
+ayToneByteL 46.2493028389543
+ayToneByteL 48.9994294977187
+ayToneByteL 51.9130871974931
+ayToneByteL 55
+ayToneByteL 58.2704701897613
+ayToneByteL 61.7354126570155
+ayToneByteL 65.4063913251497
+ayToneByteL 69.295657744218
+ayToneByteL 73.4161919793519
+ayToneByteL 77.7817459305202
+ayToneByteL 82.4068892282175
+ayToneByteL 87.307057858251
+ayToneByteL 92.4986056779086
+ayToneByteL 97.9988589954373
+ayToneByteL 103.826174394986
+ayToneByteL 110
+ayToneByteL 116.540940379522
+ayToneByteL 123.470825314031
+ayToneByteL 130.812782650299
+ayToneByteL 138.591315488436
+ayToneByteL 146.832383958704
+ayToneByteL 155.56349186104
+ayToneByteL 164.813778456435
+ayToneByteL 174.614115716502
+ayToneByteL 184.997211355817
+ayToneByteL 195.997717990875
+ayToneByteL 207.652348789973
+ayToneByteL 220
+ayToneByteL 233.081880759045
+ayToneByteL 246.941650628062
+ayToneByteL 261.625565300599
+ayToneByteL 277.182630976872
+ayToneByteL 293.664767917408
+ayToneByteL 311.126983722081
+ayToneByteL 329.62755691287
+ayToneByteL 349.228231433004
+ayToneByteL 369.994422711634
+ayToneByteL 391.995435981749
+ayToneByteL 415.304697579945
+ayToneByteL 440
+ayToneByteL 466.16376151809
+ayToneByteL 493.883301256124
+ayToneByteL 523.251130601197
+ayToneByteL 554.365261953744
+ayToneByteL 587.329535834815
+ayToneByteL 622.253967444162
+ayToneByteL 659.25511382574
+ayToneByteL 698.456462866008
+ayToneByteL 739.988845423269
+ayToneByteL 783.990871963499
+ayToneByteL 830.60939515989
+ayToneByteL 880
+ayToneByteL 932.32752303618
+ayToneByteL 987.766602512248
+ayToneByteL 1046.50226120239
+ayToneByteL 1108.73052390749
+ayToneByteL 1174.65907166963
+ayToneByteL 1244.50793488832
+ayToneByteL 1318.51022765148
+ayToneByteL 1396.91292573202
+ayToneByteL 1479.97769084654
+ayToneByteL 1567.981743927
+ayToneByteL 1661.21879031978
+ayToneByteL 1760
+ayToneByteL 1864.65504607236
+ayToneByteL 1975.5332050245
+ayToneByteL 2093.00452240479
+ayToneByteL 2217.46104781498
+ayToneByteL 2349.31814333926
+ayToneByteL 2489.01586977665
+ayToneByteL 2637.02045530296
+ayToneByteL 2793.82585146403
+ayToneByteL 2959.95538169308
+ayToneByteL 3135.96348785399
+ayToneByteL 3322.43758063956
+ayToneByteL 3520
+ayToneByteL 3729.31009214472
+ayToneByteL 3951.06641004899
+ayToneByteL 4186.00904480958
+ayToneByteL 4434.92209562995
+ayToneByteL 4698.63628667852
+ayToneByteL 4978.03173955329
+ayToneByteL 5274.04091060592
+ayToneByteL 5587.65170292806
+ayToneByteL 5919.91076338615
+ayToneByteL 6271.92697570798
+ayToneByteL 6644.87516127912
+ayToneByteL 7040
+ayToneByteL 7458.62018428944
+ayToneByteL 7902.13282009799
+ayToneByteL 8372.01808961916
+ayToneByteL 8869.8441912599
+ayToneByteL 9397.27257335704
+ayToneByteL 9956.06347910659
+ayToneByteL 10548.0818212118
+ayToneByteL 11175.3034058561
+ayToneByteL 11839.8215267723
+ayToneByteL 12543.853951416


midiNotesH:
+ayToneByteH 8.17579891564371
+ayToneByteH 8.66195721802725
+ayToneByteH 9.17702399741899
+ayToneByteH 9.72271824131503
+ayToneByteH 10.3008611535272
+ayToneByteH 10.9133822322814
+ayToneByteH 11.5623257097386
+ayToneByteH 12.2498573744297
+ayToneByteH 12.9782717993733
+ayToneByteH 13.75
+ayToneByteH 14.5676175474403
+ayToneByteH 15.4338531642539
+ayToneByteH 16.3515978312874
+ayToneByteH 17.3239144360545
+ayToneByteH 18.354047994838
+ayToneByteH 19.4454364826301
+ayToneByteH 20.6017223070544
+ayToneByteH 21.8267644645627
+ayToneByteH 23.1246514194772
+ayToneByteH 24.4997147488593
+ayToneByteH 25.9565435987466
+ayToneByteH 27.5
+ayToneByteH 29.1352350948806
+ayToneByteH 30.8677063285078
+ayToneByteH 32.7031956625748
+ayToneByteH 34.647828872109
+ayToneByteH 36.7080959896759
+ayToneByteH 38.8908729652601
+ayToneByteH 41.2034446141088
+ayToneByteH 43.6535289291255
+ayToneByteH 46.2493028389543
+ayToneByteH 48.9994294977187
+ayToneByteH 51.9130871974931
+ayToneByteH 55
+ayToneByteH 58.2704701897613
+ayToneByteH 61.7354126570155
+ayToneByteH 65.4063913251497
+ayToneByteH 69.295657744218
+ayToneByteH 73.4161919793519
+ayToneByteH 77.7817459305202
+ayToneByteH 82.4068892282175
+ayToneByteH 87.307057858251
+ayToneByteH 92.4986056779086
+ayToneByteH 97.9988589954373
+ayToneByteH 103.826174394986
+ayToneByteH 110
+ayToneByteH 116.540940379522
+ayToneByteH 123.470825314031
+ayToneByteH 130.812782650299
+ayToneByteH 138.591315488436
+ayToneByteH 146.832383958704
+ayToneByteH 155.56349186104
+ayToneByteH 164.813778456435
+ayToneByteH 174.614115716502
+ayToneByteH 184.997211355817
+ayToneByteH 195.997717990875
+ayToneByteH 207.652348789973
+ayToneByteH 220
+ayToneByteH 233.081880759045
+ayToneByteH 246.941650628062
+ayToneByteH 261.625565300599
+ayToneByteH 277.182630976872
+ayToneByteH 293.664767917408
+ayToneByteH 311.126983722081
+ayToneByteH 329.62755691287
+ayToneByteH 349.228231433004
+ayToneByteH 369.994422711634
+ayToneByteH 391.995435981749
+ayToneByteH 415.304697579945
+ayToneByteH 440
+ayToneByteH 466.16376151809
+ayToneByteH 493.883301256124
+ayToneByteH 523.251130601197
+ayToneByteH 554.365261953744
+ayToneByteH 587.329535834815
+ayToneByteH 622.253967444162
+ayToneByteH 659.25511382574
+ayToneByteH 698.456462866008
+ayToneByteH 739.988845423269
+ayToneByteH 783.990871963499
+ayToneByteH 830.60939515989
+ayToneByteH 880
+ayToneByteH 932.32752303618
+ayToneByteH 987.766602512248
+ayToneByteH 1046.50226120239
+ayToneByteH 1108.73052390749
+ayToneByteH 1174.65907166963
+ayToneByteH 1244.50793488832
+ayToneByteH 1318.51022765148
+ayToneByteH 1396.91292573202
+ayToneByteH 1479.97769084654
+ayToneByteH 1567.981743927
+ayToneByteH 1661.21879031978
+ayToneByteH 1760
+ayToneByteH 1864.65504607236
+ayToneByteH 1975.5332050245
+ayToneByteH 2093.00452240479
+ayToneByteH 2217.46104781498
+ayToneByteH 2349.31814333926
+ayToneByteH 2489.01586977665
+ayToneByteH 2637.02045530296
+ayToneByteH 2793.82585146403
+ayToneByteH 2959.95538169308
+ayToneByteH 3135.96348785399
+ayToneByteH 3322.43758063956
+ayToneByteH 3520
+ayToneByteH 3729.31009214472
+ayToneByteH 3951.06641004899
+ayToneByteH 4186.00904480958
+ayToneByteH 4434.92209562995
+ayToneByteH 4698.63628667852
+ayToneByteH 4978.03173955329
+ayToneByteH 5274.04091060592
+ayToneByteH 5587.65170292806
+ayToneByteH 5919.91076338615
+ayToneByteH 6271.92697570798
+ayToneByteH 6644.87516127912
+ayToneByteH 7040
+ayToneByteH 7458.62018428944
+ayToneByteH 7902.13282009799
+ayToneByteH 8372.01808961916
+ayToneByteH 8869.8441912599
+ayToneByteH 9397.27257335704
+ayToneByteH 9956.06347910659
+ayToneByteH 10548.0818212118
+ayToneByteH 11175.3034058561
+ayToneByteH 11839.8215267723
+ayToneByteH 12543.853951416