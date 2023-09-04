

# HBC-56 Emulator

The HBC-56 emulator allows you to build and test programs on your desktop machine. The emulator targets Windows, Linux and WebAssembly. The Windows build is the most mature.

<p align="center"><img src="https://raw.githubusercontent.com/visrealm/vrEmuTms9918/main/res/mode1demo.gif" alt="HBC-56 Emulator" width="800px"></p>

## Building the emulator

The HBC-56 uses the CMake build system.

1. Ensure you have checked out the source including all submodules. 
```
git clone --recurse-submodules https://github.com/visrealm/hbc-56.git
cd hbc-56
```
2. Setup the build
```
mkdir build
cd build
cmake ..
```
3. Build
```
cmake --build . --config Release
```

The output executable will be located at  `build/bin/Hbc56Emu`

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
<p align="center"><img src="../img/glcd_basic.gif" alt="HBC-56 Emulator LCD Window" width="588px"></p>

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
One way to set a breakpoint is to insert a special opcode (`$db`) in to your ROM image. When the emulator sees this opcode, it will break and open the debug window. eg:
```
!byte $db
```

#### Labels

If the emulator finds a `<romfile>.lmap` file (eg. myrom.o.lmap) it will load this and provide labels in the disassembly view.

#### Source debugging

When using the ACME assembler and you've generated an assembler report file, If the emulator finds a `<romfile>.o.rpt` file (eg. myrom.o.rpt) it will load this and provide full source debugging.
