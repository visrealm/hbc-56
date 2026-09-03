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


/* Which chip the VDP answers as, in ascending capability. Numerically identical to
 * pico9918_chip_t: a TMS9918A, an F18A, or a PICO9918.
 */
#define TMS9918_CHIP_TMS9918A 0
#define TMS9918_CHIP_F18A     1
#define TMS9918_CHIP_PICO9918 2


/* Function:  setTms9918Chip
 * --------------------
 * choose which chip the vdp answers as. call before creating the device.
 */
void setTms9918Chip(int chip);


/* Function:  getTms9918Chip
 * --------------------
 * which chip the vdp answers as. a change lands on the next reset.
 */
int getTms9918Chip(void);


/* Function:  tms9918ChipName
 * --------------------
 * the name of a chip, as --vdp spells it
 */
const char *tms9918ChipName(int chip);


/* Function:  tms9918ChipFromName
 * --------------------
 * parse a chip name ("tms9918a", "f18a", "pico9918"). -1 if it is none of them.
 */
int tms9918ChipFromName(const char *name);


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
uint8_t readTms9918Reg(HBC56Device* device, uint8_t reg);

/* Function:  writeTms9918Reg
 * --------------------
 * write a regiter value directly to the tms9918
 */
void writeTms9918Reg(HBC56Device* device, uint8_t reg, uint8_t value);


/* Function:  getTms9918Mode
 * --------------------
 * return tms9918 display mode (pico9918_mode_t)
 */
int getTms9918Mode(HBC56Device* device);


#ifdef __cplusplus
}
#endif

#endif