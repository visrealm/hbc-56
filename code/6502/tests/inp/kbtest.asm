; Troy's HBC-56 - Input test
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;


!src "hbc56kernel.inc"

Y_OFFSET          = 4

PRESSED_KEY_COUNT = HBC56_USER_ZP_START

pressedTable    = $1000
extPressedTable = $1100

hbc56Meta:
        +setHbcMetaTitle "KEYBOARD TEST"
        rts

hbc56Main:
        jsr tmsModeGraphicsI

        lda #TMS_R1_SPRITE_MAG2
        jsr tmsReg1ClearFields
        lda #TMS_R1_SPRITE_16
        jsr tmsReg1SetFields

        +tmsSetAddrColorTable
        +tmsSendData colorTab, 32
        
        +tmsSetAddrNameTable
        lda #$f9
        jsr _tmsSendPage
        jsr _tmsSendPage
        jsr _tmsSendPage

        +tmsSetAddrPattTable
        +tmsSendData keyboardPatt, 256*8

        +tmsSetPosWrite 0, Y_OFFSET
        +tmsSendData keyboardInd, 512

        +tmsSetAddrSpritePattTable
        +tmsSendData sprites, 4*8

        +tmsCreateSprite 0, 0, 0, $d0, TMS_DK_GREEN
        +tmsCreateSprite 1, 0, 0, $d0, TMS_DK_GREEN
        +tmsCreateSprite 2, 0, 0, $d0, TMS_DK_GREEN
        +tmsCreateSprite 3, 0, 0, $d0, TMS_DK_GREEN
        +tmsCreateSprite 4, 0, 0, $d0, TMS_DK_GREEN
        +tmsCreateSprite 5, 0, 0, $d0, TMS_DK_GREEN
        +tmsCreateSprite 6, 0, 0, $d0, TMS_DK_GREEN
        +tmsCreateSprite 7, 0, 0, $d0, TMS_DK_GREEN

        +memset pressedTable, 0, 256
        +memset extPressedTable, 0, 256

        +tmsEnableOutput

        +hbc56SetVsyncCallback outputLoop

        cli
        +tmsEnableInterrupts


inputLoop:

        jsr kbReadByte         ; load scancode into X
        cpx #0
        beq inputLoop

        cpx #KB_RELEASE
        beq keyReleased

        cpx #KB_EXT_KEY
        beq extendedKey

        jmp keyPressed

; standard key pressed
keyPressed:
        lda #1
        sta pressedTable,x
        jmp inputLoop

keyReleased:
        jsr kbReadByte
        cpx #0
        beq keyReleased

        lda #0
        sta pressedTable,x
        jmp inputLoop

extendedKey:
        ; wait until the next key...
        jsr kbReadByte
        cpx #0
        beq extendedKey

        cpx #KB_RELEASE
        beq extKeyReleased

        jmp extKeyPressed

; standard key pressed
extKeyPressed:
        lda #1
        sta extPressedTable,x
        jmp inputLoop

extKeyReleased:
        jsr kbReadByte
        cpx #0
        beq extKeyReleased
        lda #0
        sta extPressedTable,x
        jmp inputLoop


showKey:
        txa
        pha
        ldy keyPosY,x
        lda keyPosX,x
        tax

        lda PRESSED_KEY_COUNT
        jsr tmsSetSpriteTmpAddress
        jsr tmsSetAddressWrite
        tya
        clc
        adc #(Y_OFFSET*8-1)
        +tmsPut
        txa
        +tmsPut
        inc PRESSED_KEY_COUNT
        pla
        tax
        jmp doneShowKey

showExtKey:
        txa
        pha
        ldy extKeyPosY,x
        lda extKeyPosX,x
        tax

        lda PRESSED_KEY_COUNT
        jsr tmsSetSpriteTmpAddress
        jsr tmsSetAddressWrite
        tya
        clc
        adc #(Y_OFFSET*8-1)
        +tmsPut
        txa
        +tmsPut
        inc PRESSED_KEY_COUNT
        pla
        tax
        jmp doneShowExtKey

outputLoop:
        stx HBC56_TMP_X
        sty HBC56_TMP_Y

        lda #0
        sta PRESSED_KEY_COUNT

        ldx #131        ; max normal key index
-
        lda pressedTable,x
        bne showKey
doneShowKey:
        dex
        bne -

        ldx #125        ; max ext key index
-
        lda extPressedTable,x
        bne showExtKey
doneShowExtKey:
        dex
        bne -


        lda PRESSED_KEY_COUNT
        jsr tmsSetSpriteTmpAddress
        jsr tmsSetAddressWrite
        lda #$d0
        +tmsPut

        +tmsSetColorFgBg TMS_WHITE, TMS_LT_GREEN

        ldx HBC56_TMP_X
        ldy HBC56_TMP_Y

        lda #1
        bit HBC56_TICKS
        beq evenFrame
        jmp oddFrame
	rts

evenFrame:
       !for i,0,8 {
        +tmsSpriteColor i, TMS_TRANSPARENT
       }
       +tmsSetColorFgBg TMS_WHITE, TMS_DK_BLUE
       rts

oddFrame:
       !for i,0,8 {
        +tmsSpriteColor i, TMS_DK_GREEN
       }
       +tmsSetColorFgBg TMS_WHITE, TMS_DK_BLUE
       rts        

keyPosX:
!byte 0,135,0,79,51,23,37,177,0,149,121,93,65, 9, 9,0,0, 54, 9,0,  9,32,24,0,0,0,45,52,37,47,39,0,0,75,60,67,62,69,54,0,0, 69,90,82,92,77,84,0,0,120,105,112,97,107,99,0,0,0,135,127,122,114,129,0,0,150,142,137,152,159,144,0,0,165,180,157,172,167,174,0,0,0,187,0,182,189,0,0, 9,195,202,197,0,212,0,0,0,0,0,0,0,0,202,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 9,0,163,0,0,0,0,0,205,0,0,0,0,107
keyPosY:
!byte 0, 25,0,25,25,25,25, 25,0, 25, 25,25,25,56,40,0,0,104,88,0,104,56,40,0,0,0,88,72,72,56,40,0,0,88,88,72,56,40,40,0,0,104,88,72,56,56,40,0,0, 88, 88, 72,72, 56,40,0,0,0, 88, 72, 56, 40, 40,0,0, 88, 72, 56, 56, 40, 40,0,0, 88, 88, 72, 72, 56, 40,0,0,0, 72,0, 56, 40,0,0,72, 88, 72, 56,0, 56,0,0,0,0,0,0,0,0, 40,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,25,0, 25,0,0,0,0,0, 25,0,0,0,0, 25
extKeyPosX:
!byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,143,191,0,173,0,0,0,0,0,0,0,0,0,0, 24,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,158,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,233,0,203,233,0,0,0,188,233,218,0,233,218,0,0,0,0,233,0,0,233
extKeyPosY:
!byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,104, 25,0,104,0,0,0,0,0,0,0,0,0,0,104,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,104,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 88,0,104, 40,0,0,0,104, 25,104,0,104, 88,0,0,0,0, 72,0,0, 56

colorTab:
!byte $1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f
!byte $1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$4f

keyboardInd:
!bin "keyboard.ind"
keyboardIndEnd:

keyboardPatt:
!bin "keyboard.patt"
keyboardPattEnd:

sprites:
!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff   ; 14x15  $00
!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$00
!byte $fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc
!byte $fc,$fc,$fc,$fc,$fc,$fc,$fc,$00
!byte $e0,$80,$80,$00,$00,$00,$00,$00   ; 14x15  $00
!byte $00,$00,$00,$00,$80,$80,$e0,$00
!byte $1c,$04,$04,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$04,$04,$1c,$00
