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

KERNEL_DEFINES = $(foreach d, $(DISABLE_KERNEL_MODULES),-DHBC56_DISABLE_$(d)=1) -DLCD_MODEL=$(LCD_MODEL)

CONF:= hbc_$(LCD_MODEL)$(DISABLE_KERNEL_MODULES)
null:=
space:= $(null) #
CONFID:= $(subst $(space),_,$(strip $(CONF))).conf

$(CONFID):
	rm -f *.conf
	echo $(CONF) > $(CONFID)

kernel.o: kernel.asm  \
          $(ROOT_PATH)kernel/*.asm \
	  $(ROOT_PATH)lib/**/*.asm \
	  $(ROOT_PATH)lib/**/*.inc \
	  $(ROOT_PATH)lib/*.asm \
	  $(ROOT_PATH)lib/*.inc \
	  $(ROOT_PATH)kernel/makefile \
	  $(ROOT_PATH)makefile \
	  $(CONFID)
	$(ACME) $(KERNEL_DEFINES) -o $@ -l $@.lmap $<

default: kernel.o

.PHONY: clean default

clean:
	rm -f *.o *.lmap