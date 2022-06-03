# Troy's HBC-56 - Mandelbrot
#
# Copyright (c) 2022 Troy Schrapel
#
# This code is licensed under the MIT license
#
# https://github.com/visrealm/hbc-56
#
#

ROOT_PATH=../

default: mandelbrot_32_24

mandelbrot_32_24.o: DISABLE_KERNEL_MODULES = LCD

include $(ROOT_PATH)makefile

%: %.o
	$(HBC56EMU) --rom $<

clean:
	$(RM) *.o *.lmap
