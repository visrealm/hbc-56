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

#include "hbc56emu.h"
#include "ay38910_device.h"

#include "emu2149.h"

#include <stdlib.h>
#include <string.h>
#include <math.h>

#include "SDL.h"

static void resetAy38910Device(HBC56Device*);
static void destroyAy38910Device(HBC56Device*);
static void audioAy38910Device(HBC56Device* device, float* buffer, int numSamples);
static uint8_t readAy38910Device(HBC56Device*, uint16_t, uint8_t*, uint8_t);
static uint8_t writeAy38910Device(HBC56Device*, uint16_t, uint8_t);
static void tickAy38910Device(HBC56Device*, uint32_t, float);

#define AY3891X_INACTIVE 0x03
#define AY3891X_READ     0x02
#define AY3891X_WRITE    0x01
#define AY3891X_ADDR     0x00

#define BUFFER_MAX_SIZE  16384
#define BUFFER_MASK      (BUFFER_MAX_SIZE - 1)

struct AY38910Device
{
  uint16_t       baseAddr;
  uint8_t        regAddr;
  int            channels;
  float          buffer[BUFFER_MAX_SIZE];
  int            bufferStart;
  int            bufferEnd;
  double         deltaTimeOverFlow;
  double         timePerSample;
  double         lastCpuRuntimeSeconds;
  PSG* psg;
  SDL_mutex* mutex;
};
typedef struct AY38910Device AY38910Device;

/* Function:  createAy38910Device
 * --------------------
* create an AY-3-8910 PSG device
 */
HBC56Device createAY38910Device(uint16_t baseAddr, int clockFreq, int sampleRate, int channels)
{
  HBC56Device device = createDevice("AY-3-8910 PSG");
  AY38910Device* ayDevice = (AY38910Device*)malloc(sizeof(AY38910Device));
  if (ayDevice)
  {
    ayDevice->baseAddr = baseAddr;
    ayDevice->psg = PSG_new(clockFreq, sampleRate);
    PSG_setVolumeMode(ayDevice->psg, 2);  // AY-3-8910 mode
    ayDevice->regAddr = 0;
    ayDevice->channels = channels;
    ayDevice->mutex = SDL_CreateMutex();
    memset(ayDevice->buffer, 0, sizeof(ayDevice->buffer));
    ayDevice->bufferStart = 0;
    ayDevice->bufferEnd = 0;
    ayDevice->deltaTimeOverFlow = 0.0;
    ayDevice->timePerSample = 1.0 / (double)sampleRate;


    device.data = ayDevice;

    device.resetFn = &resetAy38910Device;
    device.destroyFn = &destroyAy38910Device;
    device.readFn = &readAy38910Device;
    device.writeFn = &writeAy38910Device;
    device.audioFn = &audioAy38910Device;
    device.tickFn = &tickAy38910Device;
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

static void destroyAy38910Device(HBC56Device* device)
{
  AY38910Device* ayDevice = getAy38910Device(device);
  if (ayDevice)
  {
    PSG_delete(ayDevice->psg);
    ayDevice->psg = NULL;

    SDL_DestroyMutex(ayDevice->mutex);
    ayDevice->mutex = NULL;
  }
  free(ayDevice);
  device->data = NULL;
}


static inline void addSampleToBuffer(AY38910Device* ayDevice)
{
  PSG_calc(ayDevice->psg);

  ayDevice->buffer[ayDevice->bufferEnd++] = ((ayDevice->psg->ch_out[0] * 2 + ayDevice->psg->ch_out[2]) / (8192.0f * 3.0f));
  ayDevice->bufferEnd &= BUFFER_MASK;

  if (ayDevice->channels > 1)
  {
    ayDevice->buffer[ayDevice->bufferEnd++] = ((ayDevice->psg->ch_out[1] * 2 + ayDevice->psg->ch_out[2]) / (8192.0f * 3.0f));
    ayDevice->bufferEnd &= BUFFER_MASK;
  }
  ayDevice->deltaTimeOverFlow -= ayDevice->timePerSample;
}

static void tickAy38910Device(HBC56Device* device, uint32_t deltaTicks, float deltaTime)
{
  AY38910Device* ayDevice = getAy38910Device(device);
  if (ayDevice)
  {
    SDL_LockMutex(ayDevice->mutex);

    double currentTime = hbc56CpuRuntimeSeconds();
    double extraTime = currentTime - ayDevice->lastCpuRuntimeSeconds;
    ayDevice->deltaTimeOverFlow += extraTime;

    while (ayDevice->deltaTimeOverFlow > 0)
    {
      addSampleToBuffer(ayDevice);
      ayDevice->lastCpuRuntimeSeconds = currentTime;
    }

    SDL_UnlockMutex(ayDevice->mutex);
  }
}

static void audioAy38910Device(HBC56Device* device, float* buffer, int numSamples)
{
  AY38910Device* ayDevice = getAy38910Device(device);
  if (ayDevice)
  {
    SDL_LockMutex(ayDevice->mutex);

    int end = ayDevice->bufferEnd;
    if (end < ayDevice->bufferStart) end += BUFFER_MAX_SIZE;

    int size = end - ayDevice->bufferStart;

    int samples = size >> 1;

    while (samples++ < numSamples)
    {
      addSampleToBuffer(ayDevice);
    }

    for (int i = 0; i < numSamples; ++i)
    {
      buffer[i * ayDevice->channels] += ayDevice->buffer[ayDevice->bufferStart++];
      ayDevice->bufferStart &= BUFFER_MASK;

      if (ayDevice->channels > 1)
      {
        buffer[i * ayDevice->channels + 1] += ayDevice->buffer[ayDevice->bufferStart++];
        ayDevice->bufferStart &= BUFFER_MASK;
      }
    }

    SDL_UnlockMutex(ayDevice->mutex);
  }
}

static uint8_t readAy38910Device(HBC56Device* device, uint16_t addr, uint8_t* val, uint8_t dbg)
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
      tickAy38910Device(device, 0, 0);

      PSG_writeReg(ayDevice->psg, ayDevice->regAddr, val);
      return 1;
    }
  }
  return 0;
}