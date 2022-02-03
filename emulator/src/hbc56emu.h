/*
 * Troy's HBC-56 Emulator
 *
 * Copyright (c) 2021 Troy Schrapel
 *
 * This code is licensed under the MIT license
 *
 * https://github.com/visrealm/hbc-56/emulator
 *
 */

#ifndef _HBC56_EMU_H_
#define _HBC56_EMU_H_

#include "devices/device.h"
#include "config.h"

#include <stddef.h>


/* Function:  hbc56Reset
 * --------------------
 * hardware reset the hbc-56
 */
void hbc56Reset();

/* Function:  hbc56NumDevices
 * --------------------
 * return the number of devices present
 */
int hbc56NumDevices();

/* Function:  hbc56Device
 * --------------------
 * return a pointer to the given device
 */
HBC56Device *hbc56Device(size_t deviceNum);

/* Function:  hbc56AddDevice
 * --------------------
 * add a new device
 * returns a pointer to the added device
 */
HBC56Device *hbc56AddDevice(HBC56Device device);

/* Function:  hbc56Interrupt
 * --------------------
 * raise or release an interrupt (irq# and signal)
 */
void hbc56Interrupt(uint8_t irq, HBC56InterruptSignal signal);

/* Function:  hbc56LoadRom
 * --------------------
 * load rom data. rom data bust be HBC56_ROM_SIZE bytes
 */
int hbc56LoadRom(const uint8_t *romData, int romDataSize);

/* Function:  hbc56LoadLabels
 * --------------------
 * load labels. labelFileContents is a null terminated string (lmap file contents)
 */
void hbc56LoadLabels(const char *labelFileContents);

/* Function:  hbc56ToggleDebugger
 * --------------------
 * toggle the debugger
 */
void hbc56ToggleDebugger();

/* Function:  hbc56DebugBreak
 * --------------------
 * break
 */
void hbc56DebugBreak();

/* Function:  hbc56DebugRun
 * --------------------
 * run / continue
 */
void hbc56DebugRun();

/* Function:  hbc56DebugStepInto
 * --------------------
 * step in
 */
void hbc56DebugStepInto();

/* Function:  hbc56DebugStepOver
 * --------------------
 * step over
 */
void hbc56DebugStepOver();

/* Function:  hbc56DebugStepOut
 * --------------------
 * step out
 */
void hbc56DebugStepOut();

/* Function:  hbc56DebugBreakOnInt
 * --------------------
 * break on interrupt
 */
void hbc56DebugBreakOnInt();


#endif