:: HBC-56
:: 
:: Copyright (c) 2020 Troy Schrapel
:: 
:: This code is licensed under the MIT license
:: 
:: https://github.com/visrealm/VrEmuLcd
:: 
:: Pre-requisites:
:: This batch file must be run in an emscripten environment
:: eg. emsdk activate

emcc -o hbc56.html ^
  -O0 -sASSERTIONS -g3 ^
  -D __EMSCRIPTEN__ ^
  -D DEMANGLE_SUPPORT=1 ^
  -D VR_LCD_EMU_STATIC=1 ^
  -D VR_TMS9918_EMU_STATIC=1 ^
  -D VR_6502_EMU_STATIC=1 ^
  -s DISABLE_DEPRECATED_FIND_EVENT_TARGET_BEHAVIOR=1 ^
  -s USE_SDL=2 ^
  -s INITIAL_MEMORY=64MB ^
  -I ..\modules\ay38910 ^
  -I ..\modules\65c02\src ^
  -I ..\modules\lcd\src ^
  -I ..\modules\tms9918\src ^
  -I ..\thirdparty\imgui ^
  -I ..\thirdparty\imgui\backends ^
  ..\src\hbc56emu.cpp ^
  ..\src\audio.c ^
  ..\src\devices\device.c ^
  ..\src\devices\memory_device.c ^
  ..\src\devices\6502_device.c ^
  ..\src\devices\tms9918_device.c ^
  ..\src\devices\nes_device.c ^
  ..\src\devices\keyboard_device.c ^
  ..\src\devices\lcd_device.c ^
  ..\src\devices\ay38910_device.c ^
  ..\src\debugger\debugger.cpp ^
  ..\modules\ay38910\emu2149.c ^
  ..\modules\65c02\src\vrEmu6502.c ^
  ..\modules\lcd\src\vrEmuLcd.c ^
  ..\modules\tms9918\src\vrEmuTms9918.c ^
  ..\modules\tms9918\src\vrEmuTms9918Util.c ^
  ..\thirdparty\imgui\imgui.cpp ^
  ..\thirdparty\imgui\imgui_draw.cpp ^
  ..\thirdparty\imgui\imgui_tables.cpp ^
  ..\thirdparty\imgui\imgui_widgets.cpp ^
  ..\thirdparty\imgui\backends\imgui_impl_sdl.cpp ^
  ..\thirdparty\imgui\backends\imgui_impl_sdlrenderer.cpp ^
  --preload-file "rom.bin" ^
  --preload-file "rom.bin.lmap" ^
  --preload-file "rom.bin.rpt" ^
  --preload-file "imgui.ini" ^
  -s EXPORTED_FUNCTIONS="['_hbc56Audio','_hbc56Reset','_hbc56LoadRom','_hbc56LoadLabels','_hbc56LoadSource','_hbc56LoadLayout','_hbc56GetLayout','_hbc56PasteText','_hbc56ToggleDebugger','_hbc56DebugBreak','_hbc56DebugBreakOnInt','_hbc56DebugRun','_hbc56DebugStepInto','_hbc56DebugStepOver','_hbc56DebugStepOut','_main']" ^
  -s EXPORTED_RUNTIME_METHODS="['ccall','cwrap']"