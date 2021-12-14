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
ACME=acme -I $(ROOT_PATH)lib -I $(ROOT_PATH)kernel

# Every project should depend on the kernel
kernel: 
	$(MAKE) -C $(ROOT_PATH)kernel kernel.o

# Default compile task
%.o: %.asm kernel
	$(ACME) -o $@ -l $@.lmap $<

.PHONY: clean
