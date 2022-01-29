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

        ; set up sprite mode (16x16, unmagnified)
        lda #TMS_R1_SPRITE_MAG2
        jsr tmsReg1ClearFields
        lda #TMS_R1_SPRITE_16
        jsr tmsReg1SetFields

        ; set up color table
        +tmsSetAddrColorTable
        +tmsSendData colorTab, 32
        
        ; clear the name table
        +tmsSetAddrNameTable
        lda #$f9
        jsr _tmsSendPage
        jsr _tmsSendPage
        jsr _tmsSendPage

        ; load the keyboard glyph data
        +tmsSetAddrPattTable
        +tmsSendData keyboardPatt, 256*8

        ; output the keyboard tiles
        +tmsSetPosWrite 0, Y_OFFSET
        +tmsSendData keyboardInd, 512

        ; set up the overlay sprites
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

        ; clear the key pressed tables
        +memset pressedTable, 0, 256
        +memset extPressedTable, 0, 256

        +tmsEnableOutput

        +hbc56SetVsyncCallback outputLoop

        cli
        +tmsEnableInterrupts

; -----------------------------------------------------------------------------
; Input loop runs continuously and sets the key tables
; -----------------------------------------------------------------------------
inputLoop:

        jsr kbReadByte         ; load scancode into X
        cpx #0
        beq inputLoop

        cpx #KB_RELEASE         ; is it a release code?
        beq keyReleased

        cpx #KB_EXT_KEY         ; is it an extended key code?
        beq extendedKey

        cpx #$e1                ; is it the pause/break key?
        beq pauseBreakLoop
        jmp keyPressed          ; just a regular key (pressed)

; -----------------------------------------------------------------------------
; Pause/break handler (presss/release only sent on key release)
; -----------------------------------------------------------------------------
pauseBreakLoop:
        jsr kbReadByte
        cpx #0
        beq pauseBreakLoop      ; get next scancode (either $14 or $f0)

        cpx #$14                ; if it's $14, then it's a press
        beq pausePressed

        jsr kbWaitForScancode   ; eat the next three scancodes
        jsr kbWaitForScancode
        jsr kbWaitForScancode

        lda #0                  ; mark as released
        sta pressedTable + 2
        jmp keyPressed

pausePressed:
        jsr kbWaitForScancode   ; eat the next scancode

        lda #1                  ; mark as pressed
        sta pressedTable + 2
        jmp keyPressed


; -----------------------------------------------------------------------------
; A standard key was pressed (scancode in X)
; -----------------------------------------------------------------------------
keyPressed:
        lda #1                  ; mark as pressed
        sta pressedTable,x
        jmp inputLoop

; -----------------------------------------------------------------------------
; A standard key was released ($f0 in X)
; -----------------------------------------------------------------------------
keyReleased:
        jsr kbReadByte          ; get the released key scancode
        cpx #0
        beq keyReleased

        lda #0                  ; mark as released
        sta pressedTable,x
        jmp inputLoop

; -----------------------------------------------------------------------------
; An extended key was pressed ($e0 in X)
; -----------------------------------------------------------------------------
extendedKey:
        jsr kbReadByte
        cpx #0
        beq extendedKey         ; get the scancode

        cpx #KB_RELEASE         ; is it the release code?
        beq extKeyReleased

        jmp extKeyPressed       ; extended key pressed

; -----------------------------------------------------------------------------
; An extended key was pressed (scancode in X)
; -----------------------------------------------------------------------------
extKeyPressed:
        lda #1                  ; mark as pressed
        sta extPressedTable,x
        jmp inputLoop

; -----------------------------------------------------------------------------
; An extended key was released ($f0 in X)
; -----------------------------------------------------------------------------
extKeyReleased:
        jsr kbReadByte
        cpx #0
        beq extKeyReleased      ; get the scancode

        lda #0
        sta extPressedTable,x   ; mark as released
        jmp inputLoop

; -----------------------------------------------------------------------------
; Output a sprite overlay at the key position
; -----------------------------------------------------------------------------
doShowKey:
        lda PRESSED_KEY_COUNT   ; set up sprite attribute address for writing
        jsr tmsSetSpriteTmpAddress
        jsr tmsSetAddressWrite

        tya                     ; set Y location
        clc
        adc #(Y_OFFSET*8-1)     ; add keyboard vertical offset
        +tmsPut

        txa                     ; set X location
        +tmsPut
        inc PRESSED_KEY_COUNT
        rts

; -----------------------------------------------------------------------------
; Show a standard key
; -----------------------------------------------------------------------------
showKey:
        txa
        pha

        ldy keyPosY,x           ; find key position
        lda keyPosX,x

        beq @noShow             ; 0? not a supported key

        tax                     ; add an overlay for the key
        jsr doShowKey

@noShow        
        pla
        tax
        jmp doneShowKey

; -----------------------------------------------------------------------------
; Show an extended key
; -----------------------------------------------------------------------------
showExtKey:
        txa
        pha
        ldy extKeyPosY,x        ; find key position
        lda extKeyPosX,x

        beq @noShowExt          ; 0? not a supported key
        tax

        jsr doShowKey           ; add an overlay for the key

@noShowExt        
        pla
        tax
        jmp doneShowExtKey

; -----------------------------------------------------------------------------
; Output loop (runs once for each VSYNC)
; -----------------------------------------------------------------------------
outputLoop:
        stx HBC56_TMP_X         ; keep X/Y
        sty HBC56_TMP_Y

       ; +tmsSetColorFgBg TMS_WHITE, TMS_LT_GREEN    ; keep track of vsync processing time

        lda #0                  ; clear pressed count
        sta PRESSED_KEY_COUNT

        ldx #131                ; max normal key index

-                               ; iterate over the scancode table
        lda pressedTable,x      ; if a key is pressed, show the overlay
        bne showKey
doneShowKey:
        dex
        bne -

        ldx #125                ; max ext key index

-                               ; iterate over the extended scancode table
        lda extPressedTable,x   ; if a key is pressed, show the overlay
        bne showExtKey
doneShowExtKey:
        dex
        bne -

        lda PRESSED_KEY_COUNT   ; set the next sprite Y location to $d0 (last sprite)
        jsr tmsSetSpriteTmpAddress
        jsr tmsSetAddressWrite
        lda #$d0
        +tmsPut

        ldx HBC56_TMP_X         ; restore X/Y
        ldy HBC56_TMP_Y

        lda #1                  ; set sprite visibility based on frame count
        bit HBC56_TICKS

        beq evenFrame
        jmp oddFrame

; -----------------------------------------------------------------------------
; Even frames hide overlay sprites
; -----------------------------------------------------------------------------
evenFrame:
       !for i,0,8 {
        +tmsSpriteColor i, TMS_TRANSPARENT
       }
       +tmsSetColorFgBg TMS_WHITE, TMS_DK_BLUE   ; end vsync processing time
       rts

; -----------------------------------------------------------------------------
; Odd frames show overlay sprites
; -----------------------------------------------------------------------------
oddFrame:
       !for i,0,8 {
        +tmsSpriteColor i, TMS_DK_GREEN
       }
       +tmsSetColorFgBg TMS_WHITE, TMS_DK_BLUE   ; end vsync processing time
       rts        

; -----------------------------------------------------------------------------
; Key position tables (scancode to X/Y pixel)
; -----------------------------------------------------------------------------
keyPosX:
!byte 0,135,219,79,51,23,37,177,0,149,121,93,65,13, 9,0,0, 54,19,0,  9,32,24,0,0,0,45,52,37,47,39,0,0,75,60,67,62,69,54,0,0, 97,90,82,92,77,84,0,0,120,105,112,97,107,99,0,0,0,135,127,122,114,129,0,0,150,142,137,152,159,144,0,0,165,180,157,172,167,174,0,0,0,187,0,182,189,0,0,16,199,210,197,0,215,0,0,0,0,0,0,0,0,211,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 9,0,163,0,0,0,0,0,205,0,0,0,0,107
keyPosY:
!byte 0, 25, 25,25,25,25,25, 25,0, 25, 25,25,25,56,40,0,0,104,88,0,104,56,40,0,0,0,88,72,72,56,40,0,0,88,88,72,56,40,40,0,0,104,88,72,56,56,40,0,0, 88, 88, 72,72, 56,40,0,0,0, 88, 72, 56, 40, 40,0,0, 88, 72, 56, 56, 40, 40,0,0, 88, 88, 72, 72, 56, 40,0,0,0, 72,0, 56, 40,0,0,72, 88, 72, 56,0, 56,0,0,0,0,0,0,0,0, 40,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,25,0, 25,0,0,0,0,0, 25,0,0,0,0, 25
extKeyPosX:
!byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,143,191,0,173,0,0,0,0,0,0,0,0,0,0, 24,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,158,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,233,0,203,233,0,0,0,188,233,218,0,233,218,0,0,0,0,233,0,0,233
extKeyPosY:
!byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,104, 25,0,104,0,0,0,0,0,0,0,0,0,0,104,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,104,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 88,0,104, 40,0,0,0,104, 25,104,0,104, 88,0,0,0,0, 72,0,0, 56

; -----------------------------------------------------------------------------
; Graphics data
; -----------------------------------------------------------------------------
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
!byte $07,$1F,$3F,$7F,$7F,$FF,$FF,$FF
!byte $FF,$FF,$7F,$7F,$3F,$1F,$07,$00
!byte $80,$E0,$F0,$F8,$F8,$FC,$FC,$FC
!byte $FC,$FC,$F8,$F8,$F0,$E0,$80,$00
