# Troy's HBC-56 - Shared Makefile
#
# Copyright (c) 2021 Troy Schrapel
#
# This code is licensed under the MIT license
#
# https://github.com/visrealm/hbc-56
#
#
# Project makefiles should include this one, but first define
# ROOT_PATH to be this directory
#

# Command to run a project in the emulator
HBC56EMU=$(ROOT_PATH)../../emulator/bin/Hbc56Emu.exe

# Comile command
ACME=$(ROOT_PATH)../../tools/acme/bin/acme -I $(ROOT_PATH)lib -I $(ROOT_PATH)kernel

LCD_MODEL?=12864

RM = rm
#del /Q

export LCD_MODEL
export DISABLE_KERNEL_MODULES

# Every project should depend on the kernel
kernel:
	"$(MAKE)" -C $(ROOT_PATH)kernel kernel.o

# Default compile task
%.o: %.asm kernel makefile $(ROOT_PATH)makefile
	$(ACME) -o $@ -l $@.lmap -r $@.rpt $<
	more "$(ROOT_PATH)kernel/kernel.o.rpt" >> $@.rpt

# Hex compile task
%.hex: %.asm kernel makefile $(ROOT_PATH)makefile
	$(ACME) -f hex -o $@ -l $@.lmap -r $@.rpt $<

.PHONY: clean
