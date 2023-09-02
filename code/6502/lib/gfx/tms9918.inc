; 6502 - TMS9918 VDP Macros
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;




; -----------------------------------------------------------------------------
; tmsWaitReg: Not sure how much delay we need so make a macro for now
; -----------------------------------------------------------------------------
!macro tmsWaitReg {
;        jsr _tmsWaitReg
}

; -----------------------------------------------------------------------------
; tmsWaitData: Not sure how much delay we need so make a macro for now
; -----------------------------------------------------------------------------
!macro tmsWaitData {
        jsr _tmsWaitData
}

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
        php
        sei             ; we can't be interrupted here
        lda #<(.addr)
        sta TMS9918_REG
        +tmsWaitReg
        lda #>(.addr)
        sta TMS9918_REG
        +tmsWaitReg
        plp
}

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
        lda #(.byte & 0xff)
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
; tmsPutX: Send a byte (X) of data to the TMS9918
; -----------------------------------------------------------------------------
!macro tmsPutX {
        stx TMS9918_RAM
        +tmsWaitData
}

; -----------------------------------------------------------------------------
; tmsPutY: Send a byte (Y) of data to the TMS9918
; -----------------------------------------------------------------------------
!macro tmsPutY {
        sty TMS9918_RAM
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
; tmsSetColorFgBg: Set current fg/bg color
; -----------------------------------------------------------------------------
!macro tmsSetColorFgBg .fg, .bg {
        +tmsColorFgBg .fg, .bg
        jsr tmsSetBackground
}

; -----------------------------------------------------------------------------
; byteTmsColorFgBg: Output a data byte
; -----------------------------------------------------------------------------
!macro byteTmsColorFgBg .fg, .bg {
!byte (.fg << 4 | .bg)
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

; -
!macro tmsEnableInterrupts {
        lda #TMS_R1_INT_ENABLE
        jsr tmsReg1SetFields
}

!macro tmsDisableInterrupts {
        lda #TMS_R1_INT_ENABLE
        jsr tmsReg1ClearFields
}

!macro tmsConsoleOut .char {
        lda #.char
        jsr tmsConsoleOut
}


; -----------------------------------------------------------------------------
; tmsConsolePrintAddr: Print text to console
; -----------------------------------------------------------------------------
; Inputs:
;  textAddr: Address of null-terminated string to print
; -----------------------------------------------------------------------------
!macro tmsConsolePrintAddr .textAddr {
        lda #<.textAddr
        sta STR_ADDR_L
        lda #>.textAddr
        sta STR_ADDR_H
        jsr tmsConsolePrint        
}

; -----------------------------------------------------------------------------
; tmsConsolePrint: Print immediate text to console
; -----------------------------------------------------------------------------
; Inputs:
;  str: String to print
; -----------------------------------------------------------------------------
!macro tmsConsolePrint .str {
	jmp .afterText
.textAddr
	!text .str,0
.afterText        
        +tmsConsolePrintAddr .textAddr
}

; -----------------------------------------------------------------------------
; +tmsColorFgBg: Set A to the given FG / BG color
; -----------------------------------------------------------------------------
!macro tmsColorFgBg .fg, .bg {
        lda #(.fg << 4 | .bg)
}

; -----------------------------------------------------------------------------
; tmsReadStatus: Read status - clear interrupt
; -----------------------------------------------------------------------------
!macro tmsReadStatus  {
        bit TMS9918_REG
}

; -----------------------------------------------------------------------------
; tmsSendData: Send # bytes from .sourceAddr to tms9918 data port
; -----------------------------------------------------------------------------
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
; tmsSendDataReverse: Send # bytes from .sourceAddr to tms9918 data port
; -----------------------------------------------------------------------------
!macro tmsSendDataReverse .sourceAddr, .numBytes {
        lda #<.sourceAddr
        sta TMS_TMP_ADDRESS
        lda #>.sourceAddr
        sta TMS_TMP_ADDRESS + 1

        !if .numBytes < 256 {
                ldx #.numBytes
                jsr tmsSendBytesReverse
        } else {
                !error "tmsSendDataReverse supports <256 bytes only"
        }

}

; -----------------------------------------------------------------------------
; tmsSendDataRpt: Send # bytes from .sourceAddr to tms9918 data port .rpt times
; -----------------------------------------------------------------------------
!macro tmsSendDataRpt .sourceAddr, .numBytes, .rpt {
        lda #<.sourceAddr
        sta TMS_TMP_ADDRESS
        lda #>.sourceAddr
        sta TMS_TMP_ADDRESS + 1

        !if .numBytes < 256 {
                !if .rpt < 5 {
                        !for i,1,.rpt {
                                ldx #.numBytes
                                jsr tmsSendBytes
                        }
                } else {
                        lda #.rpt
                        sta TMS9918_TMP_BUFFER
-
                        ldx #.numBytes
                        jsr tmsSendBytes
                        dec TMS9918_TMP_BUFFER
                        bne -
                }
        } else {
                !error "tmsSendDataRpt supports <256 repetitions only"
        }
}

; -----------------------------------------------------------------------------
; tmsPutAccRpt: Send accumulator .rpt times
; -----------------------------------------------------------------------------
!macro tmsPutAccRpt .rpt {
!if .rpt < 256 {
        ldx #.rpt
-
        +tmsPut
        dex
        bne -
} else  {
        !error "tmsPutAccRpt supports < 256 repetitions only"
}
}


; -----------------------------------------------------------------------------
; tmsPutRpt: Send value .rpt times
; -----------------------------------------------------------------------------
!macro tmsPutRpt .value, .rpt {
        lda #.value
        +tmsPutAccRpt .rpt
}

!macro tmsPutSeq .from, .count {
        lda #.from
-
        +tmsPut
        inc
        cmp #<(.from + .count)
        bne -
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
; tmsSetAddrPattTable: Initialise address for font table
; -----------------------------------------------------------------------------
!macro tmsSetAddrPattTable {
        +tmsSetAddrPattTable 0
}

; -----------------------------------------------------------------------------
; tmsSetAddrPattTable: Initialise address for pattern table
; -----------------------------------------------------------------------------
!macro tmsSetAddrPattTable .ind {
        +tmsSetAddressWrite TMS_VRAM_PATT_ADDRESS + (8 * .ind)
}

; -----------------------------------------------------------------------------
; tmsSetAddrPattTable: Initialise address for pattern table
; -----------------------------------------------------------------------------
!macro tmsSetAddrPattTable .ind, .row {
        +tmsSetAddressWrite TMS_VRAM_PATT_ADDRESS + (8 * .ind) + .row
}

; -----------------------------------------------------------------------------
; tmsSetAddrPattTableIIBank0: Initialise address for pattern table
; -----------------------------------------------------------------------------
!macro tmsSetAddrPattTableIIBank0 .ind {
        +tmsSetAddrPattTable .ind
}

; -----------------------------------------------------------------------------
; tmsSetAddrPattTableIIBank1: Initialise address for pattern table
; -----------------------------------------------------------------------------
!macro tmsSetAddrPattTableIIBank1 .ind {
        +tmsSetAddrPattTable 256 + .ind
}

; -----------------------------------------------------------------------------
; tmsSetAddrPattTableIIBank2: Initialise address for pattern table
; -----------------------------------------------------------------------------
!macro tmsSetAddrPattTableIIBank2 .ind {
        +tmsSetAddrPattTable 512 + .ind
}

; -----------------------------------------------------------------------------
; tmsSetAddrPattTableRead: Initialise address for pattern table to read
; -----------------------------------------------------------------------------
!macro tmsSetAddrPattTableRead .ind {
        +tmsSetAddressRead TMS_VRAM_PATT_ADDRESS + (8 * .ind)
}

; -----------------------------------------------------------------------------
; tmsSetAddrPattTableRowRead: Initialise address for pattern table to read
; -----------------------------------------------------------------------------
!macro tmsSetAddrPattTableRead .ind, .row {
        +tmsSetAddressRead TMS_VRAM_PATT_ADDRESS + (8 * .ind) + .row
}

; -----------------------------------------------------------------------------
; tmsUpdateFont: Update the pattern table with a given font
; -----------------------------------------------------------------------------
!macro tmsUpdateFont .fontAddr {
        +tmsSetAddrPattTable 32
        +tmsSendData .fontAddr, $300
}

; -----------------------------------------------------------------------------
; tmsSetAddrNameTable: Initialise address for base (text) table
; -----------------------------------------------------------------------------
!macro tmsSetAddrNameTable {
        +tmsSetAddressWrite TMS_VRAM_NAME_ADDRESS
}

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
; tmsSetAddrColorTableII: Initialise address for color table index (mode II)
; -----------------------------------------------------------------------------
!macro tmsSetAddrColorTableII .ind {
        +tmsSetAddressWrite TMS_VRAM_COLOR_ADDRESS + .ind * 8
}

; -----------------------------------------------------------------------------
; tmsSetAddrColorTableIIBank0: Initialise address for color table index (mode II)
; -----------------------------------------------------------------------------
!macro tmsSetAddrColorTableIIBank0 .ind {
        +tmsSetAddrColorTableII .ind
}

; -----------------------------------------------------------------------------
; tmsSetAddrColorTableIIBank1: Initialise address for color table index (mode II)
; -----------------------------------------------------------------------------
!macro tmsSetAddrColorTableIIBank1 .ind {
        +tmsSetAddrColorTableII 256 + .ind
}

; -----------------------------------------------------------------------------
; tmsSetAddrColorTableIIBank2: Initialise address for color table index (mode II)
; -----------------------------------------------------------------------------
!macro tmsSetAddrColorTableIIBank2 .ind {
        +tmsSetAddrColorTableII 512 + .ind
}

; -----------------------------------------------------------------------------
; tmsSetAddrSpriteAttrTable: Initialise address for sprite attributes table
; -----------------------------------------------------------------------------
!macro tmsSetAddrSpriteAttrTable {
        +tmsSetAddrSpriteAttrTable 0
}

; -----------------------------------------------------------------------------
; tmsSetAddrSpriteAttrTable: Initialise address for sprite attributes table
; -----------------------------------------------------------------------------
!macro tmsSetAddrSpriteAttrTable .index {
        +tmsSetAddressWrite TMS_VRAM_SPRITE_ATTR_ADDRESS + .index * 4
}

; -----------------------------------------------------------------------------
; tmsSetAddrSpritePattTable: Initialise address for sprite pattern table
; -----------------------------------------------------------------------------
!macro tmsSetAddrSpritePattTable {
        +tmsSetAddrSpritePattTable 0
}

; -----------------------------------------------------------------------------
; tmsSetAddrSpritePattTable: Initialise address for sprite pattern table
; -----------------------------------------------------------------------------
!macro tmsSetAddrSpritePattTable .index {
        +tmsSetAddressWrite TMS_VRAM_SPRITE_PATT_ADDRESS + .index * 8
}


; -----------------------------------------------------------------------------
; tmsCreateSpritePattern: Create a sprite pattern (.spriteDataAddr is 8 bytes)
; -----------------------------------------------------------------------------
!macro tmsCreateSpritePattern .pattInd, .spriteDataAddr {

        

        ; sprite pattern table
        +tmsSetAddrSpritePattTable .pattInd

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
        +tmsSetAddrSpritePattTable .pattInd * 4

        ldx #0
-
        lda .spriteDataAddr,x
        +tmsPut 
        inx
        cpx #32

        

        bne -
}


!macro tmsCreateSpritePatternImm .ind, .b0, .b1, .b2, .b3, .b4, .b5, .b6, .b7 {

        ; sprite pattern table
        +tmsSetAddrSpritePattTable .ind
        +tmsPut .b0
        +tmsPut .b2
        +tmsPut .b2
        +tmsPut .b3
        +tmsPut .b4
        +tmsPut .b5
        +tmsPut .b6
        +tmsPut .b7
}

!macro tmsCreatePatternImm .ind, .b0, .b1, .b2, .b3, .b4, .b5, .b6, .b7 {

        ; sprite pattern table
        +tmsSetAddrPattTable .ind
        +tmsPut .b0
        +tmsPut .b2
        +tmsPut .b2
        +tmsPut .b3
        +tmsPut .b4
        +tmsPut .b5
        +tmsPut .b6
        +tmsPut .b7
}


; -----------------------------------------------------------------------------
; tmsCreateSprite: Create a sprite
; -----------------------------------------------------------------------------
!macro tmsCreateSprite .ind, .pattInd, .xPos, .yPos, .color {

        ; sprite attr table
        +tmsSetAddrSpriteAttrTable .ind

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
        +tmsSetAddrSpriteAttrTable .ind

        +tmsPut .yPos
        +tmsPut .xPos        
}


; -----------------------------------------------------------------------------
; tmsSetLastSprite: Mark a sprite as the last sprite (set next ypos to )
; -----------------------------------------------------------------------------
!macro tmsSetLastSprite .ind {
        +tmsSpritePos .ind + 1, 0, $d0
}


; -----------------------------------------------------------------------------
; tmsSpritePosXYReg: Set a sprite position from x/y registers
; -----------------------------------------------------------------------------
!macro tmsSpritePosXYReg .ind {
        
        ; sprite attr table
        +tmsSetAddrSpriteAttrTable .ind

        +tmsPutY 
        +tmsPutX
}


; -----------------------------------------------------------------------------
; tmsSetAddrSpriteIndex: Change a sprite index
; -----------------------------------------------------------------------------
!macro tmsSetAddrSpriteIndex .ind {

        ; sprite attr table
        +tmsSetAddressWrite TMS_VRAM_SPRITE_ATTR_ADDRESS + (.ind * 4) + 2
}

; -----------------------------------------------------------------------------
; tmsSpriteIndex: Change a sprite index
; -----------------------------------------------------------------------------
!macro tmsSpriteIndex .ind, .pattInd {

        +tmsSetAddrSpriteIndex .ind

        +tmsPut .pattInd
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
