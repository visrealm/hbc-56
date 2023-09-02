; 65(C)22 Timer - HBC-56
;
; Copyright (c) 2023 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;

MAX_TIMER_TICKS = ((1 << 16) - 1)

!macro setTimer1Ticks @timerTicks {

!if @timerTicks > MAX_TIMER_TICKS {
	!error "Attmpt to set timer 1 ticks to ", @timerTicks,".\n  Maximum ticks: ",MAX_TIMER_TICKS,"\n  Maximum period: ",65535000.0/HBC56_CLOCK_FREQ,"mS\n  Minimum frequency: (",(HBC56_CLOCK_FREQ/MAX_TIMER_TICKS)+1," Hz)"
}
!if @timerTicks < 1 {
	!error "Attmpt to set timer 1 ticks to ", @timerTicks,".\n  Minimum ticks: ",1,"\n  Minimum period: ",1000000.0/HBC56_CLOCK_FREQ,"uS\n  Maximum frequency: (",(HBC56_CLOCK_FREQ)," Hz)"
}
        lda #<@timerTicks
        sta VIA_IO_ADDR_T1C_L
        lda #>@timerTicks
        sta VIA_IO_ADDR_T1C_H
}

!macro setTimer2Ticks @timerTicks {

!if @timerTicks > MAX_TIMER_TICKS {
	!error "Attmpt to set timer 2 ticks to ", @timerTicks,".\n  Maximum ticks: ",MAX_TIMER_TICKS,"\n  Maximum period: ",65535000.0/HBC56_CLOCK_FREQ,"mS\n  Minimum frequency: (",(HBC56_CLOCK_FREQ/MAX_TIMER_TICKS)+1," Hz)"
}
!if @timerTicks < 1 {
	!error "Attmpt to set timer 2 ticks to ", @timerTicks,".\n  Minimum ticks: ",1,"\n  Minimum period: ",1000000.0/HBC56_CLOCK_FREQ,"uS\n  Maximum frequency: (",(HBC56_CLOCK_FREQ)," Hz)"
}
        lda #<@timerTicks
        sta VIA_IO_ADDR_T2C_L
        lda #>@timerTicks
        sta VIA_IO_ADDR_T2C_H
}


!macro timer1SetContinuousHz @freqHz {
        lda VIA_IO_ADDR_ACR
        and #$3f
        ora #$40
        sta VIA_IO_ADDR_ACR

        lda #$c0
        sta VIA_IO_ADDR_IER

@timerTicks = HBC56_CLOCK_FREQ / @freqHz
        +setTimer1Ticks @timerTicks
}

!macro timer1SetOneShotUs @microSec {
        lda VIA_IO_ADDR_ACR
        and #$3f
        sta VIA_IO_ADDR_ACR

        lda #$c0
        sta VIA_IO_ADDR_IER

@timerTicks = @microSec * HBC56_CLOCK_FREQ / 1000000.0
        +setTimer1Ticks @timerTicks
}

!macro timer1Stop {
        lda #$40
        sta VIA_IO_ADDR_IER
}

!macro timer2SetOneShotUs @microSec {
        lda VIA_IO_ADDR_ACR
        and #$df
        sta VIA_IO_ADDR_ACR

        lda #$a0
        sta VIA_IO_ADDR_IER

@timerTicks = @microSec * HBC56_CLOCK_FREQ / 1000000.0
        +setTimer2Ticks @timerTicks
}

!macro timer2Stop {
        lda #$20
        sta VIA_IO_ADDR_IER
}