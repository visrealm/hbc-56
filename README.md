# Troy's HBC-56
My Homebrew 8-bit Computer

<img src="img/repository.png" alt="HBC-56" width="640px">

A homebrew 8-bit computer with a backplane. Initially supporting the 6502 CPU, TMS9918A VDP and Dual AY-3-8910 PSG's. With plans to add support for Z80 and perhaps other CPUs in the future.

Current cards:
* 6502 CPU card
* Triple-mode clock card (based on James Sharman's design)
* RAM/ROM card (32KB of each)
* LCD display card (supports regulat character LCD and 12864B graphics LCD)
* TMS9918A display card (composite output)
* Dual AY-3-8910 sound card

Current breadboard circuits:
* NES controller
* PS/2 keyboard controller

All source code and schematics are available in this repository.

## Emulator
I have also included an emulator for this system. The emulator supports:

* Realtime execution of code (at 4MHz).
* Step through disassembled code with labels.
* Examine CPU and VDP registers, RAM and VRAM.
* Full support for all TMS9918A display modes. See my TMS9918 emulator here: https://github.com/visrealm/vrEmuTms9918
* Support for the dual AY-3-8910 audio.

The emulator is also available for Web (Beta). You can try a live instance here: https://visrealm.github.io/hbc-56/emulator/wasm You can load a new ROM by dragging the rom file on to the emulator.


Full details on the Emulator here: [github.com/visrealm/hbc-56/emulator](emulator)

## Running the demos
1. Ensure [MAKE](http://gnuwin32.sourceforge.net/packages/make.htm) is available on your system and in your PATH
2. Ensure [ACME assembler](https://sourceforge.net/projects/acme-crossass) is in your PATH
3. For each path (basic, invaders, tests\tms, tests\sfx):
 * Open a console to the path
 * Type `make` (this will build the default program and run it in the emulator:

  <img src="img/make.png" alt="Make the demos" width="640px">

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
cd code\6502\invaders
acme -I ..\lib -I ..\kernel -o invaders.o -l invaders.o.lmap invaders.asm
```
#### Manually running a demo
Example: invaders
```
cd code\6502\invaders
..\..\..\emulator\bin\Hbc56Emu.exe --rom invaders.o
```
Example: basic
```
cd code\6502\basic
..\..\..\emulator\bin\Hbc56Emu.exe --keyboard --rom hbc56_mon.o
```


## Memory map

THe HBC-56 has 64KB addressable memory divided into RAM, ROM and IO as follows:

| From | To | Purpose |
|--|--|--|
| $0000 | $7eff | RAM |
| $7f00 | $7fff | I/O |
| $8000 | $ffff | ROM |

The RAM and ROM is further divided by the HBC-56 Kernel:

| From | To | Size | Purpose |
|--|--|--|--|
| $0000 | $00ff | 256 bytes | Zero page |
| $0100 | $01ff | 256 bytes | Stack |
| $0200 | $79ff | 30 kilobytes | User RAM |
| $7a00 | $7eff | 1280 bytes | Kernel RAM |
| $7f00 | $7fff | 256 bytes | I/O |
| $8000 | $dfff | 24 kilobytes | User ROM |
| $e000 | $ffff | 8 kilobytes | Kernel ROM |


## Videos
[![Backplane 6502 + TMS9918: Invaders](https://img.visualrealmsoftware.com/youtube/thumb/Ug6Ppz-NF2Q)](https://www.youtube.com/watch?v=Ug6Ppz-NF2Q "Backplane 6502 + TMS9918: Invaders")

[![6502 8-bit homebrew with backplane. Troy's HBC-56 project preview.](https://img.visualrealmsoftware.com/youtube/thumb/x4IN8i7_U_4?t=3)](https://www.youtube.com/watch?v=x4IN8i7_U_4 "6502 8-bit homebrew with backplane. Troy's HBC-56 project preview.")

## License
This code is licensed under the [MIT](https://opensource.org/licenses/MIT "MIT") license
