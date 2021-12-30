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

emcc -o ..\bin\hbc56.html ^
  -O0 ^
  -D __EMSCRIPTEN__ ^
  -D VR_LCD_EMU_STATIC=1 ^
  -D VR_TMS9918_EMU_STATIC=1 ^
  -s USE_SDL=2 ^
  -s INITIAL_MEMORY=33554432 ^
  -I ..\modules\ay38910 ^
  -I ..\modules\cpu6502 ^
  -I ..\modules\lcd\src ^
  -I ..\modules\tms9918\src ^
  ..\src\hbc56emu.c ^
  ..\src\audio.c ^
  ..\src\window.c ^
  ..\src\devices\device.c ^
  ..\src\devices\memory_device.c ^
  ..\src\devices\6502_device.c ^
  ..\src\devices\tms9918_device.c ^
  ..\src\devices\nes_device.c ^
  ..\src\devices\keyboard_device.c ^
  ..\src\devices\lcd_device.c ^
  ..\src\devices\ay38910_device.c ^
  ..\src\debugger\debugger.c ^
  ..\src\debugger\font.c ^
  ..\modules\ay38910\emu2149.c ^
  ..\modules\cpu6502\addrmodes.c ^
  ..\modules\cpu6502\cpu6502.c ^
  ..\modules\cpu6502\opcodes.c ^
  ..\modules\lcd\src\vrEmuLcd.c ^
  ..\modules\tms9918\src\tms9918_core.c ^
  --preload-file "rom.bin" ^
  --preload-file "rom.bin.lmap" ^
  -s EXPORTED_FUNCTIONS="['_hbc56Audio','_main']" ^
  -s EXPORTED_RUNTIME_METHODS="['ccall','cwrap']"


#  -s EXPORT_NAME="'hbc56'" ^
