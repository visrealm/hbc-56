


add_executable (Hbc56Emu WIN32)

add_definitions(-DVR_6502_EMU_STATIC)


target_sources(Hbc56Emu PUBLIC hbc56emu.cpp hbc56emu.h PRIVATE audio.c debugger/debugger.cpp devices/6502_device.c devices/ay38910_device.c devices/device.c devices/keyboard_device.c devices/lcd_device.c devices/memory_device.c devices/nes_device.c devices/tms9918_device.c devices/uart_device.c devices/via_device.c)
target_include_directories(Hbc56Emu PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(Hbc56Emu vrEmu6502 vrEmu6522 vrEmuTms9918 vrEmuTms9918Util vrEmuLcd emu2149 SDL2 SDL2main imgui)
