/*
 * Troy's HBC-56 Emulator - NES device
 *
 * Copyright (c) 2021 Troy Schrapel
 *
 * This code is licensed under the MIT license
 *
 * https://github.com/visrealm/hbc-56/emulator
 *
 */

#ifndef _HBC56_NES_DEVICE_H_
#define _HBC56_NES_DEVICE_H_

#include "device.h"


/* Function:  createNESDevice
 * --------------------
 * create a nes device for the given address
 */
HBC56Device createNESDevice(uint16_t addr);


#endif