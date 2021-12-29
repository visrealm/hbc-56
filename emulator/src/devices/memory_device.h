/*
 * Troy's HBC-56 Emulator - memory device
 *
 * Copyright (c) 2021 Troy Schrapel
 *
 * This code is licensed under the MIT license
 *
 * https://github.com/visrealm/hbc-56/emulator
 *
 */

#ifndef _HBC56_MEMORY_DEVICE_H_
#define _HBC56_MEMORY_DEVICE_H_

#include "device.h"


/* Function:  createRamDevice
 * --------------------
 * create a ram device for the given address range
 */
HBC56Device createRamDevice(uint32_t startAddr, uint32_t endAddr);

/* Function:  createRomDevice
 * --------------------
 * create a rom device for the given address range
 * contents must be of equal size
 */
HBC56Device createRomDevice(uint32_t startAddr, uint32_t endAddr, uint8_t *contents);


#endif