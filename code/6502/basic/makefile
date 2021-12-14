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

include $(ROOT_PATH)makefile

%: %.o
	$(HBC56EMU) --keyboard --rom $<

%lcd: %lcd.o
	$(HBC56EMU) --lcd 12864  --keyboard --rom $<

all: basic_tms basic_lcd basic_glcd

clean:
	rm -f *.o *.lmap
