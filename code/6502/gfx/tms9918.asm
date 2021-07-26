; 6502 - TMS9918 VDP
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
;
; Dependencies:
;  - hbc56.asm


; -------------------------
; Constants
; -------------------------
TMS9918_IO_ADDR = $10

; IO Ports
TMS9918_RAM     = IO_PORT_BASE_ADDRESS | TMS9918_IO_ADDR
TMS9918_REG     = IO_PORT_BASE_ADDRESS | TMS9918_IO_ADDR | $01

; -----------------------------------------------------------------------------
; VRAM addresses
; -----------------------------------------------------------------------------
TMS_VRAM_BASE_ADDRESS           = $0400
TMS_VRAM_COLOR_ADDRESS          = $0200
TMS_VRAM_FONT_ADDRESS           = $0800
TMS_VRAM_SPRITE_ATTR_ADDRESS    = $0300
TMS_VRAM_SPRITE_PATT_ADDRESS    = $0000

; -----------------------------------------------------------------------------
; Register values
; -----------------------------------------------------------------------------
TMS_R0_MODE_GRAPHICS_I          = $00
TMS_R0_MODE_GRAPHICS_II         = $02
TMS_R0_MODE_MULTICOLOR          = $00
TMS_R0_MODE_TEXT                = $00
TMS_R0_EXT_VDP_ENABLE           = $01
TMS_R0_EXT_VDP_DISABLE          = $00

TMS_R1_RAM_16K                  = $80
TMS_R1_RAM_4K                   = $00
TMS_R1_DISP_BLANK               = $00
TMS_R1_DISP_ACTIVE              = $40
TMS_R1_INT_ENABLE               = $20
TMS_R1_INT_DISABLE              = $00
TMS_R1_MODE_GRAPHICS_I          = $00
TMS_R1_MODE_GRAPHICS_II         = $02
TMS_R1_MODE_MULTICOLOR          = $00
TMS_R1_MODE_TEXT                = $00
TMS_R1_SPRITE_8                 = $00
TMS_R1_SPRITE_16                = $02
TMS_R1_SPRITE_MAG1              = $00
TMS_R1_SPRITE_MAG2              = $01

; -----------------------------------------------------------------------------
; Color palette
; -----------------------------------------------------------------------------
TMS_TRANSPARENT         = $00
TMS_BLACK               = $01
TMS_MED_GREEN           = $02
TMS_LT_GREEN            = $03
TMS_DK_BLUE             = $04
TMS_LT_BLUE             = $05
TMS_DK_RED              = $06
TMS_CYAN                = $07
TMS_MED_RED             = $08
TMS_LT_RED              = $09
TMS_DK_YELLOW           = $0a
TMS_LT_YELLOW           = $0b
TMS_DK_GREEN            = $0c
TMS_MAGENTA             = $0d
TMS_GREY                = $0e
TMS_WHITE               = $0f


; -----------------------------------------------------------------------------
; Default register values
; -----------------------------------------------------------------------------
TMS_REGISTER_DATA:
!byte TMS_R0_EXT_VDP_DISABLE | TMS_R0_MODE_GRAPHICS_I
!byte TMS_R1_RAM_16K | TMS_R1_DISP_ACTIVE | TMS_R1_MODE_GRAPHICS_I
!byte TMS_VRAM_BASE_ADDRESS >> 10
!byte TMS_VRAM_COLOR_ADDRESS >> 6
!byte TMS_VRAM_FONT_ADDRESS >> 11
!byte TMS_VRAM_SPRITE_ATTR_ADDRESS >> 7
!byte TMS_VRAM_SPRITE_PATT_ADDRESS >> 11
!byte TMS_BLACK << 4 | TMS_CYAN


; -----------------------------------------------------------------------------
; tmsWait: Not sure how much delay we need (if any) so make a macro for now
; -----------------------------------------------------------------------------
!macro tmsWait {
        jsr _tmsWait
}

_tmsWait:
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        rts

; -----------------------------------------------------------------------------
; tmsSetAddress: Set an address in the TMS9918
; -----------------------------------------------------------------------------
!macro tmsSetAddress .addr {
        lda #<($4000 | .addr)
        sta TMS9918_REG
        +tmsWait
        lda #>($4000 | .addr)
        sta TMS9918_REG
        +tmsWait
}

; -----------------------------------------------------------------------------
; tmsInit: Initialise the registers
; -----------------------------------------------------------------------------
tmsInit:
        ; set up the registers
        ldx #0
-
        lda TMS_REGISTER_DATA, x
        sta TMS9918_REG
        +tmsWait
        txa
        ora #$80
        sta TMS9918_REG
        +tmsWait
        inx
        cpx #8
        bne -

        ; load all data into VRAM
        jsr tmsInitFontTable

        jsr tmsInitTextTable
        
        jsr tmsInitColorTable

        jsr tmsInitSpriteTable

        rts

; -----------------------------------------------------------------------------
; _tmsSendPage: Send A for a whole page
; -----------------------------------------------------------------------------
_tmsSendPage:
        ldx #0
-
        sta TMS9918_RAM
        +tmsWait
        inx
        bne -
        rts

; -----------------------------------------------------------------------------
; _tmsSendEmptyPage: Send an empty page of data
; -----------------------------------------------------------------------------
_tmsSendEmptyPage:
        lda #0
        beq _tmsSendPage

; -----------------------------------------------------------------------------
; tmsInitFontTable: Initialise the font table
; -----------------------------------------------------------------------------
tmsInitFontTable:

        ; font table
        +tmsSetAddress TMS_VRAM_FONT_ADDRESS

        ; (0 - 31) all empty
        jsr _tmsSendEmptyPage

        ; 32 ('!') - 63 ('?')
        ldx #0
-
        lda TMS_FONT_DATA, x
        sta TMS9918_RAM
        +tmsWait
        inx
        bne -

        ; 64 ('@') - 95 ('_')
-
        lda TMS_FONT_DATA + $100, x
        sta TMS9918_RAM
        +tmsWait
        inx
        bne -

        ; 96 ('`') - 127 ('DEL')
-
        lda TMS_FONT_DATA + $200, x
        sta TMS9918_RAM
        +tmsWait
        inx
        bne -

        ; (128 - 159) all empty
        jsr _tmsSendEmptyPage

        ; (160 - 191) all empty
        jsr _tmsSendEmptyPage

        ; (192 - 223) all empty
        jsr _tmsSendEmptyPage

        ; (224 - 255) all empty
        jsr _tmsSendEmptyPage

        rts


; -----------------------------------------------------------------------------
; tmsSetBackground: Set the backgorund color (R7)
; -----------------------------------------------------------------------------
; Outputs:
;  A: Color. High nibble = FG. Low nibble = BG
; -----------------------------------------------------------------------------
tmsSetBackground:
        pha
        sta TMS9918_REG
        +tmsWait
        lda #$87
        sta TMS9918_REG
        +tmsWait
        pla
        rts

; -----------------------------------------------------------------------------
; tmsInitTextTable: Initialise the color table
; -----------------------------------------------------------------------------
tmsInitTextTable:

        ; text table table
        +tmsSetAddress TMS_VRAM_BASE_ADDRESS

        lda #' '
        jsr _tmsSendPage

        jsr _tmsSendPage

        jsr _tmsSendPage

        rts



; -----------------------------------------------------------------------------
; +tmsColorFgBg: Set A to the given FG / BG color
; -----------------------------------------------------------------------------
!macro tmsColorFgBg .fg, .bg {
        lda #(.fg << 4 | .bg)
}


; -----------------------------------------------------------------------------
; tmsInitColorTable: Initialise the color table
; -----------------------------------------------------------------------------
tmsInitColorTable:

        ; color table
        +tmsSetAddress TMS_VRAM_COLOR_ADDRESS

        ldx #32
        +tmsColorFgBg TMS_BLACK, TMS_CYAN
-
        sta TMS9918_RAM
        +tmsWait
        dex
        bne -

        rts

; -----------------------------------------------------------------------------
; tmsInitSpriteTable: Initialise the sprite table
; -----------------------------------------------------------------------------
tmsInitSpriteTable:


        ; sprites table
        +tmsSetAddress TMS_VRAM_SPRITE_ATTR_ADDRESS

        ldx #32
-
        ; Vertical position
        lda #$D0        ; 208 ($D0) stops processing of sprites
        sta TMS9918_RAM
        +tmsWait
        ; Horizontal position
        lda #$00
        sta TMS9918_RAM
        +tmsWait
        ; Index
        sta TMS9918_RAM
        +tmsWait
        ; Early Clock / Color
        sta TMS9918_RAM
        +tmsWait
        dex
        bne -

        rts


; -----------------------------------------------------------------------------
; tmsPrint: Print immediate text
; -----------------------------------------------------------------------------
; Inputs:
;  str: String to print
;  x: x position
;  y: y position
; -----------------------------------------------------------------------------
!macro tmsPrint .str, .x, .y {
	jmp +
.textAddr
	!text .str,0
+
        +tmsSetAddress (TMS_VRAM_BASE_ADDRESS + .y * 32 + .x)

        lda #<.textAddr
        sta STR_ADDR_L
        lda #>.textAddr
        sta STR_ADDR_H
        jsr tmsPrint
}

; -----------------------------------------------------------------------------
; tmsPrint: Print a null-terminated string
; -----------------------------------------------------------------------------
; Inputs:
;  STR_ADDR: Contains address of null-terminated string
; Prerequisites:
;  TMS address already set using +tmsSetAddress
; -----------------------------------------------------------------------------
tmsPrint:
	ldy #0
-
	+tmsWait
	lda (STR_ADDR), y
	beq +
        sta TMS9918_RAM
        +tmsWait
	iny
	jmp -
+
	rts


; characters 32 - 127
TMS_FONT_DATA:
!byte $00,$00,$00,$00,$00,$00,$00,$00 ; <SPACE>
!byte $18,$3C,$3C,$18,$18,$00,$18,$00 ; !
!byte $6C,$6C,$00,$00,$00,$00,$00,$00 ; "
!byte $6C,$6C,$FE,$6C,$FE,$6C,$6C,$00 ; #
!byte $18,$3E,$60,$3C,$06,$7C,$18,$00 ; $
!byte $00,$C6,$CC,$18,$30,$66,$C6,$00 ; %
!byte $38,$6C,$68,$76,$DC,$CC,$76,$00 ; &
!byte $18,$18,$30,$00,$00,$00,$00,$00 ; '
!byte $0C,$18,$30,$30,$30,$18,$0C,$00 ; (
!byte $30,$18,$0C,$0C,$0C,$18,$30,$00 ; )
!byte $00,$66,$3C,$FF,$3C,$66,$00,$00 ; *
!byte $00,$18,$18,$7E,$18,$18,$00,$00 ; +
!byte $00,$00,$00,$00,$00,$18,$18,$30 ; ,
!byte $00,$00,$00,$7E,$00,$00,$00,$00 ; -
!byte $00,$00,$00,$00,$00,$18,$18,$00 ; .
!byte $03,$06,$0C,$18,$30,$60,$C0,$00 ; /
!byte $3C,$66,$6E,$7E,$76,$66,$3C,$00 ; 0
!byte $18,$38,$18,$18,$18,$18,$7E,$00 ; 1
!byte $3C,$66,$06,$1C,$30,$66,$7E,$00 ; 2
!byte $3C,$66,$06,$1C,$06,$66,$3C,$00 ; 3
!byte $1C,$3C,$6C,$CC,$FE,$0C,$1E,$00 ; 4
!byte $7E,$60,$7C,$06,$06,$66,$3C,$00 ; 5
!byte $1C,$30,$60,$7C,$66,$66,$3C,$00 ; 6
!byte $7E,$66,$06,$0C,$18,$18,$18,$00 ; 7
!byte $3C,$66,$66,$3C,$66,$66,$3C,$00 ; 8
!byte $3C,$66,$66,$3E,$06,$0C,$38,$00 ; 9
!byte $00,$18,$18,$00,$00,$18,$18,$00 ; :
!byte $00,$18,$18,$00,$00,$18,$18,$30 ; ;
!byte $0C,$18,$30,$60,$30,$18,$0C,$00 ; <
!byte $00,$00,$7E,$00,$00,$7E,$00,$00 ; =
!byte $30,$18,$0C,$06,$0C,$18,$30,$00 ; >
!byte $3C,$66,$06,$0C,$18,$00,$18,$00 ; ?
!byte $7C,$C6,$DE,$DE,$DE,$C0,$78,$00 ; @
!byte $18,$3C,$3C,$66,$7E,$C3,$C3,$00 ; A
!byte $FC,$66,$66,$7C,$66,$66,$FC,$00 ; B
!byte $3C,$66,$C0,$C0,$C0,$66,$3C,$00 ; C
!byte $F8,$6C,$66,$66,$66,$6C,$F8,$00 ; D
!byte $FE,$66,$60,$78,$60,$66,$FE,$00 ; E
!byte $FE,$66,$60,$78,$60,$60,$F0,$00 ; F
!byte $3C,$66,$C0,$CE,$C6,$66,$3E,$00 ; G
!byte $66,$66,$66,$7E,$66,$66,$66,$00 ; H
!byte $7E,$18,$18,$18,$18,$18,$7E,$00 ; I
!byte $0E,$06,$06,$06,$66,$66,$3C,$00 ; J
!byte $E6,$66,$6C,$78,$6C,$66,$E6,$00 ; K
!byte $F0,$60,$60,$60,$62,$66,$FE,$00 ; L
!byte $82,$C6,$EE,$FE,$D6,$C6,$C6,$00 ; M
!byte $C6,$E6,$F6,$DE,$CE,$C6,$C6,$00 ; N
!byte $38,$6C,$C6,$C6,$C6,$6C,$38,$00 ; O
!byte $FC,$66,$66,$7C,$60,$60,$F0,$00 ; P
!byte $38,$6C,$C6,$C6,$C6,$6C,$3C,$06 ; Q
!byte $FC,$66,$66,$7C,$6C,$66,$E3,$00 ; R
!byte $3C,$66,$70,$38,$0E,$66,$3C,$00 ; S
!byte $7E,$5A,$18,$18,$18,$18,$3C,$00 ; T
!byte $66,$66,$66,$66,$66,$66,$3E,$00 ; U
!byte $C3,$C3,$66,$66,$3C,$3C,$18,$00 ; V
!byte $C6,$C6,$C6,$D6,$FE,$EE,$C6,$00 ; W
!byte $C3,$66,$3C,$18,$3C,$66,$C3,$00 ; X
!byte $C3,$C3,$66,$3C,$18,$18,$3C,$00 ; Y
!byte $FE,$C6,$8C,$18,$32,$66,$FE,$00 ; Z
!byte $3C,$30,$30,$30,$30,$30,$3C,$00 ; [
!byte $C0,$60,$30,$18,$0C,$06,$03,$00 ; \
!byte $3C,$0C,$0C,$0C,$0C,$0C,$3C,$00 ; ]
!byte $10,$38,$6C,$C6,$00,$00,$00,$00 ; ^
!byte $00,$00,$00,$00,$00,$00,$00,$FE ; _
!byte $18,$18,$0C,$00,$00,$00,$00,$00 ; `
!byte $00,$00,$3C,$06,$1E,$66,$3B,$00 ; a
!byte $E0,$60,$6C,$76,$66,$66,$3C,$00 ; b
!byte $00,$00,$3C,$66,$60,$66,$3C,$00 ; c
!byte $0E,$06,$36,$6E,$66,$66,$3B,$00 ; d
!byte $00,$00,$3C,$66,$7E,$60,$3C,$00 ; e
!byte $1C,$36,$30,$78,$30,$30,$78,$00 ; f
!byte $00,$00,$3B,$66,$66,$3C,$C6,$7C ; g
!byte $E0,$60,$6C,$76,$66,$66,$E6,$00 ; h
!byte $18,$00,$38,$18,$18,$18,$3C,$00 ; i
!byte $06,$00,$06,$06,$06,$06,$66,$3C ; j
!byte $E0,$60,$66,$6C,$78,$6C,$E6,$00 ; k
!byte $38,$18,$18,$18,$18,$18,$3C,$00 ; l
!byte $00,$00,$66,$77,$6B,$63,$63,$00 ; m
!byte $00,$00,$7C,$66,$66,$66,$66,$00 ; n
!byte $00,$00,$3C,$66,$66,$66,$3C,$00 ; o
!byte $00,$00,$DC,$66,$66,$7C,$60,$F0 ; p
!byte $00,$00,$3D,$66,$66,$3E,$06,$07 ; q
!byte $00,$00,$EC,$76,$66,$60,$F0,$00 ; r
!byte $00,$00,$3E,$60,$3C,$06,$7C,$00 ; s
!byte $10,$30,$7C,$30,$30,$34,$18,$00 ; t
!byte $00,$00,$CC,$CC,$CC,$CC,$76,$00 ; u
!byte $00,$00,$CC,$CC,$CC,$78,$30,$00 ; v
!byte $00,$00,$C6,$D6,$D6,$6C,$6C,$00 ; w
!byte $00,$00,$63,$36,$1C,$36,$63,$00 ; x
!byte $00,$00,$66,$66,$66,$3C,$18,$70 ; y
!byte $00,$00,$7E,$4C,$18,$32,$7E,$00 ; z
!byte $0E,$18,$18,$70,$18,$18,$0E,$00 ; {
!byte $18,$18,$18,$18,$18,$18,$18,$00 ; |
!byte $70,$18,$18,$0E,$18,$18,$70,$00 ; }
!byte $72,$9C,$00,$00,$00,$00,$00,$00 ; ~
!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;  
