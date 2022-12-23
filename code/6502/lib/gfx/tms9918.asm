; 6502 - TMS9918 VDP
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;

!src "hbc56.inc"

!ifndef HAVE_MATH_INC { !src "ut/math.inc" }
!src "gfx/tms9918.inc"

TMS_FONT_DATA:
!src "gfx/fonts/hbc56font.asm"

HAVE_TMS9918 = 1

; -------------------------
; Constants
; -------------------------
!ifndef TMS9918_IO_PORT { TMS9918_IO_PORT = $10
        !warn "TMS9918_IO_PORT not provided. Defaulting to ", TMS9918_IO_PORT
}

!ifndef TMS9918_ZP_START { TMS9918_ZP_START = $30
        !warn "TMS9918_ZP_START not provided. Defaulting to ", TMS9918_ZP_START
}

!ifndef TMS9918_RAM_START { TMS9918_RAM_START = $7ba0
        !warn "TMS9918_RAM_START not provided. Defaulting to ", TMS9918_RAM_START
}

; -----------------------------------------------------------------------------
; Zero page
; -----------------------------------------------------------------------------
TMS_TMP_ADDRESS         = TMS9918_ZP_START      ; 2 bytes
TMS9918_ZP_SIZE         = 2                     ; LAST ZP ADDRESS

; -----------------------------------------------------------------------------
; High RAM
; -----------------------------------------------------------------------------
.TMS9918_REG0_SHADOW_ADDR = TMS9918_RAM_START
.TMS9918_REG1_SHADOW_ADDR = TMS9918_RAM_START + 1

TMS9918_CONSOLE_X         = TMS9918_RAM_START + 2
TMS9918_CONSOLE_Y         = TMS9918_RAM_START + 3
TMS9918_CONSOLE_SIZE_X    = TMS9918_RAM_START + 4
TMS9918_CONSOLE_LINE_LEN  = TMS9918_RAM_START + 5
.TMS9918_REGX             = TMS9918_RAM_START + 6
.TMS9918_REGY             = TMS9918_RAM_START + 7
.TMS9918_TMP_READ_ROW     = TMS9918_RAM_START + 8
.TMS9918_TMP_WRITE_ROW    = TMS9918_RAM_START + 9

TMS9918_TMP_BUFFER        = TMS9918_RAM_START + 10 ; 40 bytes 
TMS9918_RAM_SIZE          = 50



!if TMS9918_ZP_END < (TMS9918_ZP_START + TMS9918_ZP_SIZE) {
	!error "TMS9918_ZP requires ",TMS9918_ZP_SIZE," bytes. Allocated ",TMS9918_ZP_END - TMS9918_ZP_START
}

!if TMS9918_RAM_END < (TMS9918_RAM_START + TMS9918_RAM_SIZE) {
	!error "TMS9918_RAM requires ",.TMS9918_RAM_SIZE," bytes. Allocated ",TMS9918_RAM_END - TMS9918_RAM_START
}


; IO Ports
TMS9918_RAM     = IO_PORT_BASE_ADDRESS | TMS9918_IO_PORT
TMS9918_REG     = IO_PORT_BASE_ADDRESS | TMS9918_IO_PORT | $01


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
!byte TMS_R1_RAM_16K
!byte TMS_VRAM_NAME_ADDRESS >> 10
!byte TMS_VRAM_COLOR_ADDRESS >> 6
!byte TMS_VRAM_PATT_ADDRESS >> 11
!byte TMS_VRAM_SPRITE_ATTR_ADDRESS >> 7
!byte TMS_VRAM_SPRITE_PATT_ADDRESS >> 11
!byte TMS_BLACK << 4 | TMS_BLACK


; -----------------------------------------------------------------------------
; Delay subroutines required for TMS9918 CPU access windows
; -----------------------------------------------------------------------------
;      CONDITION          MODE    VDP DELAY       WAIT TIME          TOTAL TIME
; -----------------------------------------------------------------------------
;  Active Display Area   Text        2uS          0 - 1.1uS           2 - 3.1uS      
;  Active Display Area   GFX I, II   2uS          0 - 5.95uS          2 - 8uS      
;  4300uS after VSYNC    All         2uS             0uS                2uS      
;  Reg 1 Blank Bit 0     All         2uS             0uS                2uS      
;  Active Display Area   Multicolor  2uS          0 - 1.5uS           2 - 3.5uS      
; -----------------------------------------------------------------------------
_tmsWaitData:
        nop
        nop
        nop
        nop
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

tmsSetAddressNextRow:
        lda TMS_TMP_ADDRESS
        clc
        adc #32
        sta TMS_TMP_ADDRESS
        bcc +
        inc TMS_TMP_ADDRESS + 1
+
        rts

; -----------------------------------------------------------------------------
; tmsSetAddressWrite: Set an address in the TMS9918 
; -----------------------------------------------------------------------------
; TMS_TMP_ADDRESS: Address to set
; -----------------------------------------------------------------------------
tmsSetAddressWrite:
        php
        sei                     ; we can't be interrupted here
        lda TMS_TMP_ADDRESS
        sta TMS9918_REG
        +tmsWaitReg
        lda TMS_TMP_ADDRESS + 1
        ora #$40
        sta TMS9918_REG
        +tmsWaitReg
        plp
        rts

; -----------------------------------------------------------------------------
; tmsSetAddressRead: Set an address to read from the TMS9918 
; -----------------------------------------------------------------------------
; TMS_TMP_ADDRESS: Address to read
; -----------------------------------------------------------------------------
tmsSetAddressRead:
        php
        sei                     ; we can't be interrupted here
        lda TMS_TMP_ADDRESS
        sta TMS9918_REG
        +tmsWaitReg
        lda TMS_TMP_ADDRESS + 1
        sta TMS9918_REG
        +tmsWaitReg
        plp
        rts


; -----------------------------------------------------------------------------
; tmsSetRegister: Set a register value
; -----------------------------------------------------------------------------
; Inputs:
;  A: The value to set
;  X: The register (0 - 7)
; -----------------------------------------------------------------------------
tmsSetRegister:
        php
        sei             ; we can't be interrupted here
        sta TMS9918_REG
        +tmsWaitReg
        txa
        ora #$80
        sta TMS9918_REG
        +tmsWaitReg
        plp
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
        ora .TMS9918_REG0_SHADOW_ADDR
.tmsReg0SetFields:
        sta .TMS9918_REG0_SHADOW_ADDR
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
        and .TMS9918_REG0_SHADOW_ADDR
        jmp .tmsReg0SetFields


; -----------------------------------------------------------------------------
; tmsReg1Set: Set register 0
; -----------------------------------------------------------------------------
; Outputs:
;  A: Field values to set (will be OR'd with existing Reg1)
; -----------------------------------------------------------------------------
tmsReg1SetFields:
        ora .TMS9918_REG1_SHADOW_ADDR
.tmsReg1SetFields:
        sta .TMS9918_REG1_SHADOW_ADDR
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
        and .TMS9918_REG1_SHADOW_ADDR
        jmp .tmsReg1SetFields


; -----------------------------------------------------------------------------
; tmsModeReset: Reset graphics Mode
; -----------------------------------------------------------------------------
tmsModeReset:
        lda #$03
        jsr tmsReg0ClearFields

        lda #$18
        jsr tmsReg1ClearFields

        ; if we were in Graphics II, then we need to reset
        ; the color and pattern table addresses
        lda #<(TMS_VRAM_COLOR_ADDRESS >> 6)
        ldx #3
        jsr tmsSetRegister

        lda #<(TMS_VRAM_PATT_ADDRESS >> 11)
        ldx #4
        jsr tmsSetRegister
        rts

; -----------------------------------------------------------------------------
; tmsModeGraphicsI: Set up for Graphics I mode
; -----------------------------------------------------------------------------
tmsModeGraphicsI:
        jsr tmsModeReset

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
        jsr tmsModeReset

        lda #TMS_R0_MODE_GRAPHICS_II
        jsr tmsReg0SetFields

        lda #TMS_R1_MODE_GRAPHICS_II
        jsr tmsReg1SetFields

        ; in Graphics II, Registers 3 and 4 work differently
        ;
        ; reg3 - Color table
        ;   $7f = $0000
        ;   $ff = $2000
        ;
        ; reg4 - Pattern table
        ;  $03 = $0000
        ;  $07 = $2000

        ; set color table to $0000
        lda #$7f
        ldx #3
        jsr tmsSetRegister

        ; set pattern table to $2000
        lda #$07
        ldx #4
        jsr tmsSetRegister

        lda #32
        sta TMS9918_CONSOLE_SIZE_X

        rts

; -----------------------------------------------------------------------------
; tmsModeText: Set up for Text mode
; -----------------------------------------------------------------------------
tmsModeText:
        jsr tmsModeReset

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
        jsr tmsModeReset

        lda #TMS_R0_MODE_MULTICOLOR
        jsr tmsReg0SetFields

        lda #TMS_R1_MODE_MULTICOLOR
        jsr tmsReg1SetFields
        rts

; -----------------------------------------------------------------------------
; tmsInit: Initialise the registers
; -----------------------------------------------------------------------------
tmsInit:
        php
        sei                             ; we can't be interrupted here
        lda TMS_REGISTER_DATA
        sta .TMS9918_REG0_SHADOW_ADDR
        lda TMS_REGISTER_DATA + 1
        sta .TMS9918_REG1_SHADOW_ADDR

        lda #0
        sta TMS9918_CONSOLE_X
        sta TMS9918_CONSOLE_Y

        ; set up the registers
        ldx #0

@regLoop
                lda TMS_REGISTER_DATA, x
                sta TMS9918_REG
                +tmsWaitReg
                txa
                ora #$80
                sta TMS9918_REG
                +tmsWaitReg
                inx
                cpx #8
                bne @regLoop
        
        jsr tmsModeGraphicsI

        ; load all data into VRAM
        jsr tmsInitPattTable

        jsr tmsInitTextTable
        
        +tmsColorFgBg TMS_BLACK, TMS_CYAN
        jsr tmsInitEntireColorTable

        jsr tmsInitSpriteTable

        plp
        
        rts

; -----------------------------------------------------------------------------
; _tmsSendPage: Send A for a kilobyte
; -----------------------------------------------------------------------------
_tmsSendKb
        jsr _tmsSendPage
        jsr _tmsSendPage
        jsr _tmsSendPage
        ; flow through
        
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
        ldx #(42 * 3)
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
; tmsSetSpriteTmpAddress: Set TMS_TMP_ADDRESS for a given sprite attributes
; -----------------------------------------------------------------------------
; Inputs:
;   A: sprite index (0-31)
; -----------------------------------------------------------------------------
tmsSetSpriteTmpAddress:
        asl
        asl
        sta TMS_TMP_ADDRESS

        lda #>TMS_VRAM_SPRITE_ATTR_ADDRESS
        sta TMS_TMP_ADDRESS + 1
        rts

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


tmsConsoleScrollLine:
        lda #0
        sta .TMS9918_TMP_WRITE_ROW
        lda #1
        sta .TMS9918_TMP_READ_ROW
.nextRow:

        ldy .TMS9918_TMP_READ_ROW
        ldx #0
        lda #40
        cmp TMS9918_CONSOLE_SIZE_X
        beq +
        jsr tmsSetPosTmpAddress
        jmp ++
+
        jsr tmsSetPosTmpAddressText
++
        jsr tmsSetAddressRead

        jsr .tmsBufferIn

        ldx #0
        ldy .TMS9918_TMP_WRITE_ROW
        ldx #0
        lda #40
        cmp TMS9918_CONSOLE_SIZE_X
        beq +
        jsr tmsSetPosTmpAddress
        jmp ++
+
        jsr tmsSetPosTmpAddressText
++
        jsr tmsSetAddressWrite

        jsr .tmsBufferOut


        inc .TMS9918_TMP_WRITE_ROW
        inc .TMS9918_TMP_READ_ROW

        lda .TMS9918_TMP_READ_ROW
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
; tmsIncPosConsole: Increment console position
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
        bcc +
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
; tmsConsoleHome: Set cursor position top left
; -----------------------------------------------------------------------------
tmsConsoleHome:
        stz TMS9918_CONSOLE_X
        stz TMS9918_CONSOLE_Y

        ; flow through

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
        bit .TMS9918_REG1_SHADOW_ADDR
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
; tmsSetPatternTmpAddress: Set TMS_TMP_ADDRESS for a given mode II pattern definition
; -----------------------------------------------------------------------------
; Inputs:
;   X: X position
;   Y: Y position
; -----------------------------------------------------------------------------
tmsSetPatternTmpAddressII:
        lda #>TMS_VRAM_PATT_ADDRESS
        sta TMS_TMP_ADDRESS + 1

        tya
        +lsr3
        ora TMS_TMP_ADDRESS + 1
        sta TMS_TMP_ADDRESS + 1

        txa
        and #$f8
        sta TMS_TMP_ADDRESS

        tya
        and #$07
        ora TMS_TMP_ADDRESS
        sta TMS_TMP_ADDRESS

        rts

; -----------------------------------------------------------------------------
; tmsSetPatternTmpAddress: Set TMS_TMP_ADDRESS for a given pattern definition
; -----------------------------------------------------------------------------
; Inputs:
;   A: Pattern number
;   Y: Y offset (row) in the pattern
; -----------------------------------------------------------------------------
tmsSetPatternTmpAddressBank0:
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
        +mul8
        sta TMS_TMP_ADDRESS
        tya
        ora TMS_TMP_ADDRESS
        sta TMS_TMP_ADDRESS
        rts

; -----------------------------------------------------------------------------
; tmsSetPatternTmpAddressBank1: Set TMS_TMP_ADDRESS for a given pattern 
;                               definition in bank 1 (GFX II)
; -----------------------------------------------------------------------------
; Inputs:
;   A: Pattern number
;   Y: Y offset (row) in the pattern
; -----------------------------------------------------------------------------
tmsSetPatternTmpAddressBank1:
        jsr tmsSetPatternTmpAddress
        lda TMS_TMP_ADDRESS + 1
        clc
        adc #8
        sta TMS_TMP_ADDRESS + 1
        rts

; -----------------------------------------------------------------------------
; tmsSetPatternTmpAddressBank2: Set TMS_TMP_ADDRESS for a given pattern 
;                               definition in bank 2 (GFX II)
; -----------------------------------------------------------------------------
; Inputs:
;   A: Pattern number
;   Y: Y offset (row) in the pattern
; -----------------------------------------------------------------------------
tmsSetPatternTmpAddressBank2:
        jsr tmsSetPatternTmpAddress
        lda TMS_TMP_ADDRESS + 1
        clc
        adc #16
        sta TMS_TMP_ADDRESS + 1
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


; -----------------------------------------------------------------------------
; tmsConsoleOut: Print a null-terminated string
; -----------------------------------------------------------------------------
; Inputs:
;  'A': Character to output to console
; -----------------------------------------------------------------------------
tmsConsoleOut:
        stx .TMS9918_REGX
        sty .TMS9918_REGY
        php
        sei
        cmp #$0d ; enter
        beq .tmsConsoleNewline
        cmp #$0a ; enter
        beq .tmsConsoleNewline

        cmp #$08 ; backspace
        beq .tmsConsoleBackspace

        pha
        jsr tmsSetPosConsole
        pla
        +tmsPut
        jsr tmsIncPosConsole
        inc TMS9918_CONSOLE_LINE_LEN

.endConsoleOut
        plp
        ldy .TMS9918_REGY
        ldx .TMS9918_REGX
        rts

.tmsConsoleNewline
        jsr tmsConsoleNewline
        jmp .endConsoleOut

.tmsConsoleBackspace
        jsr tmsConsoleBackspace
        jmp .endConsoleOut


; -----------------------------------------------------------------------------
; tmsConsolePrint: Print a null-terminated string (console mode)
; -----------------------------------------------------------------------------
; Inputs:
;  STR_ADDR: Contains address of null-terminated string
; Prerequisites:
;  TMS address already set using +tmsSetAddressWrite
; -----------------------------------------------------------------------------
tmsConsolePrint:
	ldy #0
-
	+tmsWaitData
	lda (STR_ADDR), y
	beq +
        jsr tmsConsoleOut
	iny
	bne -
+
	rts

; -----------------------------------------------------------------------------
; tmsConsoleNewline: Output a newline to the console (scrolls if on last line)
; -----------------------------------------------------------------------------
tmsConsoleNewline:
        jsr tmsSetPosConsole
        +tmsPut ' '
        lda TMS9918_CONSOLE_X
        bne +
        lda TMS9918_CONSOLE_LINE_LEN
        beq +
        rts
        beq +
+
        lda TMS9918_CONSOLE_SIZE_X
        sta TMS9918_CONSOLE_X
        dec TMS9918_CONSOLE_X
        stz TMS9918_CONSOLE_LINE_LEN
        jmp tmsIncPosConsole


; -----------------------------------------------------------------------------
; tmsConsoleBackspace: Output a backspace to the console
; -----------------------------------------------------------------------------
tmsConsoleBackspace:
        jsr tmsDecPosConsole
        +tmsConsoleOut ' '
        +tmsPut ' '
        dec TMS9918_CONSOLE_LINE_LEN
        jmp tmsDecPosConsole
