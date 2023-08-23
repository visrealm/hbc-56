/*
 * Troy's HBC-56 Emulator - 65C22 (VIA) device
 *
 * Copyright (c) 2023 Troy Schrapel
 *
 * This code is licensed under the MIT license
 *
 * https://github.com/visrealm/hbc-56/emulator
 *
 */

#ifndef _HBC56_VIA_DEVICE_H_
#define _HBC56_VIA_DEVICE_H_

#include "device.h"

#ifdef __cplusplus
extern "C" {
#endif

/* Function:  create65C22ViaDevice
 * --------------------
 * create a 65C22 (VIA) device
 */
HBC56Device create65C22ViaDevice(uint16_t baseAddr, uint8_t irq);

/* Function:  readVia6522Reg
 * --------------------
 * read a regiter value directly from the 6522
 */
uint8_t readVia6522Reg(HBC56Device* device, uint8_t reg);


#ifdef __cplusplus
}
#endif


#endif