# Troy's HBC-56 - Breakout makefile
#
# Copyright (c) 2022 Troy Schrapel
#
# This code is licensed under the MIT license
#
# https://github.com/visrealm/hbc-56
#
#

ROOT_PATH=../

default: breakout

#DISABLE_KERNEL_MODULES = LCD

include $(ROOT_PATH)makefile

%: %.o
	copy /Y $<* ..\..\..\emulator\wasm\roms
	$(HBC56EMU) --rom $<

clean:
	$(RM) *.o *.lmap