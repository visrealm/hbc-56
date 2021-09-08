/*
 * Troy's HBC-56 Emulator - Clock module
 *
 * Copyright (c) 2021 Troy Schrapel
 *
 * This code is licensed under the MIT license
 *
 * https://github.com/visrealm/hbc-56/emulator
 *
 */

#include "SDL_config.h"

 /* PRIVATE DATA STRUCTURE
 * ---------------------------------------- */
struct vrClock_s;
typedef struct vrClock_s VrClock;

/* PUBLIC INTERFACE
 * ---------------------------------------- */

 /* Function:  vrClockNew
  * --------------------
  * create a new clock
  */
VrClock* vrClockNew();

/* Function:  vrClockDestroy
 * --------------------
 * destroy a clock
 */
void vrClockDestroy(VrClock* clock);

