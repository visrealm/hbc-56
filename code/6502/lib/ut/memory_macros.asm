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

!macro setMemCpySrc .src {
	lda #<.src
	sta MEMCPY_SRC
	lda #>.src
	sta MEMCPY_SRC + 1
}

!macro setMemCpyDst .dst {
	lda #<.dst
	sta MEMCPY_DST
	lda #>.dst
	sta MEMCPY_DST + 1
}

!macro setMemCpySrcInd .srcRef {
	lda .srcRef
	sta MEMCPY_SRC
	lda .srcRef + 1
	sta MEMCPY_SRC + 1
}

!macro setMemCpyDstInd .dstRef {
	lda .dstRef
	sta MEMCPY_DST
	lda .dstRef + 1
	sta MEMCPY_DST + 1
}

!macro memcpySinglePage .bytes {
	ldy #.bytes
	jsr memcpySinglePage
}


; -----------------------------------------------------------------------------
; memcpyPort: Copy a fixed number of bytes from src ram to dest port
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

