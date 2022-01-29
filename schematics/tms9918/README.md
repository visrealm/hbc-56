## TMS9918 Display Card

This TMS9918 display card is based on a [popular circuit](https://cdn.hackaday.io/files/5789247676576/9918-SRAM.pdf) to use SRAM with the TMS9918.

There are a couple of changes however:

* The 74LS574 (U5) I have replaced with a 74245 bus tranceiver.
* I'm not using the delay circuit. I do have it as an option, however haven't needed it.

## Emulator

The emulator includes full support for this TMS9918 card using my [vrEmuTms9918 emulator library](https://github.com/visrealm/vrEmuTms9918).
