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

lcdtype: LCD_MODEL = 12864

#DISABLE_KERNEL_MODULES = TMS9918

include $(ROOT_PATH)makefile

%: %.o
	$(HBC56EMU) --lcd $(LCD_MODEL) --rom $<

clean:
	$(RM) *.o *.lmap

all: lcd12864tilemap lcd12864text lcd12864gfx lcd12864gallery