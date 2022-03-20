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

#ifdef __cplusplus
extern "C" {
#endif

struct SDL_Renderer;
typedef struct SDL_Renderer SDL_Renderer;


/* Function:  createTms9918Device
 * --------------------
 * create a TMS9918 device
 */
HBC56Device createTms9918Device(uint16_t dataAddr, uint16_t regAddr, uint8_t irq, SDL_Renderer *renderer);


/* Function:  readTms9918Vram
 * --------------------
 * read a value directly from the tms9918 vram
 */
uint8_t readTms9918Vram(HBC56Device *device, uint16_t vramAddr);


/* Function:  readTms9918Reg
 * --------------------
 * read a regiter value directly from the tms9918
 */
uint8_t readTms9918Reg(HBC56Device *device, uint8_t reg);


#ifdef __cplusplus
}
#endif

#endif