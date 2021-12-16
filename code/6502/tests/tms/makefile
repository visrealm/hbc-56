# Troy's HBC-56 - TMS9918 tests makefile
#
# Copyright (c) 2021 Troy Schrapel
#
# This code is licensed under the MIT license
#
# https://github.com/visrealm/hbc-56
#
#

ROOT_PATH=../../

default: tms9918type

include $(ROOT_PATH)makefile

%: %.o
	$(HBC56EMU) --keyboard --rom $<

# override for NES controller
tms9918nes: tms9918nes.o
	$(HBC56EMU) --rom $<

all: tms9918type tms9918txttest tms9918nes tms9918mctest tms9918gfx2test

clean:
	rm -f *.o *.lmap