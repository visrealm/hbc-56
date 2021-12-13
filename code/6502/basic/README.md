# BASIC for the HBC-56

Here is a "port" of 6502 EhBASIC for the HBC-56. It includes a keyboard input driver and three output drivers:

* TMS9918
* Character LCD
* Graphics LCD

## Building and running

To run in the emulator (TMS9918 version) using MAKE:

```
cd code\6502\basic
make
```

<img src="/img/basic.gif" alt="BASIC" width="957px">

To build and run manually:

```
cd code\6502\basic
acme -I ..\lib -I ..\kernel -o basic_tms.o -l basic_tms.o.lmap basic_tms.asm
..\..\..\emulator\bin\Hbc56Emu.exe --keyboard --rom hbc56_mon.o
```

## Versions / drivers

There are two main asm files which jsut include the various components required for each build:
* basic_tms.asm  - the TMS9918 verion
* basic_lcd.asm  - the LCD version

####

The LCD version has two possible output drivers. One for a standard character LCD and another for a graphics LCD:

```assembly
; Troy's HBC-56 - BASIC (For LCD screen)
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;

!src "basic_hbc56_core.asm"             ; core basic

!src "input.asm"                        ; input routines
;!src "output_lcd.asm"                  ; output routines
!src "output_lcd_12864.asm"             ; output routines (graphics lcd)
```

Comment out the output driver you don't need
