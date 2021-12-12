# HBC-56 Emulator

The HBC-56 emulator allows you to build and test programs on your desktop machine. The source source be platform independent, however I have only built and tested the emulator on Windows.

## Building the emulator

Ensure you have checked out the source including all submodules. Then open `emulator/msvc/Hbc56Emu.sln` in Visual Studio. Unless you are debugging, it is preferred to build the Release version. The Release version is used by all of the code samples to launch after the sample is assembled.

## Command-line options

The emulator supports the following command-line options:

* `--rom <romfile>` The ROM to load. THe ROM is expected to be 32KB is size to match the physical machine.
* `--keyboard` Allows keyboard input. (The default is NES controller)
* `--brk` Start with the debugger in 'break' mode. Allows debugging from the first instruction.
