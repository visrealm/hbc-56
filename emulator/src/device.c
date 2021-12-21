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
HBC56Device* createDevice(const char* name)
{
  HBC56Device* device = (HBC56Device*)malloc(sizeof(HBC56Device));
  if (device)
  {
    device->name = name;
    device->resetFn = NULL;
    device->destroyFn = NULL;
    device->tickFn = NULL;
    device->readFn = NULL;
    device->writeFn = NULL;
    device->renderFn = NULL;
    device->output = NULL;
    device->data = NULL;
  }
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
    memset(device, 0, sizeof(HBC56Device));
    free(device);
  }
}
