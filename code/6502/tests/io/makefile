# Troy's HBC-56 - IO tests makefile
#
# Copyright (c) 2022 Troy Schrapel
#
# This code is licensed under the MIT license
#
# https://github.com/visrealm/hbc-56
#
#

ROOT_PATH=../../

default: viatest

DISABLE_KERNEL_MODULES = 

include $(ROOT_PATH)makefile

%: %.o
	$(HBC56EMU) --rom $<

clean:
	$(RM) *.o *.lmap