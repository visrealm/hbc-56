# 6502 source code

* **`kernel`** - The HBC-56 Kernel (Uses the top 6KB of ROM and is included in all HBC-56 ROM images)
* **`lib`** - Library subroutines and macros for the HBC-56 hardware (used by the kernel)
* **`basic`** - An implementation of EhBASIC for the HBC-56
* **`tests`** - Various tests/demos which can be run in the emulator
* **`invaders`** - An invaders clone (work in progress)

## Running the demos
1. Ensure [MAKE](http://gnuwin32.sourceforge.net/packages/make.htm) is available on your system and in your PATH
2. For each path (basic, invaders, tests\tms, tests\sfx):
 * Open a console to the path
 * Type `make` (this will build the default program and run it in the emulator:

  <img src="/img/make.png" alt="Make the demos" width="640px">

 * Type `make all` to build and run all demos in the directory
 * Type `make <basefile>` (filename without extension) to build and run a specific demo eg:
 
```
cd code\6502\tests\tms
make tms9918gfx2test
```

<img src="https://raw.githubusercontent.com/visrealm/vrEmuTms9918/main/res/mode2demo.gif" alt="HBC-56 Emulator" width="800px">

#### Manually building a demo
Example: invaders
```
cd invaders
..\..\..\tools\acme\bin\acme -I ..\lib -I ..\kernel -o invaders.o -l invaders.o.lmap invaders.asm
```
#### Manually running a demo
Example: invaders
```
cd invaders
..\..\..\emulator\bin\Hbc56Emu.exe --rom invaders.o
```
Example: basic
```
cd basic
..\..\..\emulator\bin\Hbc56Emu.exe --rom hbc56_mon.o
```
