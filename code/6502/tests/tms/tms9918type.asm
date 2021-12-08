!src "kernel.inc"

TICKS     = $40
SECONDS_L = $41
SECONDS_H = $42
LAST_SECONDS = $43

onVSync:
        pha
        inc TICKS
        lda TICKS
        cmp #TMS_FPS
        bne +
        lda #0
        sta TICKS
        +inc16 SECONDS_L
+  
        jsr loop
        +tmsReadStatus
        pla      
        rti



main:
        sei
        lda #0
        sta TICKS
        sta SECONDS_L
        sta SECONDS_H

        jsr kbInit

        jsr tmsModeText

        +tmsSetAddrNameTable
        lda #' '
        ldx #(40 * 25 / 8)
        jsr _tmsSendX8

        +tmsSetColorFgBg TMS_LT_GREEN, TMS_BLACK
        +tmsEnableOutput
        cli

        +setIntHandler onVSync

        +tmsEnableInterrupts
-
        jmp -


loop:
        jsr tmsSetPosConsole
        lda TICKS
        cmp #30
        bcc +
        lda #' '
        +tmsPut
        jmp ++
+ 
        lda #$7f
        +tmsPut
++
        jsr kbReadAscii
        cmp #$ff
        beq .endLoop
        cmp #$0d ; enter
        bne +
        +tmsConsoleOut ' '
        lda #39
        sta TMS9918_CONSOLE_X
        jsr tmsIncPosConsole
        jmp .endLoop    
+
        cmp #$08 ; backspace
        bne ++
        +tmsConsoleOut ' '
        jsr tmsDecPosConsole
        jsr tmsDecPosConsole
        +tmsConsoleOut ' '
        jsr tmsDecPosConsole
        jmp .endLoop
++
        pha
        jsr tmsSetPosConsole
        pla
        +tmsPut
        jsr tmsIncPosConsole

.endLoop

        rts

medDelay:
	jsr delay
	jsr delay
	jsr delay
	jsr delay


delay:
	ldx #255
	ldy #255
-
	dex
	bne -
	ldx #255
	dey
	bne -
	rts

customDelay:
	ldx #255
-
	dex
	bne -
	ldx #255
	dey
	bne -
	rts
