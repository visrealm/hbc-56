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
TMS9918_REG0_SHADOW_ADDR = $210
TMS9918_REG1_SHADOW_ADDR = $211

; IO Ports
TMS9918_RAM     = IO_PORT_BASE_ADDRESS | TMS9918_IO_ADDR
TMS9918_REG     = IO_PORT_BASE_ADDRESS | TMS9918_IO_ADDR | $01

; -----------------------------------------------------------------------------
; Zero page
; -----------------------------------------------------------------------------
TMS_TMP_ADDRESS = R10

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


!ifndef TMS_MODEL {
	!warn "Set TMS_MODEL to one of: 9918, 9929. Defaulting to 9918"
	TMS_MODEL = 9918
} 

; -------------------------
; Constants
; -------------------------

!if TMS_MODEL = 9918 {
	TMS_FPS = 60
} else { !if TMS_MODEL = 9929 {
	TMS_FPS = 50
} else {
	!error "Unknown TMS_MODEL. Must be one of: 9918 or 9929"
}}

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
; tmsSetAddress: Set an address in the TMS9918 
; -----------------------------------------------------------------------------
; TMS_TMP_ADDRESS: Address to set
; -----------------------------------------------------------------------------
tmsSetAddress:
        lda TMS_TMP_ADDRESS
        sta TMS9918_REG
        +tmsWait
        lda TMS_TMP_ADDRESS + 1
        sta TMS9918_REG
        +tmsWait
        rts

; -----------------------------------------------------------------------------
; tmsPut: Send a byte of data to the TMS9918
; -----------------------------------------------------------------------------
!macro tmsPut .byte {
        lda #.byte
        sta TMS9918_RAM
        +tmsWait
}

; -----------------------------------------------------------------------------
; tmsPut: Send a byte of data to the TMS9918
; -----------------------------------------------------------------------------
!macro tmsSetColor .color {
        lda #.color
        jsr tmsSetBackground
}

; -----------------------------------------------------------------------------
; tmsSetRegister: Set a register value
; -----------------------------------------------------------------------------
; Inputs:
;  A: The value to set
;  X: The register (0 - 7)
; -----------------------------------------------------------------------------
tmsSetRegister:
        sei
        pha
        sta TMS9918_REG
        +tmsWait
        txa
        ora #$80
        sta TMS9918_REG
        +tmsWait
        pla
        cli
        rts

; -----------------------------------------------------------------------------
; tmsSetBackground: Set the background color (R7)
; -----------------------------------------------------------------------------
; Outputs:
;  A: Color. High nibble = FG. Low nibble = BG
; -----------------------------------------------------------------------------
tmsSetBackground:
        ldx #7
        bne tmsSetRegister

; -----------------------------------------------------------------------------
; tmsReg0Set: Set register 0
; -----------------------------------------------------------------------------
; Outputs:
;  A: Field values to set (will be OR'd with existing Reg0)
; -----------------------------------------------------------------------------
tmsReg0SetFields:
        ora TMS9918_REG0_SHADOW_ADDR
        sta TMS9918_REG0_SHADOW_ADDR
        ldx #0
        beq tmsSetRegister
        
; -----------------------------------------------------------------------------
; tmsReg0Clear: Clear register 0 
; -----------------------------------------------------------------------------
; Outputs:
;  A: Field values to cleared (will be XOR'd with existing Reg0)
; -----------------------------------------------------------------------------
tmsReg0ClearFields:
        eor #$ff
        and TMS9918_REG0_SHADOW_ADDR
        sta TMS9918_REG0_SHADOW_ADDR
        ldx #0
        beq tmsSetRegister


; -----------------------------------------------------------------------------
; tmsReg1Set: Set register 0
; -----------------------------------------------------------------------------
; Outputs:
;  A: Field values to set (will be OR'd with existing Reg1)
; -----------------------------------------------------------------------------
tmsReg1SetFields:
        ora TMS9918_REG1_SHADOW_ADDR
        sta TMS9918_REG1_SHADOW_ADDR
        ldx #1
        bne tmsSetRegister
        
; -----------------------------------------------------------------------------
; tmsReg1Clear: Clear register 1
; -----------------------------------------------------------------------------
; Outputs:
;  A: Field values to cleared (will be XOR'd with existing Reg1)
; -----------------------------------------------------------------------------
tmsReg1ClearFields:
        eor #$ff
        and TMS9918_REG1_SHADOW_ADDR
        sta TMS9918_REG1_SHADOW_ADDR
        ldx #1
        bne tmsSetRegister

!macro tmsEnableInterrupts {
        lda #TMS_R1_INT_ENABLE
        jsr tmsReg1SetFields
}

!macro tmsDisableInterrupts {
        lda #TMS_R1_INT_ENABLE
        jsr tmsReg1ClearFields
}


; -----------------------------------------------------------------------------
; tmsInit: Initialise the registers
; -----------------------------------------------------------------------------
tmsInit:
        sei

        lda TMS_REGISTER_DATA
        sta TMS9918_REG0_SHADOW_ADDR
        lda TMS_REGISTER_DATA + 1
        sta TMS9918_REG1_SHADOW_ADDR

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
        cli

        ; load all data into VRAM
        jsr tmsInitFontTable

        jsr tmsInitTextTable
        
        jsr tmsInitColorTable

        jsr tmsInitSpriteTable

        rts


; -----------------------------------------------------------------------------
; tmsSetAddress: Set an address in the TMS9918
; -----------------------------------------------------------------------------
!macro tmsReadStatus  {
        lda TMS9918_REG
}

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

!macro tmsSendData .sourceAddr, .numBytes {
        lda #<.sourceAddr
        sta TMS_TMP_ADDRESS
        lda #>.sourceAddr
        sta TMS_TMP_ADDRESS + 1

!if .numBytes < 256 {
        ldx #.numBytes
        jsr tmsSendBytes
} else {
        !do while .numBytes > 0 {
                !if .numBytes > 255 {
                        ldx #0
                        !set .numBytes = .numBytes - 256
                } else {
                        ldx #.numBytes
                        !set .numBytes = 0
                }
                jsr tmsSendBytes
                inc TMS_TMP_ADDRESS + 1
        }
}

}

; -----------------------------------------------------------------------------
; tmsSendBytes: Send bytes to the TMS (up to 1 page)
; -----------------------------------------------------------------------------
; Inputs:
;   TMS_TMP_ADDRESS:    Holds source address
;   X:                  Number of bytes (1 to 256)
; -----------------------------------------------------------------------------
tmsSendBytes:
        ldy #0
-
        lda (TMS_TMP_ADDRESS), Y
        sta TMS9918_RAM
        +tmsWait
        iny
        dex
        bne -
        rts

; -----------------------------------------------------------------------------
; tmsSetAddrFontTable: Initialise address for font table
; -----------------------------------------------------------------------------
!macro tmsSetAddrFontTable {
        +tmsSetAddrFontTableInd 0
}

; -----------------------------------------------------------------------------
; tmsSetAddrFontTable: Initialise address for font table
; -----------------------------------------------------------------------------
!macro tmsSetAddrFontTableInd .ind {
        +tmsSetAddress TMS_VRAM_FONT_ADDRESS + 8 * .ind
}


; -----------------------------------------------------------------------------
; tmsInitFontTable: Initialise the font table
; -----------------------------------------------------------------------------
tmsInitFontTable:
        sei

        ; font table
        +tmsSetAddrFontTable

        ; (0 - 31) all empty
        jsr _tmsSendEmptyPage

        +tmsSendData TMS_FONT_DATA, $300

        ; (128 - 159) all empty
        jsr _tmsSendEmptyPage

        ; (160 - 191) all empty
        jsr _tmsSendEmptyPage

        ; (192 - 223) all empty
        jsr _tmsSendEmptyPage

        ; (224 - 255) all empty
        jsr _tmsSendEmptyPage

        cli

        rts


; -----------------------------------------------------------------------------
; tmsSetAddrBase: Initialise address for base (text) table
; -----------------------------------------------------------------------------
!macro tmsSetAddrBase {
        +tmsSetAddress TMS_VRAM_BASE_ADDRESS
}

; -----------------------------------------------------------------------------
; tmsInitTextTable: Initialise the color table
; -----------------------------------------------------------------------------
tmsInitTextTable:
        sei

        ; text table table
        +tmsSetAddrBase


        lda #' '
        jsr _tmsSendPage

        jsr _tmsSendPage

        jsr _tmsSendPage

        cli

        rts



; -----------------------------------------------------------------------------
; +tmsColorFgBg: Set A to the given FG / BG color
; -----------------------------------------------------------------------------
!macro tmsColorFgBg .fg, .bg {
        lda #(.fg << 4 | .bg)
}

; -----------------------------------------------------------------------------
; tmsSetAddrColorTable: Initialise address for color table
; -----------------------------------------------------------------------------
!macro tmsSetAddrColorTable {
        +tmsSetAddress TMS_VRAM_COLOR_ADDRESS
}
; -----------------------------------------------------------------------------
; tmsInitColorTable: Initialise the color table
; -----------------------------------------------------------------------------
tmsInitColorTable:
        sei

        ; color table
        +tmsSetAddrColorTable

        ldx #32
        +tmsColorFgBg TMS_BLACK, TMS_CYAN
-
        sta TMS9918_RAM
        +tmsWait
        dex
        bne -

        cli

        rts

; -----------------------------------------------------------------------------
; tmsSetAddrSpriteAttrTable: Initialise address for sprite attributes table
; -----------------------------------------------------------------------------
!macro tmsSetAddrSpriteAttrTable {
        +tmsSetAddrSpriteAttrTableInd 0
}

; -----------------------------------------------------------------------------
; tmsSetAddrSpriteAttrTableInd: Initialise address for sprite attributes table
; -----------------------------------------------------------------------------
!macro tmsSetAddrSpriteAttrTableInd .index {
        +tmsSetAddress TMS_VRAM_SPRITE_ATTR_ADDRESS + .index * 4
}

; -----------------------------------------------------------------------------
; tmsInitSpriteTable: Initialise the sprite table
; -----------------------------------------------------------------------------
tmsInitSpriteTable:
        sei

        ; sprites table
        +tmsSetAddrSpriteAttrTable

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

        cli

        rts

; -----------------------------------------------------------------------------
; tmsSetAddrSpritePattTable: Initialise address for sprite pattern table
; -----------------------------------------------------------------------------
!macro tmsSetAddrSpritePattTable {
        +tmsSetAddrSpritePattTableInd 0
}

; -----------------------------------------------------------------------------
; tmsSetAddrSpritePattTableInd: Initialise address for sprite pattern table
; -----------------------------------------------------------------------------
!macro tmsSetAddrSpritePattTableInd .index {
        +tmsSetAddress TMS_VRAM_SPRITE_PATT_ADDRESS + .index * 8
}


; -----------------------------------------------------------------------------
; tmsCreateSpritePattern: Create a sprite pattern (.spriteDataAddr is 8 bytes)
; -----------------------------------------------------------------------------
!macro tmsCreateSpritePattern .pattInd, .spriteDataAddr {

        sei

        ; sprite pattern table
        +tmsSetAddrSpritePattTableInd .pattInd

        ldx #0
-
        lda .spriteDataAddr,x
        sta TMS9918_RAM
        +tmsWait
        inx
        cpx #8

        cli

        bne -
}

; -----------------------------------------------------------------------------
; tmsCreateSprite: Create a sprite
; -----------------------------------------------------------------------------
!macro tmsCreateSprite .ind, .pattInd, .xPos, .yPos, .color {

        sei

        ; sprite attr table
        +tmsSetAddrSpriteAttrTableInd .ind

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

        cli
}

; -----------------------------------------------------------------------------
; tmsSpritePos: Set a sprite position
; -----------------------------------------------------------------------------
!macro tmsSpritePos .ind, .xPos, .yPos {
        sei

        ; sprite attr table
        +tmsSetAddrSpriteAttrTableInd .ind

        lda #.yPos
        sta TMS9918_RAM
        +tmsWait
        lda #.xPos
        sta TMS9918_RAM
        +tmsWait

        cli
}

; -----------------------------------------------------------------------------
; tmsSpritePosXYReg: Set a sprite position from x/y registers
; -----------------------------------------------------------------------------
!macro tmsSpritePosXYReg .ind {
        sei

        ; sprite attr table
        +tmsSetAddrSpriteAttrTableInd .ind

        tya
        sta TMS9918_RAM
        +tmsWait
        txa
        sta TMS9918_RAM
        +tmsWait

        cli
}

; -----------------------------------------------------------------------------
; tmsSpriteColor: Change a sprite color
; -----------------------------------------------------------------------------
!macro tmsSpriteColor .ind, .color {

        sei

        ; sprite attr table
        +tmsSetAddress TMS_VRAM_SPRITE_ATTR_ADDRESS + (.ind * 4) + 3

        lda #.color
        sta TMS9918_RAM
        +tmsWait

        cli
}


; -----------------------------------------------------------------------------
; tmsHex8: Output an 8-bit byte as hexadecimal
; -----------------------------------------------------------------------------
; Inputs:
;  A: The value to output
; -----------------------------------------------------------------------------
tmsHex8:
        sei
	pha
	lsr
	lsr
	lsr
	lsr
	tax
	lda .H2, x
        sta TMS9918_RAM
        +tmsWait
	pla
	pha
	and #$0f
	tax
	lda .H2, x
        sta TMS9918_RAM
        +tmsWait
	pla
        cli
	rts

.H2 !text "0123456789abcdef"


; -----------------------------------------------------------------------------
; tmsSetPos: Set cursor position
; -----------------------------------------------------------------------------
!macro tmsSetPos .x, .y {
        +tmsSetAddress (TMS_VRAM_BASE_ADDRESS + .y * 32 + .x)
}


; -----------------------------------------------------------------------------
; tmsSetPos: Set cursor position
; -----------------------------------------------------------------------------
; Inputs:
;   X: X position (0 - 31)
;   Y: Y position (0 - 23)
; -----------------------------------------------------------------------------
tmsSetPos:
        lda #>TMS_VRAM_BASE_ADDRESS
        sta TMS_TMP_ADDRESS + 1
        
        ; this can be better. rotate and save, perhaps

        tya
        lsr
        lsr
        lsr
        clc
        adc TMS_TMP_ADDRESS + 1
        sta TMS_TMP_ADDRESS + 1
        tya
        and #$07
        asl
        asl
        asl
        asl
        asl
        sta TMS_TMP_ADDRESS
        txa
        ora TMS_TMP_ADDRESS
        sta TMS_TMP_ADDRESS
        jmp tmsSetAddress



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
        sei

        +tmsSetPos .x, .y

        lda #<.textAddr
        sta STR_ADDR_L
        lda #>.textAddr
        sta STR_ADDR_H
        jsr tmsPrint
        cli
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
