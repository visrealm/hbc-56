cmake_minimum_required(VERSION 3.22)

project(Hbc56)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

option(BUILD_SHARED_LIBS "Build using shared libraries" ON)

if (DEFINED EMSCRIPTEN)
	set(BUILD_SHARED_LIBS OFF)
	add_definitions(-D__EMSCRIPTEN__=1)
endif()

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin/)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE ${CMAKE_BINARY_DIR}/bin/)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG ${CMAKE_BINARY_DIR}/bin_debug/)

include(CTest)

add_subdirectory(emulator)

if (NOT DEFINED EMSCRIPTEN)
	add_subdirectory(tools/acme)
endif()

