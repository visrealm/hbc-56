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
 * raise or release an interrupt
 */
void hbc56Interrupt(HBC56InterruptType type, HBC56InterruptSignal signal);


#endif