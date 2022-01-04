PROJDIR=$(realpath $(CURDIR)/..)

CC=gcc
CFLAGS=-I.

ODIR=obj

SRC_DIRS=src \
	 src/debugger \
	 src/devices \
	 modules/ay38910 \
	 modules/cpu6502 \
	 modules/tms9918/src \
	 modules/lcd/src

INCLUDES = $(foreach dir, $(SRC_DIRS), $(addprefix -I, ../$(dir)))

EMU_FILES=src/window.c \
 	  src/hbc56emu.c \
	  src/audio.c \
	  src/debugger/debugger.c \
	  src/debugger/font.c \
	  src/devices/6502_device.c \
   	  src/devices/keyboard_device.c \
	  src/devices/nes_device.c \
	  src/devices/ay38910_device.c \
	  src/devices/lcd_device.c \
   	  src/devices/tms9918_device.c \
	  src/devices/device.c \
	  src/devices/memory_device.c

MODULE_FILES=modules/ay38910/emu2149.c \
	     modules/cpu6502/cpu6502.c \
	     modules/tms9918/src/tms9918_core.c \
	     modules/lcd/src/vrEmuLcd.c

MODULE_CFLAGS=-DVR_LCD_EMU_STATIC=1 \
	      -DVR_TMS9918_EMU_STATIC=1

# Define the function that will generate each rule
define generateRules
$(ODIR)/$(1)/%.o: $(PROJDIR)/$(1)/%.c
	@echo Building $$@
	mkdir -p $(ODIR)/$(1)
	$(CC) $$(MODULE_CFLAGS) $$(INCLUDES) `sdl2-config --cflags`  -c $$< -o $$@
endef

# Generate rules
$(foreach srcdir, $(SRC_DIRS), $(eval $(call generateRules,$(srcdir))))

_OBJ_FILES=$(EMU_FILES:.c=.o) $(MODULE_FILES:.c=.o)
OBJ_FILES=$(foreach f, $(_OBJ_FILES), $(addprefix $(ODIR)/, $(f)))

hbc56emu: $(OBJ_FILES)
	$(CC) `sdl2-config --libs` $(OBJ_FILES) -o hbc56emu