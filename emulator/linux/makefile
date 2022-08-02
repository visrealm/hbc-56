CC = clang

CFLAGS = -lm -g -lstdc++ -lSDL2

VARS = -D DEMANGLE_SUPPORT=1 -D VR_LCD_EMU_STATIC=1 -D VR_TMS9918_EMU_STATIC=1 -D VR_6502_EMU_STATIC=1 -D HAVE_FOPEN_S -D __CLANG__

## user may need to change this to where their SDL2 includes files are located (you may need to install libsdl2-dev)
SDL2 = -I /usr/include/SDL2

INCLUDES = -I ../modules/ay38910 -I ../modules/65c02/src -I ../modules/lcd/src -I ../modules/tms9918/src -I ../thirdparty/imgui\
           -I ../thirdparty/imgui/backends

C_FILES = ../src/hbc56emu.cpp \
          ../src/audio.c \
          ../src/devices/device.c \
          ../src/devices/memory_device.c \
          ../src/devices/6502_device.c \
          ../src/devices/tms9918_device.c \
          ../src/devices/nes_device.c \
          ../src/devices/keyboard_device.c \
          ../src/devices/lcd_device.c \
          ../src/devices/ay38910_device.c \
          ../src/debugger/debugger.cpp \
          ../modules/ay38910/emu2149.c \
          ../modules/65c02/src/vrEmu6502.c \
          ../modules/lcd/src/vrEmuLcd.c \
          ../modules/tms9918/src/vrEmuTms9918.c \
          ../modules/tms9918/src/vrEmuTms9918Util.c \
          ../thirdparty/imgui/imgui.cpp \
          ../thirdparty/imgui/imgui_draw.cpp \
          ../thirdparty/imgui/imgui_tables.cpp\
          ../thirdparty/imgui/imgui_widgets.cpp \
          ../thirdparty/imgui/backends/imgui_impl_sdl.cpp\
          ../thirdparty/imgui/backends/imgui_impl_sdlrenderer.cpp

all:
	$(CC) $(VARS) $(SDL2) $(INCLUDES) $(C_FILES) -o hbc56 $(CFLAGS)
