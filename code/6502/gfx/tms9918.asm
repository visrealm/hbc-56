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
!byte TMS_R1_RAM_16K | TMS_R1_DISP_ACTIVE | TMS_R1_MODE_GRAPHICS_I | TMS_R1_SPRITE_MAG2
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
; tmsCreateSpritePattern: Create a sprite pattern (.spriteDataAddr is 8 bytes)
; -----------------------------------------------------------------------------
!macro tmsCreateSpritePattern .pattInd, .spriteDataAddr {

        ; sprite pattern table
        +tmsSetAddress TMS_VRAM_SPRITE_PATT_ADDRESS + .pattInd * 8

        ldx #0
-
        lda .spriteDataAddr,x
        sta TMS9918_RAM
        +tmsWait
        inx
        cpx #8
        bne -
}

; -----------------------------------------------------------------------------
; tmsCreateSprite: Create a sprite
; -----------------------------------------------------------------------------
!macro tmsCreateSprite .ind, .pattInd, .xPos, .yPos, .color {

        ; sprite attr table
        +tmsSetAddress TMS_VRAM_SPRITE_ATTR_ADDRESS + .ind * 4

        lda #.yPos
        sta TMS9918_RAM
        +tmsWait
        lda #.xPos
        sta TMS9918_RAM
        +tmsWait
        lda #.pattInd
        sta TMS9918_RAM
        +tmsWait
        lda #.color
        sta TMS9918_RAM
        +tmsWait
}

; -----------------------------------------------------------------------------
; tmsSpritePos: Set a sprite position
; -----------------------------------------------------------------------------
!macro tmsSpritePos .ind, .xPos, .yPos {

        ; sprite attr table
        +tmsSetAddress TMS_VRAM_SPRITE_ATTR_ADDRESS + .ind * 4

        lda #.yPos
        sta TMS9918_RAM
        +tmsWait
        lda #.xPos
        sta TMS9918_RAM
        +tmsWait
}


; -----------------------------------------------------------------------------
; tmsSpriteColor: Change a sprite color
; -----------------------------------------------------------------------------
!macro tmsSpriteColor .ind, .color {

        ; sprite attr table
        +tmsSetAddress TMS_VRAM_SPRITE_ATTR_ADDRESS + (.ind * 4) + 3

        lda #.color
        sta TMS9918_RAM
        +tmsWait
}


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
