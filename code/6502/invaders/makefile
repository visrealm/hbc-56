# Troy's HBC-56 - Invaders makefile
#
# Copyright (c) 2021 Troy Schrapel
#
# This code is licensed under the MIT license
#
# https://github.com/visrealm/hbc-56
#
#

ROOT_PATH=../

default: invaders

DISABLE_KERNEL_MODULES = LCD

include $(ROOT_PATH)makefile

%: %.o
	$(HBC56EMU) --rom $<

clean:
	rm -f *.o *.lmap