/*
 * Troy's HBC-56 Emulator - character lcd device
 *
 * Copyright (c) 2021 Troy Schrapel
 *
 * This code is licensed under the MIT license
 *
 * https://github.com/visrealm/hbc-56/emulator
 *
 */

#ifndef _HBC56_LCD_DEVICE_H_
#define _HBC56_LCD_DEVICE_H_

#include "device.h"

struct SDL_Renderer;
typedef struct SDL_Renderer SDL_Renderer;

typedef enum
{
  LCD_NONE,
  LCD_1602,
  LCD_2004,
  LCD_GRAPHICS
} LCDType;

/* Function:  createLcdDevice
 * --------------------
 * create a character LCD device
 */
HBC56Device createLcdDevice(LCDType type, uint16_t dataAddr, uint16_t cmdAddr, SDL_Renderer *renderer);


#endif