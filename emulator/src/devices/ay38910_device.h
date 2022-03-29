/*
 * Troy's HBC-56 Emulator - AY-3-8910 device
 *
 * Copyright (c) 2021 Troy Schrapel
 *
 * This code is licensed under the MIT license
 *
 * https://github.com/visrealm/hbc-56/emulator
 *
 */

#ifndef _HBC56_AY38910_DEVICE_H_
#define _HBC56_AY38910_DEVICE_H_

#include "device.h"

#ifdef __cplusplus
extern "C" {
#endif

/* Function:  createAY38910Device
 * --------------------
 * create an AY-3-8910 PSG device
 */
HBC56Device createAY38910Device(uint16_t baseAddr, int clockFreq, int sampleRate, int channels);

#ifdef __cplusplus
}
#endif


#endif