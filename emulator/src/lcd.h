/*
 * Troy's HBC-56 Emulator - LCD module
 *
 * Copyright (c) 2021 Troy Schrapel
 *
 * This code is licensed under the MIT license
 *
 * https://github.com/visrealm/hbc-56/emulator
 *
 */

#pragma once

#include "SDL.h"
#include "vrEmuLcd.h"

typedef struct
{
  SDL_Window *window;
  SDL_Renderer *renderer;
  SDL_Texture *tex;
  byte *frameBuffer;
  VrEmuLcd *lcd;
} LCDWindow;

typedef enum
{
  LCD_NONE,
  LCD_1602,
  LCD_2004,
  LCD_GRAPHICS
} LCDType;

LCDWindow *lcdWindowCreate(LCDType type);

void lcdWindowDestroy(LCDWindow *lcdw);

void lcdWindowUpdate(LCDWindow* lcdw);
