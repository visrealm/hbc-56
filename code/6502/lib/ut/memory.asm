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

!zone memcpy {

MEMCPY_DST = R0
MEMCPY_SRC = R1
MEMCPY_LEN = R2

; -----------------------------------------------------------------------------
; memcpy: Copy a fixed number of bytes from src to dest
; -----------------------------------------------------------------------------
; Inputs:
;	src: source address
;	dst: destination address
;	cnt: number of bytes
; -----------------------------------------------------------------------------
!macro memcpy dst, src, cnt {
!if cnt <= 8 {
	!for i, 0, cnt - 1 {
		lda src + i
		sta dst + i
	}
} else { !if cnt <= 255 {
	ldx #cnt
-
	dex
	lda src, x
	sta dst, x
	cpx #0
	bne -
} else {
	lda #<src
	sta MEMCPY_SRC
	lda #>src
	sta MEMCPY_SRC + 1

	lda #<dst
	sta MEMCPY_DST
	lda #>dst
	sta MEMCPY_DST + 1


		lda #<cnt
		sta MEMCPY_LEN
		lda #>cnt
		sta MEMCPY_LEN + 1
		jsr memcpyMultiPage
	}
}
}

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
	beq +
-
	dey
	lda (MEMCPY_SRC), Y
	sta (MEMCPY_DST), Y
	cpy #0
	bne -
+
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
	beq +
-
	dey
	lda (MEMCPY_SRC), Y
	sta MEMCPY_DST
	cpy #0
	bne -
+
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
	beq +
	inc MEMCPY_SRC + 1
	inc MEMCPY_DST + 1
	jmp -
+ ; remaining bytes
	ldx MEMCPY_LEN
	beq +
- ; X bytes
	lda (MEMCPY_SRC),y
	sta (MEMCPY_DST),y
	iny
	dex
	bne -
+
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
	beq +
	inc MEMCPY_SRC + 1
	jmp -
+ ; remaining bytes
	ldx MEMCPY_LEN
	beq +
- ; X bytes
	lda (MEMCPY_SRC),y
	sta MEMCPY_DST
	iny
	dex
	bne -
+
	rts
; -----------------------------------------------------------------------------



; -----------------------------------------------------------------------------
; memcpy: Copy a fixed number of bytes from src ram to dest port
; -----------------------------------------------------------------------------
; Inputs:
;	src: source address
;	dst: destination address
;	cnt: number of bytes
; -----------------------------------------------------------------------------
!macro memcpyPort dst, src, cnt {
	lda #<src
	sta MEMCPY_SRC
	lda #>src
	sta MEMCPY_SRC + 1

	lda #<dst
	sta MEMCPY_DST
	lda #>dst
	sta MEMCPY_DST + 1

	!if cnt <= 255 {
		ldy #<cnt					
		jsr memcpySinglePagePort
	} else {
		lda #<cnt
		sta MEMCPY_LEN
		lda #>cnt
		sta MEMCPY_LEN + 1
		jsr memcpyMultiPagePort
	}
}

} ; memcpy

!zone memset {

MEMSET_DST = R0
MEMSET_LEN = R1

; -----------------------------------------------------------------------------
; memset: Set a fixed number of bytes to a single value
; -----------------------------------------------------------------------------
; Inputs:
;	dst: destination address
;	val: the byte value
;	cnt: number of bytes
; -----------------------------------------------------------------------------
!macro memset dst, val, cnt {
!if cnt <= 8 {
	lda #val
	!for i, 0, cnt - 1 {
	sta dst + i
	}
} else if cnt <= 255 {
	ldx #cnt
	lda #val
-
	dex
	sta dst, x
	cpx #0
	bne -
} else {
	lda #<dst
	sta MEMSET_DST
	lda #>dst
	sta MEMSET_DST + 1
	lda #<cnt
	sta MEMSET_LEN
	lda #>cnt
	sta MEMSET_LEN + 1
	lda #val
	jsr memsetMultiPage
}

}


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
	beq +
-
	dey
	sta (MEMSET_DST), y
	cpy #0
	bne -
+
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
	bne +
	ldy MEMSET_LEN
	jmp memsetSinglePage
+ 
	ldy #0
- 
	sta (MEMSET_DST),y ; could unroll to any power of 2
	iny
	bne -
	dex
	beq +
	inc MEMSET_DST + 1
	jmp -
+ ; remaining bytes
	ldx MEMSET_LEN
	beq +
- ; X bytes
	sta (MEMSET_DST),y
	iny
	dex
	bne -
+
	rts

} ; memset
