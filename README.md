# hbc-56
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

All source code and schematics are available in this repository.

## Emulator
I have also included an emulator for this system. The emulator supports:
* Realtime execution of code (at 4MHz).
* Step through disassembled code with labels.
* Examine CPU and VDP registers, RAM and VRAM.
* Full support for all TMS9918A display modes. See my TMS9918 emulator here: https://github.com/visrealm/vrEmuTms9918
* Support for the dual AY-3-8910 audio.
 

<img src="https://raw.githubusercontent.com/visrealm/vrEmuTms9918/main/res/mode1demo.gif" alt="HBC-56 Emulator" width="1279px">

## Videos
[![Backplane 6502 + TMS9918: Invaders](https://img.visualrealmsoftware.com/youtube/thumb/Ug6Ppz-NF2Q)](https://www.youtube.com/watch?v=Ug6Ppz-NF2Q "Backplane 6502 + TMS9918: Invaders")

[![6502 8-bit homebrew with backplane. Troy's HBC-56 project preview.](https://img.visualrealmsoftware.com/youtube/thumb/x4IN8i7_U_4?t=3)](https://www.youtube.com/watch?v=x4IN8i7_U_4 "6502 8-bit homebrew with backplane. Troy's HBC-56 project preview.")

## License
This code is licensed under the [MIT](https://opensource.org/licenses/MIT "MIT") license
