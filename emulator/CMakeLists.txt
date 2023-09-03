cmake_minimum_required(VERSION 3.22)

project(Hbc56Emu C CXX)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

option(BUILD_SHARED_LIBS "Build using shared libraries" ON)

if (DEFINED EMSCRIPTEN)
	set(BUILD_SHARED_LIBS OFF)
	add_definitions(-D__EMSCRIPTEN__=1)
endif()

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin/)

include(CTest)

add_subdirectory(modules)
add_subdirectory(thirdparty)
add_subdirectory(src)
