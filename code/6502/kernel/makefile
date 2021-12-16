# Troy's HBC-56 - Kernel makefile
#
# Copyright (c) 2021 Troy Schrapel
#
# This code is licensed under the MIT license
#
# https://github.com/visrealm/hbc-56
#
#

ROOT_PATH:=../

include ../makefile

kernel.o: kernel.asm  \
          $(ROOT_PATH)kernel/*.asm \
	  $(ROOT_PATH)lib/**/*.asm \
	  $(ROOT_PATH)lib/**/*.inc \
	  $(ROOT_PATH)lib/*.asm \
	  $(ROOT_PATH)lib/*.inc
	$(ACME) -o $@ -l $@.lmap $<

default: kernel.o

.PHONY: clean default

clean:
	rm -f *.o *.lmap