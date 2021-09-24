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
TMS_VRAM_NAME_ADDRESS           = $3800
TMS_VRAM_COLOR_ADDRESS          = $0000
TMS_VRAM_PATT_ADDRESS           = $2000
TMS_VRAM_SPRITE_ATTR_ADDRESS    = $3B00
TMS_VRAM_SPRITE_PATT_ADDRESS    = $1800

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
TMS_R1_MODE_GRAPHICS_II         = $00
TMS_R1_MODE_MULTICOLOR          = $08
TMS_R1_MODE_TEXT                = $10
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

TMS_GFX_TILE_WIDTH      = 8
TMS_GFX_TILE_HEIGHT     = 8
TMS_GFX_TILES_X         = 32
TMS_GFX_TILES_Y         = 24
TMS_GFX_PIXELS_X        = TMS_GFX_TILES_X * TMS_GFX_TILE_WIDTH
TMS_GFX_PIXELS_Y        = TMS_GFX_TILES_Y * TMS_GFX_TILE_HEIGHT

TMS_TXT_TILE_WIDTH      = 6
TMS_TXT_TILE_HEIGHT     = 8
TMS_TXT_TILES_X         = 40
TMS_TXT_TILES_Y         = 24
TMS_TXT_PIXELS_X        = TMS_TXT_TILES_X * TMS_TXT_TILE_WIDTH
TMS_TXT_PIXELS_Y        = TMS_TXT_TILES_Y * TMS_TXT_TILE_HEIGHT

TMS_SPRITE_SIZE         = 8
TMS_SPRITE_SIZE2X       = TMS_SPRITE_SIZE * 2

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
!byte TMS_VRAM_NAME_ADDRESS >> 10
!byte TMS_VRAM_COLOR_ADDRESS >> 6
!byte TMS_VRAM_PATT_ADDRESS >> 11
!byte TMS_VRAM_SPRITE_ATTR_ADDRESS >> 7
!byte TMS_VRAM_SPRITE_PATT_ADDRESS >> 11
!byte TMS_BLACK << 4 | TMS_CYAN


; -----------------------------------------------------------------------------
; tmsWaitReg: Not sure how much delay we need so make a macro for now
; -----------------------------------------------------------------------------
!macro tmsWaitReg {
        jsr _tmsWaitReg
}

; -----------------------------------------------------------------------------
; tmsWaitData: Not sure how much delay we need so make a macro for now
; -----------------------------------------------------------------------------
!macro tmsWaitData {
        jsr _tmsWaitData
}

_tmsWaitData:
        nop
        nop
        nop
        nop
        nop
_tmsWaitReg:
        nop
        nop
        nop
        rts

; -----------------------------------------------------------------------------
; tmsSetAddressWrite: Set an address in the TMS9918
; -----------------------------------------------------------------------------
!macro tmsSetAddressWrite .addr {
        +tmsSetAddressRead ($4000 | .addr)
}

; -----------------------------------------------------------------------------
; tmsSetAddressRead: Set an address to read from the TMS9918
; -----------------------------------------------------------------------------
!macro tmsSetAddressRead .addr {
        lda #<(.addr)
        sta TMS9918_REG
        +tmsWaitReg
        lda #>(.addr)
        sta TMS9918_REG
        +tmsWaitReg
}


; -----------------------------------------------------------------------------
; tmsSetAddressWrite: Set an address in the TMS9918 
; -----------------------------------------------------------------------------
; TMS_TMP_ADDRESS: Address to set
; -----------------------------------------------------------------------------
tmsSetAddressWrite:
        lda TMS_TMP_ADDRESS
        sta TMS9918_REG
        +tmsWaitReg
        lda TMS_TMP_ADDRESS + 1
        ora #$40
        sta TMS9918_REG
        +tmsWaitReg
        rts

; -----------------------------------------------------------------------------
; tmsSetAddressRead: Set an address to read from the TMS9918 
; -----------------------------------------------------------------------------
; TMS_TMP_ADDRESS: Address to read
; -----------------------------------------------------------------------------
tmsSetAddressRead:
        lda TMS_TMP_ADDRESS
        sta TMS9918_REG
        +tmsWaitReg
        lda TMS_TMP_ADDRESS + 1
        sta TMS9918_REG
        +tmsWaitReg
        rts

; -----------------------------------------------------------------------------
; tmsGet: Get a byte of data from the TMS9918
; -----------------------------------------------------------------------------
!macro tmsGet {
        lda TMS9918_RAM
        +tmsWaitData
}

; -----------------------------------------------------------------------------
; tmsPut: Send a byte of data to the TMS9918
; -----------------------------------------------------------------------------
!macro tmsPut .byte {
        lda #.byte
        +tmsPut
}


; -----------------------------------------------------------------------------
; tmsPut: Send a byte (A) of data to the TMS9918
; -----------------------------------------------------------------------------
!macro tmsPut {
        sta TMS9918_RAM
        +tmsWaitData
}

; -----------------------------------------------------------------------------
; tmsSetColor: Set current fg/bg color
; -----------------------------------------------------------------------------
!macro tmsSetColor .color {
        lda #.color
        jsr tmsSetBackground
}

; -----------------------------------------------------------------------------
; tmSetGraphicsMode2: Put the TMS9918 in Graphics II mode
; -----------------------------------------------------------------------------
!macro tmSetGraphicsMode2 {

        ; Set up R0/R1 for mode 2
        lda #TMS_R0_MODE_GRAPHICS_II
        jsr tmsReg0SetFields

        lda #TMS_R1_MODE_GRAPHICS_II
        jsr tmsReg1SetFields

        ; Update color table to upper 8KB
        lda #$7f
        ldx #3
        jsr tmsSetRegister

        ; Update pattern table to lower 8KB
        lda #$07
        ldx #4
        jsr tmsSetRegister        
}

; -----------------------------------------------------------------------------
; tmsDisableOutput: Disable the TMS9918 output
; -----------------------------------------------------------------------------
!macro tmsDisableOutput {
        lda #TMS_R1_DISP_ACTIVE
        jsr tmsReg1ClearFields
}

; -----------------------------------------------------------------------------
; tmsEnableOutput: Enable the TMS9918 output
; -----------------------------------------------------------------------------
!macro tmsEnableOutput {
        lda #TMS_R1_DISP_ACTIVE
        jsr tmsReg1SetFields
}

; -----------------------------------------------------------------------------
; tmsSetRegister: Set a register value
; -----------------------------------------------------------------------------
; Inputs:
;  A: The value to set
;  X: The register (0 - 7)
; -----------------------------------------------------------------------------
tmsSetRegister:
        sta R2
        sta TMS9918_REG
        +tmsWaitReg
        txa
        ora #$80
        sta TMS9918_REG
        +tmsWaitReg
        lda R2
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
; +tmsColorFgBg: Set A to the given FG / BG color
; -----------------------------------------------------------------------------
!macro tmsColorFgBg .fg, .bg {
        lda #(.fg << 4 | .bg)
}

; -----------------------------------------------------------------------------
; tmsInit: Initialise the registers
; -----------------------------------------------------------------------------
tmsInit:
        lda TMS_REGISTER_DATA
        sta TMS9918_REG0_SHADOW_ADDR
        lda TMS_REGISTER_DATA + 1
        sta TMS9918_REG1_SHADOW_ADDR

        ; set up the registers
        ldx #0
-
        lda TMS_REGISTER_DATA, x
        sta TMS9918_REG
        +tmsWaitReg
        txa
        ora #$80
        sta TMS9918_REG
        +tmsWaitReg
        inx
        cpx #8
        bne -
        

        ; load all data into VRAM
        jsr tmsInitPattTable

        jsr tmsInitTextTable
        
        +tmsColorFgBg TMS_BLACK, TMS_CYAN
        jsr tmsInitEntireColorTable

        jsr tmsInitSpriteTable

        rts


; -----------------------------------------------------------------------------
; tmsSetAddressWrite: Set an address in the TMS9918
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
        +tmsPut
        inx
        +tmsPut
        inx
        +tmsPut
        inx
        +tmsPut
        inx
        +tmsPut
        inx
        +tmsPut
        inx
        +tmsPut
        inx
        +tmsPut
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

!macro tmsSetSourceAddressInd .addr {
	lda .addr
	sta TMS_TMP_ADDRESS
	lda .addr + 1
	sta TMS_TMP_ADDRESS + 1
}

!macro tmsSetSourceAddressIndOffset .addr, .offset {
        clc
	lda .addr
        adc #<.offset
	sta TMS_TMP_ADDRESS
	lda .addr + 1
        adc #>.offset
	sta TMS_TMP_ADDRESS + 1
}


!macro tmsSendBytes .bytes {
        ldx #.bytes
        jsr tmsSendBytes
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
        +tmsPut
        iny
        dex
        bne -
        rts

; -----------------------------------------------------------------------------
; tmsSetAddrPattTable: Initialise address for font table
; -----------------------------------------------------------------------------
!macro tmsSetAddrPattTable {
        +tmsSetAddrPattTableInd 0
}

; -----------------------------------------------------------------------------
; tmsSetAddrPattTableInd: Initialise address for pattern table
; -----------------------------------------------------------------------------
!macro tmsSetAddrPattTableInd .ind {
        +tmsSetAddressWrite TMS_VRAM_PATT_ADDRESS + (8 * .ind)
}

; -----------------------------------------------------------------------------
; tmsSetAddrPattTableIndRead: Initialise address for pattern table to read
; -----------------------------------------------------------------------------
!macro tmsSetAddrPattTableIndRead .ind {
        +tmsSetAddressRead TMS_VRAM_PATT_ADDRESS + (8 * .ind)
}

; -----------------------------------------------------------------------------
; tmsSetAddrPattTableIndRowRead: Initialise address for pattern table to read
; -----------------------------------------------------------------------------
!macro tmsSetAddrPattTableIndRead .ind, .row {
        +tmsSetAddressRead TMS_VRAM_PATT_ADDRESS + (8 * .ind) + .row
}


; -----------------------------------------------------------------------------
; tmsInitPattTable: Initialise the pattern table
; -----------------------------------------------------------------------------
tmsInitPattTable:
        

        ; pattern table
        +tmsSetAddrPattTable

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

        

        rts


; -----------------------------------------------------------------------------
; tmsSetAddrNameTable: Initialise address for base (text) table
; -----------------------------------------------------------------------------
!macro tmsSetAddrNameTable {
        +tmsSetAddressWrite TMS_VRAM_NAME_ADDRESS
}

; -----------------------------------------------------------------------------
; tmsInitTextTable: Initialise the text (tilemap) table
; -----------------------------------------------------------------------------
tmsInitTextTable:
        

        ; text table table
        +tmsSetAddrNameTable


        lda #0
        jsr _tmsSendPage

        jsr _tmsSendPage

        jsr _tmsSendPage

        

        rts


; -----------------------------------------------------------------------------
; tmsSetAddrColorTable: Initialise address for color table
; -----------------------------------------------------------------------------
!macro tmsSetAddrColorTable {
        +tmsSetAddressWrite TMS_VRAM_COLOR_ADDRESS
}

; -----------------------------------------------------------------------------
; tmsSetAddrColorTable: Initialise address for color table index
; -----------------------------------------------------------------------------
!macro tmsSetAddrColorTable .ind {
        +tmsSetAddressWrite TMS_VRAM_COLOR_ADDRESS + .ind
}


; -----------------------------------------------------------------------------
; tmsInitEntireColorTable: Initialise the full color table
; -----------------------------------------------------------------------------
; Inputs:
;   A: Color (fg/bg) to initialise

tmsInitEntireColorTable:
        ldx #32

; tmsInitColorTable: Initialise the color table

; Inputs:
;   A: Color (fg/bg) to initialise
;   X: Number of elements to initialise (1 to 32)
; -----------------------------------------------------------------------------
tmsInitColorTable:
        
        sta R0

        ; color table
        +tmsSetAddrColorTable

        lda R0
-
        +tmsPut
        dex
        bne -

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
        +tmsSetAddressWrite TMS_VRAM_SPRITE_ATTR_ADDRESS + .index * 4
}

; -----------------------------------------------------------------------------
; tmsInitSpriteTable: Initialise the sprite table
; -----------------------------------------------------------------------------
tmsInitSpriteTable:
        

        ; sprites table
        +tmsSetAddrSpriteAttrTable

        ldx #32
-
        ; Vertical position
        +tmsPut $D0        ; 208 ($D0) stops processing of sprites
        +tmsPut $00        ; Horizontal position

        ; Index (A still 0)
        +tmsPut
        ; Early Clock / Color  (A still 0)
        +tmsPut
        dex
        bne -

        

        rts

; -----------------------------------------------------------------------------
; tmsTileXyAtPixelXy: Return tile position at pixel position
; -----------------------------------------------------------------------------
; Inputs:
;  X: Pixel position X
;  Y: Pixel position Y
; Outputs:
;  X: Tile position X
;  Y: Tile position Y
; -----------------------------------------------------------------------------
tmsTileXyAtPixelXy:
        sta R2
        txa
        +div8
        tax

        tya
        +div8
        tay
        lda R2
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
        +tmsSetAddressWrite TMS_VRAM_SPRITE_PATT_ADDRESS + .index * 8
}


; -----------------------------------------------------------------------------
; tmsCreateSpritePattern: Create a sprite pattern (.spriteDataAddr is 8 bytes)
; -----------------------------------------------------------------------------
!macro tmsCreateSpritePattern .pattInd, .spriteDataAddr {

        

        ; sprite pattern table
        +tmsSetAddrSpritePattTableInd .pattInd

        ldx #0
-
        lda .spriteDataAddr,x
        +tmsPut
        inx
        cpx #8

        

        bne -
}

; -----------------------------------------------------------------------------
; tmsCreateSpritePatternQuad: Create a (size 1) sprite pattern 
;   (.spriteDataAddr is 32 bytes)
; -----------------------------------------------------------------------------
!macro tmsCreateSpritePatternQuad .pattInd, .spriteDataAddr {

        

        ; sprite pattern table
        +tmsSetAddrSpritePattTableInd .pattInd * 4

        ldx #0
-
        lda .spriteDataAddr,x
        +tmsPut 
        inx
        cpx #32

        

        bne -
}


; -----------------------------------------------------------------------------
; tmsCreateSprite: Create a sprite
; -----------------------------------------------------------------------------
!macro tmsCreateSprite .ind, .pattInd, .xPos, .yPos, .color {

        

        ; sprite attr table
        +tmsSetAddrSpriteAttrTableInd .ind

        +tmsPut .yPos
        +tmsPut .xPos
        +tmsPut .pattInd
        +tmsPut .color
        
}

; -----------------------------------------------------------------------------
; tmsSpritePos: Set a sprite position
; -----------------------------------------------------------------------------
!macro tmsSpritePos .ind, .xPos, .yPos {
        

        ; sprite attr table
        +tmsSetAddrSpriteAttrTableInd .ind

        +tmsPut .yPos
        +tmsPut .xPos        
}

; -----------------------------------------------------------------------------
; tmsSpritePosXYReg: Set a sprite position from x/y registers
; -----------------------------------------------------------------------------
!macro tmsSpritePosXYReg .ind {
        

        ; sprite attr table
        +tmsSetAddrSpriteAttrTableInd .ind

        tya
        +tmsPut 
        txa
        +tmsPut 
}


; -----------------------------------------------------------------------------
; tmsSetAddrSpriteColor: Change a sprite color
; -----------------------------------------------------------------------------
!macro tmsSetAddrSpriteColor .ind {

        ; sprite attr table
        +tmsSetAddressWrite TMS_VRAM_SPRITE_ATTR_ADDRESS + (.ind * 4) + 3
}
; -----------------------------------------------------------------------------
; tmsSpriteColor: Change a sprite color
; -----------------------------------------------------------------------------
!macro tmsSpriteColor .ind, .color {

        +tmsSetAddrSpriteColor .ind

        +tmsPut .color
}


; -----------------------------------------------------------------------------
; tmsHex8: Output an 8-bit byte as hexadecimal
; -----------------------------------------------------------------------------
; Inputs:
;  A: The value to output
; -----------------------------------------------------------------------------
tmsHex8:
	sta R2
        +lsr4
	tax
	lda .H2, x
        +tmsPut 
	lda R2
	and #$0f
	tax
	lda .H2, x
        +tmsPut 
        
	rts

.H2 !text "0123456789abcdef"


; -----------------------------------------------------------------------------
; tmsSetPosWrite: Set cursor position
; -----------------------------------------------------------------------------
!macro tmsSetPosWrite .x, .y {
        +tmsSetAddressWrite (TMS_VRAM_NAME_ADDRESS + .y * 32 + .x)
}

; -----------------------------------------------------------------------------
; tmsSetPosRead: Set read cursor position
; -----------------------------------------------------------------------------
!macro tmsSetPosRead .x, .y {
        +tmsSetAddressRead (TMS_VRAM_NAME_ADDRESS + .y * 32 + .x)
}

; -----------------------------------------------------------------------------
; tmsSetPosTmpAddress: Set TMS_TMP_ADDRESS for a given text position
; -----------------------------------------------------------------------------
; Inputs:
;   X: X position (0 - 31)
;   Y: Y position (0 - 23)
; -----------------------------------------------------------------------------
tmsSetPosTmpAddress:
        lda #>TMS_VRAM_NAME_ADDRESS
        sta TMS_TMP_ADDRESS + 1
        
        ; this can be better. rotate and save, perhaps

        tya
        +div8
        clc
        adc TMS_TMP_ADDRESS + 1
        sta TMS_TMP_ADDRESS + 1
        tya
        and #$07
        +mul32
        sta TMS_TMP_ADDRESS
        txa
        ora TMS_TMP_ADDRESS
        sta TMS_TMP_ADDRESS
        rts

; -----------------------------------------------------------------------------
; tmsSetPosWrite: Set cursor position
; -----------------------------------------------------------------------------
; Inputs:
;   X: X position (0 - 31)
;   Y: Y position (0 - 23)
; -----------------------------------------------------------------------------
tmsSetPosWrite:
        jsr tmsSetPosTmpAddress
        jmp tmsSetAddressWrite


; -----------------------------------------------------------------------------
; tmsSetPosRead: Set cursor position to read from
; -----------------------------------------------------------------------------
; Inputs:
;   X: X position (0 - 31)
;   Y: Y position (0 - 23)
; -----------------------------------------------------------------------------
tmsSetPosRead:
        jsr tmsSetPosTmpAddress
        jmp tmsSetAddressRead


; -----------------------------------------------------------------------------
; tmsSetPatternTmpAddress: Set TMS_TMP_ADDRESS for a given pattern definition
; -----------------------------------------------------------------------------
; Inputs:
;   A: Pattern number
;   Y: Y offset (row) in the pattern
; -----------------------------------------------------------------------------
tmsSetPatternTmpAddress:
        sta R2
        lda #>TMS_VRAM_PATT_ADDRESS
        sta TMS_TMP_ADDRESS + 1
        
        lda R2

        +div32
        clc
        adc TMS_TMP_ADDRESS + 1
        sta TMS_TMP_ADDRESS + 1
        lda R2
        and #$1f
        +mul8
        sta TMS_TMP_ADDRESS
        tya
        ora TMS_TMP_ADDRESS
        sta TMS_TMP_ADDRESS
        rts

; -----------------------------------------------------------------------------
; tmsSetPatternWrite: Set pattern definition to write to
; -----------------------------------------------------------------------------
; Inputs:
;   A: Pattern number
;   Y: Y offset (row) in the pattern
; -----------------------------------------------------------------------------
tmsSetPatternWrite:
        jsr tmsSetPatternTmpAddress
        jmp tmsSetAddressWrite

; -----------------------------------------------------------------------------
; tmsSetPatternRead: Set pattern definition to read from
; -----------------------------------------------------------------------------
; Inputs:
;   A: Pattern number
;   Y: Y offset (row) in the pattern
; -----------------------------------------------------------------------------
tmsSetPatternRead:
        jsr tmsSetPatternTmpAddress
        jmp tmsSetAddressRead


; -----------------------------------------------------------------------------
; tmsPrint: Print immediate text
; -----------------------------------------------------------------------------
; Inputs:
;  str: String to print
;  x: x position
;  y: y position
; -----------------------------------------------------------------------------
!macro tmsPrint .str, .x, .y {
	jmp .afterText
.textAddr
	!text .str,0
.afterText        

        +tmsSetPosWrite .x, .y

        lda #<.textAddr
        sta STR_ADDR_L
        lda #>.textAddr
        sta STR_ADDR_H
        jsr tmsPrint        
}


; -----------------------------------------------------------------------------
; tmsPrintCentre: Print centre-aligned immediate text
; -----------------------------------------------------------------------------
; Inputs:
;  str: String to print
;  y: y position
; -----------------------------------------------------------------------------
!macro tmsPrintCentre .str, .y {
	jmp .afterText
.textAddr
	!text .str,0
.afterText        

        +tmsSetPosWrite (32 - ((.afterText - 1) - .textAddr)) / 2, .y

        lda #<.textAddr
        sta STR_ADDR_L
        lda #>.textAddr
        sta STR_ADDR_H
        jsr tmsPrint        
}


; -----------------------------------------------------------------------------
; tmsPrintZ: Print text
; -----------------------------------------------------------------------------
; Inputs:
;  str: Address of zero-terminated string to print
;  x: x position
;  y: y position
; -----------------------------------------------------------------------------
!macro tmsPrintZ .textAddr, .x, .y {
        +tmsSetPosWrite .x, .y

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
;  TMS address already set using +tmsSetAddressWrite
; -----------------------------------------------------------------------------
tmsPrint:
	ldy #0
-
	+tmsWaitData
	lda (STR_ADDR), y
	beq +
        +tmsPut 
	iny
	bne -
+
	rts
