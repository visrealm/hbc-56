/*
 * Troy's HBC-56 Emulator - TMS9918 device
 *
 * Copyright (c) 2021 Troy Schrapel
 *
 * This code is licensed under the MIT license
 *
 * https://github.com/visrealm/hbc-56/emulator
 *
 */

#include "tms9918_device.h"
#include "tms9918_core.h"

#include <stdlib.h>
#include <string.h>
#include <math.h>

#include "SDL.h"

extern void cpu6502_irq(void);

static void resetTms9918Device(HBC56Device*);
static void destroyTms9918Device(HBC56Device*);
static void renderTms9918Device(HBC56Device* device);
static void tickTms9918Device(HBC56Device*, uint32_t, double);
static uint8_t readTms9918Device(HBC56Device*, uint16_t, uint8_t*, uint8_t);
static uint8_t writeTms9918Device(HBC56Device*, uint16_t, uint8_t);

#define TMS9918_DISPLAY_WIDTH   320
#define TMS9918_DISPLAY_HEIGHT  240
#define TMS9918_FPS             60.0
#define TMS9918_FRAME_TIME      (1.0 / TMS9918_FPS)
#define TMS9918_ROW_TIME        (TMS9918_FRAME_TIME / (double)TMS9918_DISPLAY_HEIGHT)
#define TMS9918_PIXEL_TIME      (TMS9918_ROW_TIME / (double)TMS9918_DISPLAY_WIDTH)
#define TMS9918_BORDER_X        ((TMS9918_DISPLAY_WIDTH - TMS9918A_PIXELS_X) / 2)
#define TMS9918_BORDER_Y        ((TMS9918_DISPLAY_HEIGHT - TMS9918A_PIXELS_Y) / 2)

static const uint32_t tms9918Pal[] = {
  0x00000000, /* transparent */
  0x000000ff, /* black */
  0x21c942ff, /* medium green */
  0x5edc78ff, /* light green */
  0x5455edff, /* dark blue */
  0x7d75fcff, /* light blue */
  0xd3524dff, /* dark red */
  0x43ebf6ff, /* cyan */
  0xfd5554ff, /* medium red */
  0xff7978ff, /* light red */
  0xd3c153ff, /* dark yellow */
  0xe5ce80ff, /* light yellow */
  0x21b03cff, /* dark green */
  0xc95bbaff, /* magenta */
  0xccccccff, /* grey */
  0xffffffff  /* white */
};

struct TMS9918Device
{
  uint16_t       dataAddr;
  uint16_t       regAddr;
  VrEmuTms9918a *tms9918;
  uint32_t       frameBuffer[TMS9918_DISPLAY_WIDTH * TMS9918_DISPLAY_HEIGHT];
  double         unusedTime;
  int       currentFramePixels;
  uint8_t        scanlineBuffer[TMS9918_DISPLAY_WIDTH];
};
typedef struct TMS9918Device TMS9918Device;


/* Function:  createTms9918Device
 * --------------------
 * create a ram or rom device for the given address range
 */

 /* Function:  createTms9918Device
  * --------------------
  * create a TMS9918 device
  */
HBC56Device* createTms9918Device(uint16_t dataAddr, uint16_t regAddr, SDL_Renderer* renderer)
{
  HBC56Device* device = createDevice("TMS9918 VDP");
  if (!device)
    return NULL;

  TMS9918Device* tmsDevice = (TMS9918Device*)malloc(sizeof(TMS9918Device));
  if (tmsDevice)
  {
    tmsDevice->dataAddr = dataAddr;
    tmsDevice->regAddr = regAddr;
    tmsDevice->tms9918 = vrEmuTms9918aNew();
    tmsDevice->unusedTime = 0.0f;
    tmsDevice->currentFramePixels = 0;
    memset(tmsDevice->frameBuffer, 0, sizeof(tmsDevice->frameBuffer));
    memset(tmsDevice->scanlineBuffer, 0, sizeof(tmsDevice->scanlineBuffer));
    device->data = tmsDevice;
  }
  else
  {
    destroyDevice(device);
    return NULL;
  }

  device->resetFn = &resetTms9918Device;
  device->destroyFn = &destroyTms9918Device;
  device->readFn = &readTms9918Device;
  device->writeFn = &writeTms9918Device;
  device->tickFn = &tickTms9918Device;
  device->renderFn = &renderTms9918Device;

  device->output = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_STREAMING,
                                     TMS9918_DISPLAY_WIDTH, TMS9918_DISPLAY_HEIGHT);

  return device;
}


/* Function:  getTms9918Device
 * --------------------
 * helper funtion to get private structure
 */
inline static TMS9918Device* getTms9918Device(HBC56Device* device)
{
  if (!device) return NULL;
  return (TMS9918Device*)device->data;
}

static void resetTms9918Device(HBC56Device* device)
{
  TMS9918Device* tmsDevice = getTms9918Device(device);
  if (tmsDevice)
  {
    vrEmuTms9918aReset(tmsDevice->tms9918);
  }
}

static void destroyTms9918Device(HBC56Device *device)
{
  TMS9918Device *tmsDevice = getTms9918Device(device);
  if (tmsDevice)
  {
    vrEmuTms9918aDestroy(tmsDevice->tms9918);
  }
  free(tmsDevice);
}


static void renderTms9918Device(HBC56Device* device)
{
  TMS9918Device* tmsDevice = getTms9918Device(device);
  if (tmsDevice)
  {
      SDL_UpdateTexture(device->output, NULL, tmsDevice->frameBuffer, TMS9918_DISPLAY_WIDTH * 4);
  }
}

int color=0;

static void tickTms9918Device(HBC56Device* device, uint32_t delataTicks, double deltaTime)
{
  TMS9918Device* tmsDevice = getTms9918Device(device);
  if (tmsDevice)
  {
    deltaTime += tmsDevice->unusedTime;

    if (deltaTime > TMS9918_FRAME_TIME) deltaTime = TMS9918_FRAME_TIME;

    tmsDevice->unusedTime = 0.0;

    div_t currentPos = div((int)tmsDevice->currentFramePixels, (int)TMS9918_DISPLAY_WIDTH);

    int currentRow = currentPos.quot;
    int currentCol = currentPos.rem;

    double thisStepTotalPixelsDbl = 0.0;
    tmsDevice->unusedTime += modf(deltaTime / (double)TMS9918_PIXEL_TIME, &thisStepTotalPixelsDbl) * TMS9918_PIXEL_TIME;
    int thisStepTotalPixels = (uint32_t)thisStepTotalPixelsDbl;

    div_t endPos = div((int)tmsDevice->currentFramePixels + thisStepTotalPixels, (int)TMS9918_DISPLAY_WIDTH);

    int endRow = endPos.quot;
    int endCol = endPos.rem;

    uint32_t* fbPtr = tmsDevice->frameBuffer + tmsDevice->currentFramePixels;

    if (endRow > TMS9918_DISPLAY_HEIGHT)
    {
      int extraPixels = endCol;
      extraPixels += TMS9918_DISPLAY_WIDTH * (endRow - TMS9918_DISPLAY_HEIGHT);

      endRow = TMS9918_DISPLAY_HEIGHT;
      endCol = TMS9918_DISPLAY_WIDTH;

      tmsDevice->unusedTime += extraPixels * TMS9918_PIXEL_TIME;

      thisStepTotalPixels = (TMS9918_DISPLAY_WIDTH * TMS9918_DISPLAY_HEIGHT) - tmsDevice->currentFramePixels;
    }

    uint8_t bgColor = (vrEmuTms9918aDisplayEnabled(tmsDevice->tms9918) 
                                ? vrEmuTms9918aRegValue(tmsDevice->tms9918, TMS_REG_7)
                                : TMS_BLACK) & 0x0f;

    //++color;
    bgColor = (bgColor + color) & 0x0f;

    for (int y = currentRow; y < endRow; ++y)
    {
      // set to bg
      memset(tmsDevice->scanlineBuffer, bgColor, sizeof(tmsDevice->scanlineBuffer));

      int tmsRow = y - TMS9918_BORDER_Y;

      if (tmsRow >= 0 && tmsRow < TMS9918A_PIXELS_Y)
      {
        vrEmuTms9918aScanLine(tmsDevice->tms9918, tmsRow, tmsDevice->scanlineBuffer + TMS9918_BORDER_X);
      }

      int xPixels = (y == (endRow - 1)) ? endCol : TMS9918_DISPLAY_WIDTH;

      for (int x = currentCol; x < xPixels; ++x)
      {
        *fbPtr++ = tms9918Pal[tmsDevice->scanlineBuffer[x]];
        ++tmsDevice->currentFramePixels;
      }
      currentCol = 0;
        
      if (tmsRow == TMS9918A_PIXELS_Y)
      {
        
      }
    }
    
    if (tmsDevice->currentFramePixels >= (TMS9918_DISPLAY_WIDTH * TMS9918_DISPLAY_HEIGHT))
    {
      tmsDevice->currentFramePixels = 0;
      cpu6502_irq();
    }
  }
}


static uint8_t readTms9918Device(HBC56Device* device, uint16_t addr, uint8_t *val, uint8_t dbg)
{
  TMS9918Device* tmsDevice = getTms9918Device(device);
  if (tmsDevice && val)
  {
    if (addr == tmsDevice->regAddr)
    {
      *val = vrEmuTms9918aReadStatus(tmsDevice->tms9918);
      return 1;
    }
    else if (addr == tmsDevice->dataAddr)
    {
      if (dbg)
      {
        *val = vrEmuTms9918aReadDataNoInc(tmsDevice->tms9918);
      }
      else
      {
        *val = vrEmuTms9918aReadData(tmsDevice->tms9918);
      }
      return 1;
    }
  }
  return 0;
}


static uint8_t writeTms9918Device(HBC56Device* device, uint16_t addr, uint8_t val)
{
  TMS9918Device* tmsDevice = getTms9918Device(device);
  if (tmsDevice)
  {
    if (addr == tmsDevice->regAddr)
    {
      vrEmuTms9918aWriteAddr(tmsDevice->tms9918, val);
      return 1;
    }
    else if (addr == tmsDevice->dataAddr)
    {
      vrEmuTms9918aWriteData(tmsDevice->tms9918, val);
      return 1;
    }
  }
  return 0;
}
