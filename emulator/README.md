

# HBC-56 Emulator

The HBC-56 emulator allows you to build and test programs on your desktop machine. The source source be platform independent, however I have only built and tested the emulator on Windows.

<p align="center"><img src="https://raw.githubusercontent.com/visrealm/vrEmuTms9918/main/res/mode1demo.gif" alt="HBC-56 Emulator" width="800px"></p>

## Building the emulator

The repository does include a pre-built Windows executable located in `emulator/bin`. However, if you wish to modify and build the emulator, you can.
1. Ensure you have checked out the source including all submodules. 
2. Open `emulator/msvc/Hbc56Emu.sln` in Visual Studio.
  Unless you are debugging, it is preferred to build the Release version. The Release version is used by all of the code samples to launch after the sample is assembled.
3. Build the solution.

The output executable will be located at  `emulator/bin`

## Command-line options

The emulator supports the following command-line options:

* **`--rom <romfile>`** The ROM to load. The ROM is expected to be 32KB in size to match the physical machine.
* **`--keyboard`** Allows keyboard input. (The default is NES controller)
* **`--brk`** Start with the debugger in 'break' mode. Allows debugging from the first instruction.
* **`--lcd <lcdmodel>`** Enables the character LCD model. 
 `<lcdmodel>` can be one of: 
  * **`1602`**  - 16 x 2 Character LCD
  * **`2004`**  - 20 x 4 Character LCD
  * **`12864`** - 128 x 64 Graphics LCD (Also works as a 16 x 4 character LCD with 8x16 glyphs).
  See [12864B Datasheet](https://www.exploreembedded.com/wiki/images/7/77/QC12864B.pdf)
<p align="center"><img src="https://visrealm.github.io/hbc-56/img/emu_glcd.png" alt="HBC-56 Emulator LCD Window" width="594px"></p>

## NES controller key mapping
* **`<Arrow keys>`** - Directional pad (DPAD)
* **`<Shift>`** - A button
* **`<Ctrl>`** - B button
* **`<Tab>`** - Select button
* **`<Space>`** - Start button

## Debugger

The emulator includes a debugger you can use to step through your code. The debugger is controlled as follows:
* **`<Ctrl>+D`** - Toggle debug window
* **`F12`** - Break execution
* **`F10`** - Step over
* **`F11`** - Step into (jmp)
* **`F5`**  - Continue/run
* **`<PgUp>`** - Scroll RAM view up 0x64
* **`<Shift>+<PgUp>`** - Scroll RAM view up 0x1000
* **`<PgDn>`** - Scroll RAM view down 0x64
* **`<Shift>+<PgDn>`** - Scroll RAM view down 0x1000
* **`<Ctrl>+<PgUp>`** - Scroll TMS VRAM view up 0x64
* **`<Ctrl>+<Shift>+<PgUp>`** - Scroll TMS VRAM view up 0x1000
* **`<Ctrl>+<PgDn>`** - Scroll TMS VRAM view down 0x64
* **`<Ctrl>+<Shift>+<PgDn>`** - Scroll TMS VRAM view down 0x1000

#### Breakpoints
At this stage, the only way to set a breakpoint is to insert a special opcode (`$db`) in to your ROM image. When the emulator sees this opcode, it will break and open the debug window. eg:
```
!byte $db
```

#### Labels

If the emulator finds a `<romfile>.lmap` file (eg. myrom.o.lmap) it will load this and provide labels in the disassembly view.
