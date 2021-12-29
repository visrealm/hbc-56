/*
 * Troy's HBC-56 Emulator - memory device
 *
 * Copyright (c) 2021 Troy Schrapel
 *
 * This code is licensed under the MIT license
 *
 * https://github.com/visrealm/hbc-56/emulator
 *
 */

#include "memory_device.h"

#include <stdlib.h>
#include <string.h>

static void destroyMemoryDevice(HBC56Device*);
static uint8_t readMemoryDevice(HBC56Device*, uint16_t, uint8_t*, uint8_t);
static uint8_t writeMemoryDevice(HBC56Device*, uint16_t, uint8_t);

/* memory device data */
struct MemoryDevice
{
  uint32_t startAddr;
  uint32_t endAddr;
  uint8_t *data;
};
typedef struct MemoryDevice MemoryDevice;

/* Function:  createMemoryDevice
 * --------------------
 * create a ram or rom device for the given address range
 */
static HBC56Device createMemoryDevice(
  const char *name,
  uint32_t startAddr,
  uint32_t endAddr)
{
  HBC56Device device = createDevice(name);
  if (endAddr <= startAddr)
    return device;

  MemoryDevice* memoryDevice = (MemoryDevice*)malloc(sizeof(MemoryDevice));
  if (memoryDevice)
  {
    memoryDevice->startAddr = startAddr;
    memoryDevice->endAddr = endAddr;
    memoryDevice->data = malloc((size_t)(endAddr - startAddr));
    device.data = memoryDevice;
    device.destroyFn = &destroyMemoryDevice;
    device.readFn = &readMemoryDevice;
    device.writeFn = &writeMemoryDevice;
  }
  else
  {
    destroyDevice(&device);
  }

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
HBC56Device createRamDevice(uint32_t startAddr, uint32_t endAddr)
{
  return createMemoryDevice("RAM", startAddr, endAddr);
}

/* Function:  createRomDevice
 * --------------------
 * create a rom device for the given address range
 * contents must be of equal size
 */
HBC56Device createRomDevice(uint32_t startAddr, uint32_t endAddr, uint8_t* contents)
{
  HBC56Device device = createMemoryDevice("ROM", startAddr, endAddr);
  device.writeFn = NULL;
  MemoryDevice* romDevice = getMemoryDevice(&device);
  if (romDevice)
  {
    memcpy(romDevice->data, contents, (size_t)(endAddr - startAddr));
  }
  return device;
}

/* Function:  destroyMemoryDevice
 * --------------------
 * destroy/clean up the memory data structure
 */
static void destroyMemoryDevice(HBC56Device *device)
{
  MemoryDevice *memoryDevice = getMemoryDevice(device);
  if (memoryDevice)
  {
    free(memoryDevice->data);
  }
  free(memoryDevice);
  device->data = NULL;
}

/* Function:  readMemoryDevice
 * --------------------
 * read from the memory device
 */
static uint8_t readMemoryDevice(HBC56Device* device, uint16_t addr, uint8_t *val, uint8_t dbg)
{
  MemoryDevice* memoryDevice = getMemoryDevice(device);
  if (memoryDevice && val)
  {
    if (addr >= memoryDevice->startAddr &&
        addr < memoryDevice->endAddr)
    {
      *val = memoryDevice->data[addr - memoryDevice->startAddr];
      return 1;
    }
  }
  return 0;
}

/* Function:  writeMemoryDevice
 * --------------------
 * write to the memory device
 */
static uint8_t writeMemoryDevice(HBC56Device* device, uint16_t addr, uint8_t val)
{
  MemoryDevice* memoryDevice = getMemoryDevice(device);
  if (memoryDevice)
  {
    if (addr >= memoryDevice->startAddr &&
        addr < memoryDevice->endAddr)
    {
      memoryDevice->data[addr - memoryDevice->startAddr] = val;
      return 1;
    }
  }
  return 0;
}
