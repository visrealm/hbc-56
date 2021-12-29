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

#include "device.h"

#include <stdlib.h>
#include <string.h>

/* Function:  createDevice
 * --------------------
 * create an empty device. the starting point for all devices
 */
HBC56Device createDevice(const char* name)
{
  HBC56Device device;
  device.name = name;
  device.resetFn = NULL;
  device.destroyFn = NULL;
  device.tickFn = NULL;
  device.readFn = NULL;
  device.writeFn = NULL;
  device.renderFn = NULL;
  device.audioFn = NULL;
  device.eventFn = NULL;
  device.output = NULL;
  device.data = NULL;
  return device;
}

/* Function:  destroyDevice
 * --------------------
 * destroy a device
 */
void destroyDevice(HBC56Device* device)
{
  if (device)
  {
    if (device->destroyFn) device->destroyFn(device);
    if (device->data) free(device->data);
    memset(device, 0, sizeof(HBC56Device));
  }
}


/* Function:  resetDevice
 * --------------------
 * reset a device
 */
void resetDevice(HBC56Device* device)
{
  if (device && device->resetFn)
  {
    device->resetFn(device);
  }
}

/* Function:  tickDevice
 * --------------------
 * tick a device (for devices which require regular attention)
 */
void tickDevice(HBC56Device* device, uint32_t deltaTicks, double deltaTime)
{
  if (device && device->tickFn)
  {
    device->tickFn(device, deltaTicks, deltaTime);
  }
}

/* Function:  readDevice
 * --------------------
 * read from a device
 */
uint8_t readDevice(HBC56Device* device, uint16_t addr, uint8_t* val, uint8_t dbg)
{
  if (device && device->readFn)
  {
    return device->readFn(device, addr, val, dbg);
  }
  return 0;
}

/* Function:  writeDevice
 * --------------------
 * write to a device
 */
uint8_t writeDevice(HBC56Device* device, uint16_t addr, uint8_t val)
{
  if (device && device->writeFn)
  {
    return device->writeFn(device, addr, val);
  }
  return 0;
}

/* Function:  renderDevice
 * --------------------
 * render a device (if it has some form of display output)
 */
void renderDevice(HBC56Device* device)
{
  if (device && device->renderFn)
  {
    device->renderFn(device);
  }
}

/* Function:  renderAudioDevice
 * --------------------
 * render an audio device
 */
void renderAudioDevice(HBC56Device* device, float* buffer, int numSamples)
{
  if (device && device->audioFn)
  {
    device->audioFn(device, buffer, numSamples);
  }
}

/* Function:  eventDevice
 * --------------------
 * handle events
 */
void eventDevice(HBC56Device* device, SDL_Event* evt)
{
  if (device && device->eventFn)
  {
    device->eventFn(device, evt);
  }
}