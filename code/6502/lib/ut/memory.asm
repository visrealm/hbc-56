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

!src "ut/memory.inc"


!ifndef MEMORY_ZP_START { MEMORY_ZP_START = $48
        !warn "MEMORY_ZP_START not provided. Defaulting to ", MEMORY_ZP_START
}

; -------------------------
; Zero page
; -------------------------
MEM_DST	= MEMORY_ZP_START
MEM_SRC	= MEMORY_ZP_START + 2
MEM_LEN	= MEMORY_ZP_START + 4
MEMORY_ZP_SIZE	= 6


!if MEMORY_ZP_END < (MEMORY_ZP_START + MEMORY_ZP_SIZE) {
	!error "MEMORY_ZP requires ",MEMORY_ZP_SIZE," bytes. Allocated ",MEMORY_ZP_END - MEMORY_ZP_START
}

; -----------------------------------------------------------------------------
; memcpySinglePage: Copy up to 255 bytes 
; -----------------------------------------------------------------------------
; Inputs:
;	MEM_SRC: src address
;	MEM_DST: dst address
;	Y:	bytes
; -----------------------------------------------------------------------------
memcpySinglePage:
	cpy #0
	beq .endMemcpySinglePage
-
	dey
	lda (MEM_SRC), Y
	sta (MEM_DST), Y
	cpy #0
	bne -
.endMemcpySinglePage:
	rts
; -----------------------------------------------------------------------------



; -----------------------------------------------------------------------------
; memcpySinglePagePort: Copy up to 255 bytes 
; -----------------------------------------------------------------------------
; Inputs:
;	MEM_SRC: src address
;	MEM_DST: dst address (port)
;	Y:	bytes
; -----------------------------------------------------------------------------
memcpySinglePagePort:
	cpy #0
	beq .endMemcpySinglePagePort
-
	dey
	lda (MEM_SRC), Y
	sta MEM_DST
	cpy #0
	bne -
.endMemcpySinglePagePort
	rts
; -----------------------------------------------------------------------------



; -----------------------------------------------------------------------------
; memcpyMultiPage: Copy an up to 2^15 bytes 
; -----------------------------------------------------------------------------
; Inputs:
;	MEM_SRC: src address
;	MEM_DST: dst address
;	MEM_LEN: length
; -----------------------------------------------------------------------------
memcpyMultiPage:

!ifdef ALLOW_SELF_MODIFYING_CODE {
	lda MEM_SRC
	sta .loadIns + 1
	lda MEM_SRC + 1
	sta .loadIns + 2

	lda MEM_DST
	sta .storeIns + 1
	lda MEM_DST + 1
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
	ldx MEM_LEN + 1
- 
	lda (MEM_SRC),y ; could unroll to any power of 2
	sta (MEM_DST),y
	iny
	bne -
	dex
	beq .memcpyMultiPageRemaining
	inc MEM_SRC + 1
	inc MEM_DST + 1
	jmp -
.memcpyMultiPageRemaining ; remaining bytes
	ldx MEM_LEN
	beq .memcpyMultiPageEnd
- ; X bytes
	lda (MEM_SRC),y
	sta (MEM_DST),y
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
;	MEM_SRC: src address
;	MEM_DST: dst address (port)
;	MEM_LEN: length
; -----------------------------------------------------------------------------
memcpyMultiPagePort:

	ldy #0
	ldx MEM_LEN + 1
- 
	lda (MEM_SRC),y ; could unroll to any power of 2
	sta MEM_DST
	iny
	bne -
	dex
	beq .memcpyMultiPagePortRemaining
	inc MEM_SRC + 1
	jmp -
.memcpyMultiPagePortRemaining ; remaining bytes
	ldx MEM_LEN
	beq .memcpyMultiPagePortEnd
- ; X bytes
	lda (MEM_SRC),y
	sta MEM_DST
	iny
	dex
	bne -
.memcpyMultiPagePortEnd
	rts
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; memsetSinglePage: set a block of memory data
; -----------------------------------------------------------------------------
; Inputs:
;	 A:	value to set
;	 MEM_DST: start address
;	 Y:	bytes
; -----------------------------------------------------------------------------
memsetSinglePage:
	cpy #0
	beq .doneCpy
-
	dey
	sta (MEM_DST), y
	cpy #0
	bne -
.doneCpy
	rts


; -----------------------------------------------------------------------------
; memsetMultiPage: set a block of memory data
; -----------------------------------------------------------------------------
; Inputs:
;	 A: value
;	 MEM_DST: start address
;	 MEM_LEN: length
; -----------------------------------------------------------------------------
memsetMultiPage:
	ldx MEM_LEN + 1
	bne .doneSet
	ldy MEM_LEN
	jmp memsetSinglePage
.doneSet
	ldy #0
- 
	sta (MEM_DST),y ; could unroll to any power of 2
	iny
	bne -
	dex
	beq .doneSet2
	inc MEM_DST + 1
	jmp -
.doneSet2 ; remaining bytes
	ldx MEM_LEN
	beq .doneSet3
- ; X bytes
	sta (MEM_DST),y
	iny
	dex
	bne -
.doneSet3
	rts
