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

!src "hbc56.inc"
!src "ut/math_macros.asm"
!src "gfx/tms9918macros.asm"

TMS_FONT_DATA:
!src "gfx/fonts/tms9918font2subset.asm"

; -------------------------
; Constants
; -------------------------
TMS9918_IO_ADDR = $10
TMS9918_REG0_SHADOW_ADDR = $7e10
TMS9918_REG1_SHADOW_ADDR = $7e11

TMS9918_CONSOLE_X        = $7e12
TMS9918_CONSOLE_Y        = $7e13
TMS9918_CONSOLE_SIZE_X   = $7e14
TMS9918_TMP_BUFFER       = $7e20 ; 32 bytes 

; IO Ports
TMS9918_RAM     = IO_PORT_BASE_ADDRESS | TMS9918_IO_ADDR
TMS9918_REG     = IO_PORT_BASE_ADDRESS | TMS9918_IO_ADDR | $01

; -----------------------------------------------------------------------------
; Zero page
; -----------------------------------------------------------------------------
TMS_TMP_ADDRESS = $ed

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
!byte TMS_R0_EXT_VDP_DISABLE
!byte TMS_R1_RAM_16K | TMS_R1_SPRITE_MAG2
!byte TMS_VRAM_NAME_ADDRESS >> 10
!byte TMS_VRAM_COLOR_ADDRESS >> 6
!byte TMS_VRAM_PATT_ADDRESS >> 11
!byte TMS_VRAM_SPRITE_ATTR_ADDRESS >> 7
!byte TMS_VRAM_SPRITE_PATT_ADDRESS >> 11
!byte TMS_BLACK << 4 | TMS_BLACK


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
; tmsSetRegister: Set a register value
; -----------------------------------------------------------------------------
; Inputs:
;  A: The value to set
;  X: The register (0 - 7)
; -----------------------------------------------------------------------------
tmsSetRegister:
        pha
        sta TMS9918_REG
        +tmsWaitReg
        txa
        ora #$80
        sta TMS9918_REG
        +tmsWaitReg
        pla
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

; -----------------------------------------------------------------------------
; tmsModeGraphicsI: Set up for Graphics I mode
; -----------------------------------------------------------------------------
tmsModeGraphicsI:
        lda #TMS_R0_MODE_GRAPHICS_I
        jsr tmsReg0SetFields

        lda #TMS_R1_MODE_GRAPHICS_I
        jsr tmsReg1SetFields

        lda #32
        sta TMS9918_CONSOLE_SIZE_X
        rts

; -----------------------------------------------------------------------------
; tmsModeGraphicsII: Set up for Graphics II mode
; -----------------------------------------------------------------------------
tmsModeGraphicsII:
        lda #TMS_R0_MODE_GRAPHICS_II
        jsr tmsReg0SetFields

        lda #TMS_R1_MODE_GRAPHICS_II
        jsr tmsReg1SetFields

        lda #32
        sta TMS9918_CONSOLE_SIZE_X

        rts

; -----------------------------------------------------------------------------
; tmsModeText: Set up for Text mode
; -----------------------------------------------------------------------------
tmsModeText:
        lda #TMS_R0_MODE_TEXT
        jsr tmsReg0SetFields

        lda #TMS_R1_MODE_TEXT
        jsr tmsReg1SetFields

        lda #40
        sta TMS9918_CONSOLE_SIZE_X

        rts

; -----------------------------------------------------------------------------
; tmsModeMulticolor: Set up for Multicolor mode
; -----------------------------------------------------------------------------
tmsModeMulticolor:
        lda #TMS_R0_MODE_MULTICOLOR
        jsr tmsReg0SetFields

        lda #TMS_R1_MODE_MULTICOLOR
        jsr tmsReg1SetFields
        rts

; -----------------------------------------------------------------------------
; tmsInit: Initialise the registers
; -----------------------------------------------------------------------------
tmsInit:
        lda TMS_REGISTER_DATA
        sta TMS9918_REG0_SHADOW_ADDR
        lda TMS_REGISTER_DATA + 1
        sta TMS9918_REG1_SHADOW_ADDR

        lda #0
        sta TMS9918_CONSOLE_X
        sta TMS9918_CONSOLE_Y

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
        
        jsr tmsModeGraphicsI

        ; load all data into VRAM
        jsr tmsInitPattTable

        jsr tmsInitTextTable
        
        +tmsColorFgBg TMS_BLACK, TMS_CYAN
        jsr tmsInitEntireColorTable

        jsr tmsInitSpriteTable

        rts


; -----------------------------------------------------------------------------
; _tmsSendPage: Send A for a whole page
; -----------------------------------------------------------------------------
_tmsSendPage:
        ldx #32
_tmsSendX8:
        +tmsPut
        +tmsPut
        +tmsPut
        +tmsPut
        +tmsPut
        +tmsPut
        +tmsPut
        +tmsPut
        dex
        bne _tmsSendX8
        rts

; -----------------------------------------------------------------------------
; _tmsSendEmptyPage: Send an empty page of data
; -----------------------------------------------------------------------------
_tmsSendEmptyPage:
        lda #0
        beq _tmsSendPage ; rts in here

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
; tmsInitTextTable: Initialise the text (tilemap) table
; -----------------------------------------------------------------------------
tmsInitTextTable:
        

        ; text table table
        +tmsSetAddrNameTable


        lda #0
        ldx #(32 * 3)
        jsr _tmsSendX8

        rts


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
        
        pha

        ; color table
        +tmsSetAddrColorTable

        pla
-
        +tmsPut
        dex
        bne -

        rts

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
        pha
        txa
        +div8
        tax

        tya
        +div8
        tay
        pla
        rts

; -----------------------------------------------------------------------------
; tmsHex8: Output an 8-bit byte as hexadecimal
; -----------------------------------------------------------------------------
; Inputs:
;  A: The value to output
; -----------------------------------------------------------------------------
tmsHex8:
	pha
        +lsr4
	tax
	lda .H2, x
        +tmsPut 
	pla
	and #$0f
	tax
	lda .H2, x
        +tmsPut 
        
	rts

.H2 !text "0123456789abcdef"


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
; tmsSetPosTmpAddressText: Set TMS_TMP_ADDRESS for a given text position
; -----------------------------------------------------------------------------
; Inputs:
;   X: X position (0 - 39)
;   Y: Y position (0 - 23)
; -----------------------------------------------------------------------------
tmsSetPosTmpAddressText:
        lda #>TMS_VRAM_NAME_ADDRESS
        sta TMS_TMP_ADDRESS + 1
        lda #<TMS_VRAM_NAME_ADDRESS
        sta TMS_TMP_ADDRESS

.tmsSetPosTmpAddressTextLoop
        cpy #0
        beq ++
        clc
        lda TMS_TMP_ADDRESS
        adc #40
        sta TMS_TMP_ADDRESS
        bcc +
        inc TMS_TMP_ADDRESS + 1
+
        dey
        bne .tmsSetPosTmpAddressTextLoop
++
        clc
        txa
        adc TMS_TMP_ADDRESS
        sta TMS_TMP_ADDRESS
        bcc +
        inc TMS_TMP_ADDRESS + 1
+
        rts

TMP_READ_ROW = $7e18
TMP_WRITE_ROW = $7e19

tmsConsoleScrollLine:
        lda #0
        sta TMP_WRITE_ROW
        lda #1
        sta TMP_READ_ROW
.nextRow:

        ldy TMP_READ_ROW
        ldx #0
        jsr tmsSetPosTmpAddressText
        jsr tmsSetAddressRead

        jsr .tmsBufferIn

        ldx #0
        ldy TMP_WRITE_ROW
        ldx #0
        jsr tmsSetPosTmpAddressText
        jsr tmsSetAddressWrite

        jsr .tmsBufferOut


        inc TMP_WRITE_ROW
        inc TMP_READ_ROW

        lda TMP_READ_ROW
        cmp #25

        bne .nextRow


        ; copy to buffer 32 bytes at a time, write back  24 rows for gfx, 30 "rows" for text
        rts

.tmsBufferIn:
        ldx #0
-
        +tmsGet
        sta TMS9918_TMP_BUFFER, x
        inx
        cpx TMS9918_CONSOLE_SIZE_X
        bne -
        rts

.tmsBufferOut:
        ldx #0

-
        lda TMS9918_TMP_BUFFER, x
        +tmsPut
        inx
        cpx TMS9918_CONSOLE_SIZE_X
        bne -
        rts

; -----------------------------------------------------------------------------
; tmsIncPosConsole: Increment consoel position
; -----------------------------------------------------------------------------
tmsIncPosConsole:
        inc TMS9918_CONSOLE_X
        lda TMS9918_CONSOLE_X
        cmp TMS9918_CONSOLE_SIZE_X
        bne +
        lda #0
        sta TMS9918_CONSOLE_X
        inc TMS9918_CONSOLE_Y
+
        lda TMS9918_CONSOLE_Y
        cmp #24
        bne +
        dec TMS9918_CONSOLE_Y
        jmp tmsConsoleScrollLine
+
        rts


; -----------------------------------------------------------------------------
; tmsDecPosConsole: Increment console position
; -----------------------------------------------------------------------------
tmsDecPosConsole:
        dec TMS9918_CONSOLE_X
        bpl ++
        lda TMS9918_CONSOLE_SIZE_X
        sta TMS9918_CONSOLE_X
        dec TMS9918_CONSOLE_X
        lda #0
        cmp TMS9918_CONSOLE_Y
        bne +
        sta TMS9918_CONSOLE_X
        rts        
+
        dec TMS9918_CONSOLE_Y
++
        rts


; -----------------------------------------------------------------------------
; tmsSetPosConsole: Set cursor position to console position
; -----------------------------------------------------------------------------
tmsSetPosConsole:
        ldx TMS9918_CONSOLE_X
        ldy TMS9918_CONSOLE_Y

        ; flow through

; -----------------------------------------------------------------------------
; tmsSetPosWrite: Set cursor position
; -----------------------------------------------------------------------------
; Inputs:
;   X: X position (0 - 31)
;   Y: Y position (0 - 23)
; -----------------------------------------------------------------------------
tmsSetPosWrite:
        lda #TMS_R1_MODE_TEXT
        bit TMS9918_REG1_SHADOW_ADDR
        bne tmsSetPosWriteText
        jsr tmsSetPosTmpAddress
        jmp tmsSetAddressWrite

; -----------------------------------------------------------------------------
; tmsSetPosWrite: Set cursor position (text mode)
; -----------------------------------------------------------------------------
; Inputs:
;   X: X position (0 - 39)
;   Y: Y position (0 - 23)
; -----------------------------------------------------------------------------
tmsSetPosWriteText:
        jsr tmsSetPosTmpAddressText
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
        pha
        lda #>TMS_VRAM_PATT_ADDRESS
        sta TMS_TMP_ADDRESS + 1
        
        pla
        pha

        +div32
        clc
        adc TMS_TMP_ADDRESS + 1
        sta TMS_TMP_ADDRESS + 1
        pla
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