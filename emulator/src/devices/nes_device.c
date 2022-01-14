/*
 * Troy's HBC-56 Emulator - NES device
 *
 * Copyright (c) 2021 Troy Schrapel
 *
 * This code is licensed under the MIT license
 *
 * https://github.com/visrealm/hbc-56/emulator
 *
 */

#include "nes_device.h"

#include "SDL.h"

#include <string.h>

static uint8_t readNESDevice(HBC56Device*, uint16_t, uint8_t*, uint8_t);

/* nes device data */
struct NESDevice
{
  uint16_t  addr;
};
typedef struct NESDevice NESDevice;

/* nes constants */
#define NES_RIGHT  0b00000001
#define NES_LEFT   0b00000010
#define NES_DOWN   0b00000100
#define NES_UP     0b00001000
#define NES_START  0b00010000
#define NES_SELECT 0b00100000
#define NES_B      0b01000000
#define NES_A      0b10000000

/* Function:  createRamNESDevice
 * --------------------
 * create a ram or rom device for the given address range
 */
HBC56Device createNESDevice(
  uint16_t addr)
{
  HBC56Device device = createDevice("NES");
  NESDevice* nesDevice = (NESDevice*)malloc(sizeof(NESDevice));
  if (nesDevice)
  {
    memset(nesDevice, 0, sizeof(NESDevice));
    nesDevice->addr = addr;
    device.data = nesDevice;
    device.readFn = &readNESDevice;
  }
  else
  {
    destroyDevice(&device);
  }

  return device;
}

/* Function:  getNESDevice
 * --------------------
 * helper funtion to get private structure
 */
inline static NESDevice* getNESDevice(HBC56Device* device)
{
  if (!device) return NULL;
  return (NESDevice*)device->data;
}

/* Function:  readNESDevice
 * --------------------
 * read from the nes controller.
 */
static uint8_t readNESDevice(HBC56Device* device, uint16_t addr, uint8_t *val, uint8_t dbg)
{
  NESDevice* nesDevice = getNESDevice(device);
  if (nesDevice && val)
  {
    if (addr == nesDevice->addr)
    {
      *val = 0;

      const Uint8* keystate = SDL_GetKeyboardState(NULL);
      int isNumLockOff = (SDL_GetModState() & KMOD_NUM) == 0;

      //continuous-response keys
      if (keystate[SDL_SCANCODE_LEFT] || (keystate[SDL_SCANCODE_KP_4] && isNumLockOff))
      {
        *val |= NES_LEFT;
      }
      if (keystate[SDL_SCANCODE_RIGHT] || (keystate[SDL_SCANCODE_KP_6] && isNumLockOff))
      {
        *val |= NES_RIGHT;
      }
      if (keystate[SDL_SCANCODE_UP] || (keystate[SDL_SCANCODE_KP_8] && isNumLockOff))
      {
        *val |= NES_UP;
      }
      if (keystate[SDL_SCANCODE_DOWN] || (keystate[SDL_SCANCODE_KP_2] && isNumLockOff))
      {
        *val |= NES_DOWN;
      }
      if (keystate[SDL_SCANCODE_LCTRL] || keystate[SDL_SCANCODE_RCTRL] || keystate[SDL_SCANCODE_B])
      {
        *val |= NES_B;
      }
      if (keystate[SDL_SCANCODE_LSHIFT] || keystate[SDL_SCANCODE_RSHIFT] || keystate[SDL_SCANCODE_A])
      {
        *val |= NES_A;
      }
      if (keystate[SDL_SCANCODE_TAB])
      {
        *val |= NES_SELECT;
      }
      if (keystate[SDL_SCANCODE_SPACE] || keystate[SDL_SCANCODE_RETURN])
      {
        *val |= NES_START;
      }

      *val = ~*val;

      return 1;
    }
  }
  return 0;
}
