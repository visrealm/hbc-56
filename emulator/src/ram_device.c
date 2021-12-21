/*
 * Troy's HBC-56 Emulator - RAM/ROM device
 *
 * Copyright (c) 2021 Troy Schrapel
 *
 * This code is licensed under the MIT license
 *
 * https://github.com/visrealm/hbc-56/emulator
 *
 */

#include "ram_device.h"

#include <stdlib.h>
#include <string.h>


static void destroyRamRomDevice(HBC56Device*);
static uint8_t readRamRomDevice(HBC56Device*, uint16_t, uint8_t*, uint8_t);
static uint8_t writeRamRomDevice(HBC56Device*, uint16_t, uint8_t);


struct MemoryDevice
{
  uint16_t startAddr;
  uint16_t endAddr;
  uint8_t *data;
};
typedef struct MemoryDevice MemoryDevice;


/* Function:  createRamRomDevice
 * --------------------
 * create a ram or rom device for the given address range
 */
static HBC56Device* createRamRomDevice(
  const char *name,
  uint16_t startAddr,
  uint16_t endAddr)
{
  if (endAddr <= startAddr)
    return NULL;

  HBC56Device* device = createDevice(name);
  if (!device)
    return NULL;

  MemoryDevice* memoryDevice = (MemoryDevice*)malloc(sizeof(MemoryDevice));
  if (memoryDevice)
  {
    memoryDevice->startAddr = startAddr;
    memoryDevice->endAddr = endAddr;
    memoryDevice->data = malloc((size_t)(endAddr - startAddr) + 1);
    device->data = memoryDevice;
  }
  else
  {
    destroyDevice(device);
    return NULL;
  }

  device->destroyFn = &destroyRamRomDevice;
  device->readFn = &readRamRomDevice;
  device->writeFn = &writeRamRomDevice;

  return device;
}


/* Function:  getMemoryDevice
 * --------------------
 * helper funtion to get private structure
 */
inline static MemoryDevice* getMemoryDevice(HBC56Device* device)
{
  if (!device) return NULL;
  return (MemoryDevice*)device->data;
}



/* Function:  createRamDevice
 * --------------------
 * create a ram device for the given address range
 */
HBC56Device* createRamDevice(uint16_t startAddr, uint16_t endAddr)
{
  return createRamRomDevice("RAM", startAddr, endAddr);
}

/* Function:  createRomDevice
 * --------------------
 * create a rom device for the given address range
 * contents must be of equal size
 */
HBC56Device* createRomDevice(uint16_t startAddr, uint16_t endAddr, uint8_t* contents)
{
  HBC56Device *device = createRamRomDevice("ROM", startAddr, endAddr);
  if (device)
  {
    device->writeFn = NULL;
    MemoryDevice* romDevice = getMemoryDevice(device);
    if (romDevice)
    {
      memcpy(romDevice->data, contents, (size_t)(endAddr - startAddr) + 1);
    }
  }
  return device;
}


static void destroyRamRomDevice(HBC56Device *device)
{
  MemoryDevice *memoryDevice = getMemoryDevice(device);
  if (memoryDevice)
  {
    free(memoryDevice->data);
  }
  free(memoryDevice);
}

static uint8_t readRamRomDevice(HBC56Device* device, uint16_t addr, uint8_t *val, uint8_t dbg)
{
  MemoryDevice* memoryDevice = getMemoryDevice(device);
  if (memoryDevice && val)
  {
    if (addr >= memoryDevice->startAddr &&
        addr <= memoryDevice->endAddr)
    {
      *val = memoryDevice->data[addr - memoryDevice->startAddr];
      return 1;
    }
  }
  return 0;
}


static uint8_t writeRamRomDevice(HBC56Device* device, uint16_t addr, uint8_t val)
{
  MemoryDevice* memoryDevice = getMemoryDevice(device);
  if (memoryDevice)
  {
    if (addr >= memoryDevice->startAddr &&
        addr <= memoryDevice->endAddr)
    {
      memoryDevice->data[addr - memoryDevice->startAddr] = val;
      return 1;
    }
  }
  return 0;
}
