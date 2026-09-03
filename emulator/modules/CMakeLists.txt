add_subdirectory(65c02)
add_subdirectory(65c22)
add_subdirectory(ay38910)
add_subdirectory(lcd)

# pico9918-core renders the VDP: the only VDP this emulator has. Built from the
# submodule as a static library; linking it carries the includes and build config.
if(NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/pico9918/CMakeLists.txt)
  message(FATAL_ERROR
    "pico9918-core is missing - run: git submodule update --init --recursive")
endif()

# MODE=1 is the F18A renderer and GPU; TEXT80_8BPP gives T80 ECM and the bitmap
# layer. Plain set() reaches the subproject's option() under CMP0077 NEW.
set(PICO9918_MODE 1)
set(PICO9918_TEXT80_8BPP ON)

# The chip personality is a runtime choice here, not a build one: one archive
# presents a TMS9918A, an F18A or a PICO9918 on request.
set(PICO9918_RUNTIME_CHIP ON)

# The library otherwise applies -march=native / /arch:AVX2 to published builds.
set(PICO9918_PORTABLE_CODEGEN ON)

add_subdirectory(pico9918)

# The library's version for the config block's stamp, read back out of the
# subproject's directory scope, where its project() set it.
foreach(part MAJOR MINOR PATCH)
  get_directory_property(HBC56_PICO9918_VER_${part}
      DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/pico9918
      DEFINITION pico9918_core_VERSION_${part})
  if(NOT DEFINED HBC56_PICO9918_VER_${part} OR HBC56_PICO9918_VER_${part} STREQUAL "")
    message(FATAL_ERROR
      "pico9918-core: could not read VERSION ${part} from its project(). The "
      "config block's version stamp gates the stored-settings migration, so "
      "an empty one cannot be built around.")
  endif()
  set(HBC56_PICO9918_VER_${part} ${HBC56_PICO9918_VER_${part}} PARENT_SCOPE)
endforeach()

message(STATUS "hbc56: PICO9918 VDP engine via pico9918-core "
               "${HBC56_PICO9918_VER_MAJOR}.${HBC56_PICO9918_VER_MINOR}.${HBC56_PICO9918_VER_PATCH}")
