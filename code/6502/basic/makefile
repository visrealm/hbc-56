# Troy's HBC-56 - BASIC makefile
#
# Copyright (c) 2021 Troy Schrapel
#
# This code is licensed under the MIT license
#
# https://github.com/visrealm/hbc-56
#
#

ROOT_PATH=../

default: basic_tms

#basic_lcd.o: DISABLE_KERNEL_MODULES = TMS9918
basic_tms.o: DISABLE_KERNEL_MODULES = LCD
basic_uart.o: DISABLE_KERNEL_MODULES = LCD

include $(ROOT_PATH)makefile

%: %.o
	copy /Y $<* ..\..\..\emulator\wasm\roms
	$(HBC56EMU) --rom $<

%lcd: %lcd.o
	copy /Y $<* ..\..\..\emulator\wasm\roms
	$(HBC56EMU) --lcd $(LCD_MODEL) --rom $<

clean:
	$(RM) *.o *.lmap
