cmake_minimum_required(VERSION 3.22)

include(CheckSymbolExists)

project(Hbc56Emu C CXX)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

option(BUILD_SHARED_LIBS "Build using shared libraries" ON)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin/)
file(MAKE_DIRECTORY ${CMAKE_RUNTIME_OUTPUT_DIRECTORY})

if (DEFINED EMSCRIPTEN)
	set(BUILD_SHARED_LIBS OFF)
	add_definitions(-D__EMSCRIPTEN__=1)
	add_definitions(-DDEMANGLE_SUPPORT=1)
    set(USE_FLAGS "-s USE_SDL=2")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${USE_FLAGS}")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${USE_FLAGS}")
endif()	

include(CTest)

add_subdirectory(modules)
add_subdirectory(thirdparty)
add_subdirectory(src)

check_symbol_exists(fopen_s "stdio.h" HAVE_FOPEN_S)
if(HAVE_FOPEN_S)
    target_compile_definitions(Hbc56Emu PRIVATE -DHAVE_FOPEN_S)
endif()

if (DEFINED EMSCRIPTEN)
    set_target_properties(Hbc56Emu PROPERTIES LINK_FLAGS    "${CMAKE_EXE_LINKER_FLAGS} ${USE_FLAGS} --preload-file rom.bin --preload-file rom.bin.lmap --preload-file rom.bin.rpt --preload-file imgui.ini -O3 -sASSERTIONS -g3 -s DISABLE_DEPRECATED_FIND_EVENT_TARGET_BEHAVIOR=1 -s USE_SDL=2 -s INITIAL_MEMORY=64MB -s EXPORT_NAME='Module' -s EXPORTED_RUNTIME_METHODS=['ccall','cwrap'] --no-entry -s EXPORTED_FUNCTIONS=['_hbc56Audio','_hbc56Reset','_hbc56LoadRom','_hbc56LoadLabels','_hbc56LoadSource','_hbc56LoadLayout','_hbc56GetLayout','_hbc56PasteText','_hbc56ToggleDebugger','_hbc56DebugBreak','_hbc56DebugBreakOnInt','_hbc56DebugRun','_hbc56DebugStepInto','_hbc56DebugStepOver','_hbc56DebugStepOut','_main']")
	file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/wasm/imgui.ini DESTINATION ${CMAKE_RUNTIME_OUTPUT_DIRECTORY})
endif()	