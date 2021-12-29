/*
 * Troy's HBC-56 Emulator - AY-3-8910 device
 *
 * Copyright (c) 2021 Troy Schrapel
 *
 * This code is licensed under the MIT license
 *
 * https://github.com/visrealm/hbc-56/emulator
 *
 */

#include "ay38910_device.h"

#include "emu2149.h"

#include <stdlib.h>
#include <string.h>
#include <math.h>

#include "SDL.h"

extern void cpu6502_irq(void);

static void resetAy38910Device(HBC56Device*);
static void destroyAy38910Device(HBC56Device*);
static void audioAy38910Device(HBC56Device* device, float* buffer, int numSamples);
static uint8_t readAy38910Device(HBC56Device*, uint16_t, uint8_t*, uint8_t);
static uint8_t writeAy38910Device(HBC56Device*, uint16_t, uint8_t);

#define AY3891X_INACTIVE 0x03
#define AY3891X_READ     0x02
#define AY3891X_WRITE    0x01
#define AY3891X_ADDR     0x00

struct AY38910Device
{
  uint16_t       baseAddr;
  uint8_t        regAddr;
  PSG           *psg;
};
typedef struct AY38910Device AY38910Device;

 /* Function:  createAy38910Device
  * --------------------
 * create an AY-3-8910 PSG device
  */
HBC56Device createAY38910Device(uint16_t baseAddr, int clockFreq, int sampleRate)
{
  HBC56Device device = createDevice("AY-3-8910 PSG");
  AY38910Device* ayDevice = (AY38910Device*)malloc(sizeof(AY38910Device));
  if (ayDevice)
  {
    ayDevice->baseAddr = baseAddr;
    ayDevice->psg = PSG_new(clockFreq, sampleRate);
    ayDevice->regAddr = 0;

    device.data = ayDevice;

    device.resetFn = &resetAy38910Device;
    device.destroyFn = &destroyAy38910Device;
    device.readFn = &readAy38910Device;
    device.writeFn = &writeAy38910Device;
    device.audioFn = &audioAy38910Device;
  }
  else
  {
    destroyDevice(&device);
  }

  return device;
}


/* Function:  getAy38910Device
 * --------------------
 * helper funtion to get private structure
 */
inline static AY38910Device* getAy38910Device(HBC56Device* device)
{
  if (!device) return NULL;
  return (AY38910Device*)device->data;
}

static void resetAy38910Device(HBC56Device* device)
{
  AY38910Device* ayDevice = getAy38910Device(device);
  if (ayDevice)
  {
    PSG_reset(ayDevice->psg);
  }
}

static void destroyAy38910Device(HBC56Device *device)
{
  AY38910Device *ayDevice = getAy38910Device(device);
  if (ayDevice)
  {
    PSG_delete(ayDevice->psg);
    ayDevice->psg = NULL;
  }
  free(ayDevice);
  device->data = NULL;
}

static void audioAy38910Device(HBC56Device* device, float* buffer, int numSamples)
{
  AY38910Device* ayDevice = getAy38910Device(device);
  if (ayDevice)
  {
    for (int i = 0; i < numSamples; ++i)
    {
      PSG_calc(ayDevice->psg);
      buffer[i * 2]     += ((ayDevice->psg->ch_out[1] + ayDevice->psg->ch_out[2]) / (8192.0f * 2.0f)) - 0.5f;
      buffer[i * 2 + 1] += ((ayDevice->psg->ch_out[0] + ayDevice->psg->ch_out[2]) / (8192.0f * 2.0f)) - 0.5f;
    }
  }
}

static uint8_t readAy38910Device(HBC56Device* device, uint16_t addr, uint8_t *val, uint8_t dbg)
{
  AY38910Device* ayDevice = getAy38910Device(device);
  if (ayDevice && val)
  {
    if (addr == (ayDevice->baseAddr | AY3891X_READ))
    {
      *val = PSG_readReg(ayDevice->psg, ayDevice->regAddr);
      return 1;
    }
  }
  return 0;
}


static uint8_t writeAy38910Device(HBC56Device* device, uint16_t addr, uint8_t val)
{
  AY38910Device* ayDevice = getAy38910Device(device);
  if (ayDevice)
  {
    if (addr == (ayDevice->baseAddr | AY3891X_ADDR))
    {
      ayDevice->regAddr = val;
      return 1;
    }
    else if (addr == (ayDevice->baseAddr | AY3891X_WRITE))
    {
      PSG_writeReg(ayDevice->psg, ayDevice->regAddr, val);
      return 1;
    }
  }
  return 0;
}