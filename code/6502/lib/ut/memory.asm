; 6502
;
; Memory subroutines and macros
;
; Copyright (c) 2020 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
;

UT_MEMORY_ASM_ = 1

MEMCPY_DST = $e9
MEMCPY_SRC = $eb
MEMCPY_LEN = $ed

; -----------------------------------------------------------------------------
; memcpySinglePage: Copy up to 255 bytes 
; -----------------------------------------------------------------------------
; Inputs:
;	MEMCPY_SRC: src address
;	MEMCPY_DST: dst address
;	Y:	bytes
; -----------------------------------------------------------------------------
memcpySinglePage:
	cpy #0
	beq .endMemcpySinglePage
-
	dey
	lda (MEMCPY_SRC), Y
	sta (MEMCPY_DST), Y
	cpy #0
	bne -
.endMemcpySinglePage:
	rts
; -----------------------------------------------------------------------------



; -----------------------------------------------------------------------------
; memcpySinglePagePort: Copy up to 255 bytes 
; -----------------------------------------------------------------------------
; Inputs:
;	MEMCPY_SRC: src address
;	MEMCPY_DST: dst address (port)
;	Y:	bytes
; -----------------------------------------------------------------------------
memcpySinglePagePort:
	cpy #0
	beq .endMemcpySinglePagePort
-
	dey
	lda (MEMCPY_SRC), Y
	sta MEMCPY_DST
	cpy #0
	bne -
.endMemcpySinglePagePort
	rts
; -----------------------------------------------------------------------------



; -----------------------------------------------------------------------------
; memcpyMultiPage: Copy an up to 2^15 bytes 
; -----------------------------------------------------------------------------
; Inputs:
;	MEMCPY_SRC: src address
;	MEMCPY_DST: dst address
;	MEMCPY_LEN: length
; -----------------------------------------------------------------------------
memcpyMultiPage:

!ifdef ALLOW_SELF_MODIFYING_CODE {
	lda MEMCPY_SRC
	sta .loadIns + 1
	lda MEMCPY_SRC + 1
	sta .loadIns + 2

	lda MEMCPY_DST
	sta .storeIns + 1
	lda MEMCPY_DST + 1
	sta .storeIns + 2

.loadIns:
	lda SELF_MODIFY_ADDR, Y
	
.storeIns:
	sta SELF_MODIFY_ADDR, Y
	dey
	bne .loadIns
	inc .loadIns + 2
	inc .storeIns + 2
	dex
	bne .loadIns
} else {
	ldy #0
	ldx MEMCPY_LEN + 1
- 
	lda (MEMCPY_SRC),y ; could unroll to any power of 2
	sta (MEMCPY_DST),y
	iny
	bne -
	dex
	beq .memcpyMultiPageRemaining
	inc MEMCPY_SRC + 1
	inc MEMCPY_DST + 1
	jmp -
.memcpyMultiPageRemaining ; remaining bytes
	ldx MEMCPY_LEN
	beq .memcpyMultiPageEnd
- ; X bytes
	lda (MEMCPY_SRC),y
	sta (MEMCPY_DST),y
	iny
	dex
	bne -
.memcpyMultiPageEnd
}

	rts
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; memcpyMultiPagePort: Copy an up to 2^15 bytes 
; -----------------------------------------------------------------------------
; Inputs:
;	MEMCPY_SRC: src address
;	MEMCPY_DST: dst address (port)
;	MEMCPY_LEN: length
; -----------------------------------------------------------------------------
memcpyMultiPagePort:

	ldy #0
	ldx MEMCPY_LEN + 1
- 
	lda (MEMCPY_SRC),y ; could unroll to any power of 2
	sta MEMCPY_DST
	iny
	bne -
	dex
	beq .memcpyMultiPagePortRemaining
	inc MEMCPY_SRC + 1
	jmp -
.memcpyMultiPagePortRemaining ; remaining bytes
	ldx MEMCPY_LEN
	beq .memcpyMultiPagePortEnd
- ; X bytes
	lda (MEMCPY_SRC),y
	sta MEMCPY_DST
	iny
	dex
	bne -
.memcpyMultiPagePortEnd
	rts
; -----------------------------------------------------------------------------


MEMSET_DST = $eb
MEMSET_LEN = $ed


; -----------------------------------------------------------------------------
; memsetSinglePage: set a block of memory data
; -----------------------------------------------------------------------------
; Inputs:
;	 A:	value to set
;	 MEMSET_DST: start address
;	 Y:	bytes
; -----------------------------------------------------------------------------
memsetSinglePage:
	cpy #0
	beq .doneCpy
-
	dey
	sta (MEMSET_DST), y
	cpy #0
	bne -
.doneCpy
	rts


; -----------------------------------------------------------------------------
; memsetMultiPage: set a block of memory data
; -----------------------------------------------------------------------------
; Inputs:
;	 A: value
;	 MEMSET_DST: start address
;	 MEMSET_LEN: length
; -----------------------------------------------------------------------------
memsetMultiPage:
	ldx MEMSET_LEN + 1
	bne .doneSet
	ldy MEMSET_LEN
	jmp memsetSinglePage
.doneSet
	ldy #0
- 
	sta (MEMSET_DST),y ; could unroll to any power of 2
	iny
	bne -
	dex
	beq .doneSet2
	inc MEMSET_DST + 1
	jmp -
.doneSet2 ; remaining bytes
	ldx MEMSET_LEN
	beq .doneSet3
- ; X bytes
	sta (MEMSET_DST),y
	iny
	dex
	bne -
.doneSet3
	rts
