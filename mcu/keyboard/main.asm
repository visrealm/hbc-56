; PS/2 Keyboard Controller (for PIC16F627A)
;
; Troy's HBC-56 homebrew computer    
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56

PROCESSOR 16F627A

#include <xc.inc>

CONFIG  FOSC = HS             ; Oscillator Selection bits (HS oscillator: High-speed crystal/resonator on RA6/OSC2/CLKOUT and RA7/OSC1/CLKIN)
CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled)
CONFIG  PWRTE = OFF           ; Power-up Timer Enable bit (PWRT disabled)
CONFIG  MCLRE = ON            ; RA5/MCLR/VPP Pin Function Select bit (RA5/MCLR/VPP pin function is MCLR)
CONFIG  BOREN = OFF           ; Brown-out Detect Enable bit (BOD disabled)
CONFIG  LVP = OFF             ; Low-Voltage Programming Enable bit (RB4/PGM pin has digital I/O function, HV on MCLR must be used for programming)
CONFIG  CPD = OFF             ; Data EE Memory Code Protection bit (Data memory code protection off)
CONFIG  CP = OFF              ; Flash Program Memory Code Protection bit (Code protection off)

;                          PIC16F627A
;                            PINOUT
;                         +----------+
;     DAT_RDY (O) - RA2 ==| 1     18 |== RA1 - PS/2 DATA (I)
;        _INT (O) - RA3 ==| 2     17 |== RA0 - PS/2 DATA (I)
;              NC - RA4 ==| 3     16 |== RA7 - XTAL 1
;      _RESET (I) - RA5 ==| 4     15 |== RA6 - XTAL 2
;                   GND ==| 5     14 |== VCC
;   SCANCODE0 (O) - RB0 ==| 6     13 |== RB7 - SCANCODE7 (O)
;   SCANCODE1 (O) - RB1 ==| 7     12 |== RB6 - SCANCODE6 (O)
;   SCANCODE2 (O) - RB2 ==| 8     11 |== RB5 - SCANCODE5 (O)
;   SCANCODE3 (O) - RB3 ==| 9     10 |== RB4 - SCANCODE4 (O)
;                         +----------+
     
#define CLOCK_PIN	RA0
#define CLOCK_IO	TRISA0
#define DATA_PIN	RA1
#define DATA_IO		TRISA1
#define DAT_RDY_PIN	RA2
#define DAT_RDY_IO	TRISA2
#define _INT_PIN	RA3
#define _INT_IO		TRISA3

CPUFREQ		equ	20000000	    ; CPU frequency (20MHz)
DELAY_US_COUNT	equ	(CPUFREQ / 10000000)
BYTE_BITS	equ	8
BUFFER_BITS	equ	4		    ; 2^4 bytes in buffer
BUFFER_SIZE	equ	(1 << BUFFER_BITS)  ; (16)
BUFFER_MASK     equ	(BUFFER_SIZE - 1)   ; 0x0F
PS2_TEST_PASS	equ	0xAA

; ------------------------------------------------------------------------------
; udata - variables
; ------------------------------------------------------------------------------
PSECT udata
delay_us:	    ds 1
delay_us_counter:   ds 1    
buffer:		    ds BUFFER_SIZE	; circular buffer
bufferHead:	    ds 1		; circular buffer head pointer
bufferTail:	    ds 1		; circular buffer tail pointer
rxByteTmp:	    ds 1		; temporary storage for received byte
txByteTmp:	    ds 1		; temporary storage for sent byte
loopVar:	    ds 1		; looping variable
    
; ------------------------------------------------------------------------------
; bank0 - Switch to bank0 
; ------------------------------------------------------------------------------
bank0 macro
    bcf	    RP0	    ; we don't use bank 1/2, so only need to clear RP0
    bsf	    T0IE    ; enable interrupt
endm

; ------------------------------------------------------------------------------
; bank1 - Switch to bank1 
; ------------------------------------------------------------------------------
bank1 macro
    bcf	    T0IE    ; disable interrupt
    bsf	    RP0	    ; we don't use bank 1/2, so only need to set RP0
endm
    
; ------------------------------------------------------------------------------
; skipIfQueueNotEmpty - Skip the next instruction if the queue is not empty
; ------------------------------------------------------------------------------
skipIfQueueNotEmpty macro
    movf    bufferTail,w
    xorwf   bufferHead,w    ; xor rather than subtract to avoid setting carry
    btfsc   ZERO
endm
    
; ------------------------------------------------------------------------------
; clearOutput - Clear the output register
; ------------------------------------------------------------------------------
clearOutput macro
    clrf    PORTB
endm

; ------------------------------------------------------------------------------
; writeOutput - Write W to the output register
; ------------------------------------------------------------------------------
writeOutput macro
    movwf   PORTB
endm

; ------------------------------------------------------------------------------
; resetTimer
; ------------------------------------------------------------------------------
resetTimer macro
    bcf	    T0IF    ; Clear Timer0 interrupt flag
    clrf    TMR0    ; Set timer to 255 (one increment will trigger interrupt)
    decf    TMR0
endm

; ------------------------------------------------------------------------------
; skipIfOutputEmpty - Skip the next instruction if the output is empty
; ------------------------------------------------------------------------------
skipIfOutputEmpty macro
    movf    PORTB,w		    ; check current OE value
    btfss   ZERO		    ; if not zero
endm

    
PSECT resetVec,class=CODE,delta=2
; ------------------------------------------------------------------------------
; resetVec - entry point
; ------------------------------------------------------------------------------
resetVec:
    goto main

PSECT intVec,class=CODE,delta=2
; ------------------------------------------------------------------------------
; intVec - interrupt handler
; ------------------------------------------------------------------------------
intVec:
    bcf DAT_RDY_PIN		; clear data ready
    clearOutput 		; clear output
    
    ; set up timer again
    resetTimer
    retfie
  
PSECT code
; ------------------------------------------------------------------------------
; main - program entry
; ------------------------------------------------------------------------------
main:
    call    init		; initialise the registers
    call    waitForKbSelfTest	; wait for the keyboard

    resetTimer
    bsf	    GIE			; Global interrupt enable
    call    loop		; enter the main loop
    
; ------------------------------------------------------------------------------
; init - initialise the MCU registers
; ------------------------------------------------------------------------------
init:
    clrf    STATUS

    bank0
    clrf    PORTA	  ; Initialize GPIO by clearing output
    clrf    PORTB	  ; Initialize GPIO by clearing output
    bcf	    _INT_PIN	  ; Turn off interrupt out
    movlw   CMCON_CM_MASK ; Turn comparators off
    movwf   CMCON

    bank1
    bcf	    GIE		  ; Global interrupt disable    
    clrf    TRISA	  ; Initialize GPIO by setting all pins as output
    clrf    TRISB         ; Initialize GPIO by setting all pins as output

    bsf	    CLOCK_IO      ; set Clock as floating (input)
    bsf	    DATA_IO       ; set Data as floating (input)
    
    bsf	    RA4		  ; Timer0 clock pin (input)
    bsf	    RA5		  ; Reset pin (input)
    
    bsf	    T0CS	  ; Timer0 external clock mode (counter mode)
    bcf	    T0SE	  ; Timer0 increment on rising edge
    bcf	    T0IF	  ; Clear Timer0 interrupt flag
    bank0

    clrf    bufferHead	  ; clear variables
    clrf    bufferTail
    clrf    rxByteTmp
    clrf    txByteTmp
    
    return

; ------------------------------------------------------------------------------
; waitForKbSelfTest - Wait for Kb self test code and reply
; ------------------------------------------------------------------------------
; My Perixx PERIBOARD-409 releatedly sends 0xAA until a response is received
; from the host. This subroutine waits for 0xAA and sends a response.
; ------------------------------------------------------------------------------
waitForKbSelfTest:
    call    readByte		    ; read a byte into rxByteTmp
    movf    rxByteTmp,w
    xorlw   PS2_TEST_PASS	    ; Self-test pass?
    btfss   ZERO		    ; loop again if not zero
    goto    waitForKbSelfTest
    

    movlw   200
    call    delayUs
    
    call    pullClockUp		    ; initiate a send
    call    pullDataUp
    movlw   40
    call    delayUs
    call    pullClockDown
    movlw   200
    call    delayUs
    call    pullDataDown
    call    releaseClock  
    
    ; Note: due to my keyboard not sending clock signals??? we just wait
    ;       and return
    
    nop
    nop  
    call    pullDataUp
    movlw   180
    call    delayUs
    call    releaseData

    call    longDelay
    
    return


; ------------------------------------------------------------------------------
; loop - main program loop
; ------------------------------------------------------------------------------
loop:
    btfsc   DAT_RDY_PIN		    ; skip if data is ready... already
    goto    checkForKeyboardInput
    
    call    qPopFront		    ; get the received scancode
    btfsc   ZERO		    ; was queue empty?
    goto    checkForKeyboardInput
    
    writeOutput 		    ; output it
    
    bsf	    DAT_RDY_PIN		    ; data is now ready to be read

    skipIfQueueNotEmpty
    bsf	    _INT_PIN		    ; clear interrupt
    
checkForKeyboardInput:
    btfsc   CLOCK_PIN		    ; check if clock is low
    goto    loop		    ; if it's not, skip the read

    call    readByte
    call    qPushBack
  
dataIsReady:  
    bcf	    _INT_PIN		    ; Interrupt

    movlw   100
    call    delayUs

    goto loop
    
  
; ------------------------------------------------------------------------------
; qPushBack - Push data to end of queue
; ------------------------------------------------------------------------------
; Inputs: rxByteTmp - value to push
; ------------------------------------------------------------------------------
qPushBack:
    movlw   buffer		    ; set up FSR to buffer tail
    bcf	    CARRY
    addwf   bufferTail,w
    movwf   FSR

    movf    rxByteTmp,w		    ; write rxByteTmp to buffer
    movwf   INDF

    incf    bufferTail		    ; increment bufferTail pointer
    movlw   BUFFER_MASK		    ; roll around if pointer
    andwf   bufferTail,f            ; past end
    return
    
; ------------------------------------------------------------------------------
; qPopFront - Pop data from the front of the queue
; ------------------------------------------------------------------------------
; Returns: Value returned in W
;	   0 if queue is empty
; ------------------------------------------------------------------------------
qPopFront:
    clrw
    skipIfQueueNotEmpty		    ; return if queue is empty
    return    

    movlw   buffer		    ; set up FSR to buffer head
    bcf	    CARRY
    addwf   bufferHead,w
    movwf   FSR

    incf    bufferHead		    ; increment bufferHead pointer
    movlw   BUFFER_MASK		    ; roll around if pointer
    andwf   bufferHead,f	    ; past end

    movf    INDF,w		    ; output value to W
    return
    
; ------------------------------------------------------------------------------
; sendByte - send a byte of data over PS/2 interface
; ------------------------------------------------------------------------------
; Inputs: W - value to send
; ------------------------------------------------------------------------------
sendByte:
    movwf   txByteTmp		    ; set up temp value
    
    call    pullClockDown	    ; pull the clock line down
    movlw   25			    ; wait 100us
    call    delayUs
    call    pullDataDown
    call    releaseClock    
    nop
    nop  
    call    pullDataUp		    ; data high
    
    movlw   BYTE_BITS		    ; set up loop variable (8 bits)
    movwf   loopVar

sendBitLoop:			    ; send a bit
    rrf	rxByteTmp		    ; rotate the value to get bit 0 in CARRY
    
    call    waitForClockLow	    ; wait for clock low
    call    pullDataDown	    
    btfsc   CARRY		    ; skip if CARRY is 0
    call    pullDataUp
    call    waitForClockHigh    
    
    decfsz  loopVar		    ; next bit?
    goto    sendBitLoop
    call    releaseData
    return
    
; ------------------------------------------------------------------------------
; readByte - read a byte from the PS/2 interface
; ------------------------------------------------------------------------------
; Returns: rxByteTmp - value read
; ------------------------------------------------------------------------------
readByte:
    call    waitForClockLow ; read start bit
    clrf    rxByteTmp
    
    movlw   BYTE_BITS	    ; set up loop (8 bits)
    movwf   loopVar
    
    call    waitForClockHigh
readBitLoop:		    ; read a bit
    bcf	    CARRY           ; clear carry
    call    waitForClockLow 
    btfsc   DATA_PIN	    ; skip if DATA is 0
    bsf	    CARRY	    ; set CARRY (if data 1)
    call    waitForClockHigh
    
    rrf	    rxByteTmp	    ; rotate CARRY into temp value
    
    decfsz  loopVar	    ; next bit?
    goto    readBitLoop
    return
    
; ------------------------------------------------------------------------------
; waitForClockHigh - loops until the CLOCK input pin is high
; ------------------------------------------------------------------------------
waitForClockHigh:
    btfss   CLOCK_PIN
    goto    waitForClockHigh
    return
    
; ------------------------------------------------------------------------------
; waitForClockLow - loops until the CLOCK input pin is low
; ------------------------------------------------------------------------------
waitForClockLow:
    btfsc   CLOCK_PIN
    goto    waitForClockLow
    return
 
; ------------------------------------------------------------------------------
; pullClockDown - set the CLOCK pin to an output (value 0)
; ------------------------------------------------------------------------------
pullClockDown:
    bank1
    bcf	    CLOCK_IO
    bank0
    bcf	    CLOCK_PIN
    return
  
; ------------------------------------------------------------------------------
; pullClockUp - set the CLOCK pin to an input (floating/pulled high)
; ------------------------------------------------------------------------------
pullClockUp:
releaseClock:
    bank1
    bsf	    CLOCK_IO
    bank0
    return
    
; ------------------------------------------------------------------------------
; pullDataDown - set the DATA pin to an output (value 0)
; ------------------------------------------------------------------------------
pullDataDown:
    bank1
    bcf	    DATA_IO
    bank0
    bcf	    DATA_PIN
    return

; ------------------------------------------------------------------------------
; pullDataUp - set the DATA pin to an input (floating/pulled high)
; ------------------------------------------------------------------------------
pullDataUp:
releaseData:
    bank1
    bsf	    DATA_IO
    bank0
    return
 
; ------------------------------------------------------------------------------
; longDelay - a long delay...
; ------------------------------------------------------------------------------
longDelay:
    movlw   255
    call    delayUs
    movlw   255
    call    delayUs
    movlw   255
    call    delayUs
    movlw   255
    call    delayUs
    movlw   255
    call    delayUs
    return
  
; ------------------------------------------------------------------------------
; delayUs - delay a number of microseconds
; ------------------------------------------------------------------------------
; Inputs: W - number of microseconds
; ------------------------------------------------------------------------------
delayUs:
    movwf   delay_us
    
delayUs1:
    movlw   DELAY_US_COUNT
    movwf   delay_us_counter
    
delayUs2:
    decfsz  delay_us_counter,f
    goto    delayUs2
    decfsz  delay_us,f
    goto    delayUs1
    return
  
END resetVec