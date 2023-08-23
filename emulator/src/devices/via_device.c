/*
 * Troy's HBC-56 Emulator - AY-3-8910 device
 *
 * Copyright (c) 2023 Troy Schrapel
 *
 * This code is licensed under the MIT license
 *
 * https://github.com/visrealm/hbc-56/emulator
 *
 */

#include "via_device.h"

#include "vrEmu6522.h"

#include "../hbc56emu.h"

#include <stdlib.h>
#include <string.h>
#include <math.h>


static void reset65C22ViaDevice(HBC56Device*);
static void destroy65C22ViaDevice(HBC56Device*);
static uint8_t read65C22ViaDevice(HBC56Device*, uint16_t, uint8_t*, uint8_t);
static uint8_t write65C22ViaDevice(HBC56Device*, uint16_t, uint8_t);
static void tick65C22ViaDevice(HBC56Device*, uint32_t, double);

struct ViaDevice
{
  uint16_t       baseAddr;
  VrEmu6522     *via;
  uint8_t        irq;
};
typedef struct ViaDevice ViaDevice;

 /* Function:  create65C22ViaDevice
  * --------------------
 * create an AY-3-8910 PSG device
  */
HBC56Device create65C22ViaDevice(uint16_t baseAddr, uint8_t irq)
{
  HBC56Device device = createDevice("65C22 VIA");
  ViaDevice* viaDevice = (ViaDevice*)malloc(sizeof(ViaDevice));
  if (viaDevice)
  {
    viaDevice->baseAddr = baseAddr;
    viaDevice->via = vrEmu6522New(VIA_65C22);
    viaDevice->irq = irq;

    device.data = viaDevice;

    device.resetFn = &reset65C22ViaDevice;
    device.destroyFn = &destroy65C22ViaDevice;
    device.readFn = &read65C22ViaDevice;
    device.writeFn = &write65C22ViaDevice;
    device.tickFn = &tick65C22ViaDevice;
  }
  else
  {
    destroyDevice(&device);
  }

  return device;
}


/* Function:  get65C22ViaDevice
 * --------------------
 * helper funtion to get private structure
 */
inline static ViaDevice* get65C22ViaDevice(HBC56Device* device)
{
  if (!device) return NULL;
  return (ViaDevice*)device->data;
}

static void reset65C22ViaDevice(HBC56Device* device)
{
  ViaDevice* viaDevice = get65C22ViaDevice(device);
  if (viaDevice)
  {
    vrEmu6522Reset(viaDevice->via);
  }
}

static void destroy65C22ViaDevice(HBC56Device *device)
{
  ViaDevice *viaDevice = get65C22ViaDevice(device);
  if (viaDevice)
  {
    vrEmu6522Destroy(viaDevice->via);
    viaDevice->via = NULL;
  }
  free(viaDevice);
  device->data = NULL;
}

static uint8_t read65C22ViaDevice(HBC56Device* device, uint16_t addr, uint8_t *val, uint8_t dbg)
{
  ViaDevice* viaDevice = get65C22ViaDevice(device);
  if (viaDevice && val)
  {
    if ((addr & 0xfff0) == viaDevice->baseAddr)
    {
      *val = vrEmu6522Read(viaDevice->via, addr & 0xff);
      hbc56Interrupt(viaDevice->irq, *vrEmu6522Int(viaDevice->via) == IntRequested ? INTERRUPT_RAISE : INTERRUPT_RELEASE);
      return 1;
    }
  }
  return 0;
}


static uint8_t write65C22ViaDevice(HBC56Device* device, uint16_t addr, uint8_t val)
{
  ViaDevice* viaDevice = get65C22ViaDevice(device);
  if (viaDevice)
  {
    if ((addr & 0xfff0) == viaDevice->baseAddr)
    {
      vrEmu6522Write(viaDevice->via, addr & 0xff, val);
      hbc56Interrupt(viaDevice->irq, *vrEmu6522Int(viaDevice->via) == IntRequested ? INTERRUPT_RAISE : INTERRUPT_RELEASE);
      return 1;
    }
  }
  return 0;
}

static void tick65C22ViaDevice(HBC56Device* device, uint32_t deltaTicks, double deltaTime)
{
  ViaDevice* viaDevice = get65C22ViaDevice(device);
  if (viaDevice)
  {
    while (deltaTicks--)
    {
      vrEmu6522Tick(viaDevice->via);
    }

    hbc56Interrupt(viaDevice->irq, *vrEmu6522Int(viaDevice->via) == IntRequested ? INTERRUPT_RAISE : INTERRUPT_RELEASE);
  }
}

uint8_t readVia6522Reg(HBC56Device* device, uint8_t reg)
{
  uint8_t val = 0xff;

  ViaDevice* viaDevice = get65C22ViaDevice(device);
  if (viaDevice)
  {
    val = vrEmu6522ReadDbg(viaDevice->via, reg);
  }
  return val;
}
