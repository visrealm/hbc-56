# Troy's HBC-56 - LCD tests makefile
#
# Copyright (c) 2021 Troy Schrapel
#
# This code is licensed under the MIT license
#
# https://github.com/visrealm/hbc-56
#
#

ROOT_PATH=../../

default: lcdtype

include $(ROOT_PATH)makefile

%: %.o
	$(HBC56EMU) --lcd 12864 --keyboard --rom $<

clean:
	rm -f *.o *.lmap
