![image](https://github.com/user-attachments/assets/896f23bf-48d0-4c6e-b95f-55c444ad09dc)# 65C02 Card

The 65C02 card includes support for a CMOS 65C02. The HBC-56 is currently using a WDC65C02.

The card also includes a 65C22 VIA used for SPI and timer interrupts. PORTA of the VIA is free for general use.

It includes optional circuitry for a clock which eliminates the need for the clock card.

![New 65C02 CPU card](/img/hbc56_cpu_card.png)

## Revisions

### v1.1 (Untested)

* Fixed the reversed /W and /R outputs noted in the CPU card build video: https://youtu.be/EApdkxBf2yo?si=V3qGSmfu8k72LIok&t=504

### v1.0

Revision 1.0 of this board does has minor issues which will be recfified in v1.1:

* Reversed /R and /W
* Missing pull-up resistor on /NMI

### v0.2

* Dropped support for NMOS 6502

### v0.1

* Initial hand-wired version


## Videos

Video covering the high-level design, ordering, assembly, diagnosis and repair of the v1.0 card:

[![HBC-56: New 65C02 CPU card](https://img.visualrealmsoftware.com/youtube/thumb/EApdkxBf2yo?v=2)](https://www.youtube.com/watch?v=EApdkxBf2yo "HBC-56: New 65C02 CPU card")

## Thanks

Thanks to PCBWay for supporting this build.

[![PCBWay](/img/pcbway_sm.png)](https://www.pcbway.com/)
