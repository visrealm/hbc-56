/*
 * Troy's HBC-56 Emulator - TMS9918 device
 *
 * Copyright (c) 2021 Troy Schrapel
 *
 * This code is licensed under the MIT license
 *
 * https://github.com/visrealm/hbc-56/emulator
 *
 */

#ifndef _HBC56_TMS9918_DEVICE_H_
#define _HBC56_TMS9918_DEVICE_H_

#include "device.h"

struct SDL_Renderer;
typedef struct SDL_Renderer SDL_Renderer;


/* Function:  createTms9918Device
 * --------------------
 * create a TMS9918 device
 */
HBC56Device *createTms9918Device(uint16_t dataAddr, uint16_t regAddr, SDL_Renderer *renderer);


#endif