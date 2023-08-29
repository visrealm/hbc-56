# Troy's HBC-56 - Q*Bert makefile
#
# Copyright (c) 2023 Troy Schrapel
#
# This code is licensed under the MIT license
#
# https://github.com/visrealm/hbc-56
#
#

ROOT_PATH=../

default: qbert

DISABLE_KERNEL_MODULES = LCD UART SFXMAN KEYBOARD

include $(ROOT_PATH)makefile

%: %.o
#	copy /Y $<* ..\..\..\emulator\wasm\roms
	$(HBC56EMU) --rom $<

clean:
	$(RM) *.o *.lmap```