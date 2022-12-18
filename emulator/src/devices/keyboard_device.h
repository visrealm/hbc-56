/*
 * Troy's HBC-56 Emulator - Keyboard device
 *
 * Copyright (c) 2021 Troy Schrapel
 *
 * This code is licensed under the MIT license
 *
 * https://github.com/visrealm/hbc-56/emulator
 *
 */

#ifndef _HBC56_KEYBOARD_DEVICE_H_
#define _HBC56_KEYBOARD_DEVICE_H_

#include "device.h"

#ifdef __cplusplus
extern "C" {
#endif

/* Function:  createKeyboardDevice
 * --------------------
 * create a keyboard device for the given address
 */
HBC56Device createKeyboardDevice(uint16_t addr, uint8_t irq);

bool keyboardDeviceQueueEmpty(HBC56Device* device);
int keyboardDeviceQueueCap(HBC56Device* device);

#ifdef __cplusplus
}
#endif

#endif