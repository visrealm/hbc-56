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

#basic_lcd:	LCD_MODEL = 2004
basic_lcd:	DISABLE_KERNEL_MODULES += TMS9918

#DISABLE_KERNEL_MODULES += AY3891X

include $(ROOT_PATH)makefile

%: %.o
	$(HBC56EMU) --keyboard --rom $<

%lcd: %lcd.o
	$(HBC56EMU) --lcd $(LCD_MODEL) --keyboard --rom $<

clean:
	rm -f *.o *.lmap
