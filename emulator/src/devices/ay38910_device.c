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

#if 0

extern void cpu6502_irq(void);

static void resetAy38910Device(HBC56Device*);
static void destroyAy38910Device(HBC56Device*);
static void renderAy38910Device(HBC56Device*);
static void tickAy38910Device(HBC56Device*, uint32_t, double);
static uint8_t readAy38910Device(HBC56Device*, uint16_t, uint8_t*, uint8_t);
static uint8_t writeAy38910Device(HBC56Device*, uint16_t, uint8_t);


struct AY38910Device
{
  uint16_t       baseAddr;
  PSG           *psg;
};
typedef struct AY38910Device AY38910Device;

 /* Function:  createAy38910Device
  * --------------------
 * create an AY-3-8910 PSG device
  */
HBC56Device* createAY38910Device(uint16_t baseAddr, int clockFreq)
{
  HBC56Device* device = createDevice("AY-3-8910 PSG");
  if (!device)
    return NULL;

  AY38910Device* ayDevice = (AY38910Device*)malloc(sizeof(AY38910Device));
  if (ayDevice)
  {
    ayDevice->baseAddr = baseAddr;
    ayDevice->psg = PSG_new(clockFreq, have.freq);
    device->data = ayDevice;
  }
  else
  {
    destroyDevice(device);
    return NULL;
  }

  device->resetFn = &resetAy38910Device;
  device->destroyFn = &destroyAy38910Device;
  device->readFn = &readAy38910Device;
  device->writeFn = &writeAy38910Device;
  device->tickFn = &tickAy38910Device;

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
    vrEmuTms9918aDestroy(ayDevice->tms9918);
  }
  free(ayDevice);
  device->data = NULL;
}


static void renderAy38910Device(HBC56Device* device)
{
  AY38910Device* ayDevice = getAy38910Device(device);
  if (ayDevice)
  {
      SDL_UpdateTexture(device->output, NULL, ayDevice->frameBuffer, TMS9918_DISPLAY_WIDTH * 4);
  }
}

int color=0;

static void tickAy38910Device(HBC56Device* device, uint32_t delataTicks, double deltaTime)
{
  AY38910Device* ayDevice = getAy38910Device(device);
  if (ayDevice)
  {
    deltaTime += ayDevice->unusedTime;

    if (deltaTime > TMS9918_FRAME_TIME) deltaTime = TMS9918_FRAME_TIME;

    ayDevice->unusedTime = 0.0;

    div_t currentPos = div((int)ayDevice->currentFramePixels, (int)TMS9918_DISPLAY_WIDTH);

    int currentRow = currentPos.quot;
    int currentCol = currentPos.rem;

    double thisStepTotalPixelsDbl = 0.0;
    ayDevice->unusedTime += modf(deltaTime / (double)TMS9918_PIXEL_TIME, &thisStepTotalPixelsDbl) * TMS9918_PIXEL_TIME;
    int thisStepTotalPixels = (uint32_t)thisStepTotalPixelsDbl;

    div_t endPos = div((int)ayDevice->currentFramePixels + thisStepTotalPixels, (int)TMS9918_DISPLAY_WIDTH);

    int endRow = endPos.quot;
    int endCol = endPos.rem;

    uint32_t* fbPtr = ayDevice->frameBuffer + ayDevice->currentFramePixels;

    if (endRow > TMS9918_DISPLAY_HEIGHT)
    {
      int extraPixels = endCol;
      extraPixels += TMS9918_DISPLAY_WIDTH * (endRow - TMS9918_DISPLAY_HEIGHT);

      endRow = TMS9918_DISPLAY_HEIGHT;
      endCol = TMS9918_DISPLAY_WIDTH;

      ayDevice->unusedTime += extraPixels * TMS9918_PIXEL_TIME;

      thisStepTotalPixels = (TMS9918_DISPLAY_WIDTH * TMS9918_DISPLAY_HEIGHT) - ayDevice->currentFramePixels;
    }

    uint8_t bgColor = (vrEmuTms9918aDisplayEnabled(ayDevice->tms9918) 
                                ? vrEmuTms9918aRegValue(ayDevice->tms9918, TMS_REG_7)
                                : TMS_BLACK) & 0x0f;

    //++color;
    bgColor = (bgColor + color) & 0x0f;

    for (int y = currentRow; y < endRow; ++y)
    {
      // set to bg
      memset(ayDevice->scanlineBuffer, bgColor, sizeof(ayDevice->scanlineBuffer));

      int tmsRow = y - TMS9918_BORDER_Y;

      if (tmsRow >= 0 && tmsRow < TMS9918A_PIXELS_Y)
      {
        vrEmuTms9918aScanLine(ayDevice->tms9918, tmsRow, ayDevice->scanlineBuffer + TMS9918_BORDER_X);
      }

      int xPixels = (y == (endRow - 1)) ? endCol : TMS9918_DISPLAY_WIDTH;

      for (int x = currentCol; x < xPixels; ++x)
      {
        *fbPtr++ = tms9918Pal[ayDevice->scanlineBuffer[x]];
        ++ayDevice->currentFramePixels;
      }
      currentCol = 0;
        
      if (tmsRow == TMS9918A_PIXELS_Y)
      {
        /* irq here instead? */
      }
    }
    
    if (ayDevice->currentFramePixels >= (TMS9918_DISPLAY_WIDTH * TMS9918_DISPLAY_HEIGHT))
    {
      ayDevice->currentFramePixels = 0;
      if (vrEmuTms9918aDisplayEnabled(ayDevice->tms9918) && 
          (vrEmuTms9918aRegValue(ayDevice->tms9918, TMS_REG_1) & 0x20))
      {
        cpu6502_irq(); /* TODO: abstract this away */
      }
    }
  }
}


static uint8_t readAy38910Device(HBC56Device* device, uint16_t addr, uint8_t *val, uint8_t dbg)
{
  AY38910Device* ayDevice = getAy38910Device(device);
  if (ayDevice && val)
  {
    if (addr == ayDevice->regAddr)
    {
      *val = vrEmuTms9918aReadStatus(ayDevice->tms9918);
      return 1;
    }
    else if (addr == ayDevice->dataAddr)
    {
      if (dbg)
      {
        *val = vrEmuTms9918aReadDataNoInc(ayDevice->tms9918);
      }
      else
      {
        *val = vrEmuTms9918aReadData(ayDevice->tms9918);
      }
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
    if (addr == ayDevice->regAddr)
    {
      vrEmuTms9918aWriteAddr(ayDevice->tms9918, val);
      return 1;
    }
    else if (addr == ayDevice->dataAddr)
    {
      vrEmuTms9918aWriteData(ayDevice->tms9918, val);
      return 1;
    }
  }
  return 0;
}
#endif