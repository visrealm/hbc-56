# Troy's HBC-56 - Audio tests makefile
#
# Copyright (c) 2021 Troy Schrapel
#
# This code is licensed under the MIT license
#
# https://github.com/visrealm/hbc-56
#
#

ROOT_PATH=../../

default: mario

DISABLE_KERNEL_MODULES = LCD  

include $(ROOT_PATH)makefile

%: %.o
	$(HBC56EMU) --rom $<

clean:
	$(RM) *.o *.lmap
