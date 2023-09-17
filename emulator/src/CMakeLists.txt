


file(GLOB_RECURSE SRC_DEVICES
    "${CMAKE_CURRENT_SOURCE_DIR}/devices/*.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/devices/*.h"
)
file(GLOB_RECURSE SRC_DEBUGGER
    "${CMAKE_CURRENT_SOURCE_DIR}/debugger/*.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/debugger/*.h"
)

source_group ("debugger" FILES ${SRC_DEBUGGER})
source_group ("devices" FILES ${SRC_DEVICES})		  

add_executable (Hbc56Emu WIN32 ${SRC_DEBUGGER} ${SRC_DEVICES})

add_definitions(-DVR_6502_EMU_STATIC)

target_sources(Hbc56Emu
  PUBLIC hbc56emu.h
  PRIVATE hbc56emu.cpp
          audio.c
          audio.h  
          config.h)

if (WIN32)
  target_sources(Hbc56Emu PRIVATE Hbc56Emu.rc)
endif()

target_include_directories(Hbc56Emu PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

target_link_libraries(Hbc56Emu vrEmu6502 vrEmu6522 vrEmuTms9918 vrEmuTms9918Util vrEmuLcd emu2149 SDL2 imgui)

if (NOT DEFINED EMSCRIPTEN)
	target_link_libraries(Hbc56Emu SDL2main)
endif()
