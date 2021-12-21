/*
 * Troy's HBC-56 Emulator - Device API
 *
 * Copyright (c) 2021 Troy Schrapel
 *
 * This code is licensed under the MIT license
 *
 * https://github.com/visrealm/hbc-56/emulator
 *
 */

#ifndef _HBC56_DEVICE_H_
#define _HBC56_DEVICE_H_

#include <stdint.h>


struct HBC56Device;
typedef struct HBC56Device HBC56Device;

struct SDL_Texture;
typedef struct SDL_Texture SDL_Texture;

/* tick function pointer */
/*   uint32_t deltaTicks: change in clock ticks since last call */
/*   double   deltaTime:  change in elapsed time in seconds since last call */
typedef void (*DeviceTickFn)(HBC56Device*,uint32_t, double);

/* render function pointer */
typedef void (*DeviceRenderFn)(HBC56Device*);

/* reset function pointer */
typedef void (*DeviceResetFn)(HBC56Device*);

/* destroy function pointer */
typedef void (*DeviceDestroyFn)(HBC56Device*);

/* read function pointer   
     uint16_t addr:  address to read   
     uint8_t* value: value read   
     uint8_t  dbg:   1 if called from a debugger   
     returns 1 if ok, 0 if not */
typedef uint8_t (*DeviceReadFn)(HBC56Device*,uint16_t,uint8_t*,uint8_t);

/* write function pointer   
     uint16_t addr:  address to write   
     uint8_t  value: value to write   
     returns 1 if ok, 0 if not */
typedef uint8_t (*DeviceWriteFn)(HBC56Device*,uint16_t,uint8_t);

struct HBC56Device
{
  const char       *name;

  DeviceResetFn     resetFn;
  DeviceDestroyFn   destroyFn;
  DeviceTickFn      tickFn;
  DeviceReadFn      readFn;
  DeviceWriteFn     writeFn;
  DeviceRenderFn    renderFn;

  void             *data;

  SDL_Texture      *output;
}; 


/* Function:  createDevice
 * --------------------
 * create an empty device. the starting point for all devices
 */
HBC56Device* createDevice(const char *name);

/* Function:  destroyDevice
 * --------------------
 * destroy a device
 */
void destroyDevice(HBC56Device *device);

/* Function:  destroyDevice
 * --------------------
 * destroy a device
 */
void destroyDevice(HBC56Device* device);


#endif