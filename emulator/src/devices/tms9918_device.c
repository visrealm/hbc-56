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
#include "SDL.h"

#include <stdlib.h>
#include <string.h>
#include <math.h>

extern void cpu6502_irq(void);

static void resetTms9918Device(HBC56Device*);
static void destroyTms9918Device(HBC56Device*);
static void renderTms9918Device(HBC56Device* device);
static void tickTms9918Device(HBC56Device*, uint32_t, double);
static uint8_t readTms9918Device(HBC56Device*, uint16_t, uint8_t*, uint8_t);
static uint8_t writeTms9918Device(HBC56Device*, uint16_t, uint8_t);

/* tms9918 constants */
#define TMS9918_DISPLAY_WIDTH   320
#define TMS9918_DISPLAY_HEIGHT  240
#define TMS9918_FPS             60.0
#define TMS9918_TICK_MIN_PIXELS 26

/* tms9918 computed constants */
#define TMS9918_FRAME_TIME      (1.0 / TMS9918_FPS)
#define TMS9918_ROW_TIME        (TMS9918_FRAME_TIME / (double)TMS9918_DISPLAY_HEIGHT)
#define TMS9918_PIXEL_TIME      (TMS9918_ROW_TIME / (double)TMS9918_DISPLAY_WIDTH)
#define TMS9918_BORDER_X        ((TMS9918_DISPLAY_WIDTH - TMS9918A_PIXELS_X) / 2)
#define TMS9918_BORDER_Y        ((TMS9918_DISPLAY_HEIGHT - TMS9918A_PIXELS_Y) / 2)
#define TMS9918_DISPLAY_PIXELS  (TMS9918_DISPLAY_WIDTH * TMS9918_DISPLAY_HEIGHT)

/* tms9918 palette */
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

/* tms9918 device data */
struct TMS9918Device
{
  uint16_t       dataAddr;
  uint16_t       regAddr;
  VrEmuTms9918a *tms9918;
  uint32_t       frameBuffer[TMS9918_DISPLAY_PIXELS];
  double         unusedTime;
  int            currentFramePixels;
  uint8_t        scanlineBuffer[TMS9918_DISPLAY_WIDTH];
};
typedef struct TMS9918Device TMS9918Device;


 /* Function:  createTms9918Device
  * --------------------
  * create a TMS9918 device
  */
HBC56Device createTms9918Device(uint16_t dataAddr, uint16_t regAddr, SDL_Renderer* renderer)
{
  HBC56Device device = createDevice("TMS9918 VDP");
  TMS9918Device* tmsDevice = (TMS9918Device*)malloc(sizeof(TMS9918Device));
  if (tmsDevice)
  {
    tmsDevice->dataAddr = dataAddr;
    tmsDevice->regAddr = regAddr;
    tmsDevice->tms9918 = vrEmuTms9918aNew();
    tmsDevice->unusedTime = 0.0f;
    tmsDevice->currentFramePixels = 0;
    memset(tmsDevice->frameBuffer, 0, sizeof(tmsDevice->frameBuffer));
    memset(tmsDevice->scanlineBuffer, 6, sizeof(tmsDevice->scanlineBuffer));

    device.data = tmsDevice;
    device.resetFn = &resetTms9918Device;
    device.destroyFn = &destroyTms9918Device;
    device.readFn = &readTms9918Device;
    device.writeFn = &writeTms9918Device;
    device.tickFn = &tickTms9918Device;
    device.renderFn = &renderTms9918Device;

    device.output = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_STREAMING,
                                      TMS9918_DISPLAY_WIDTH, TMS9918_DISPLAY_HEIGHT);
#ifndef _EMSCRIPTEN
    SDL_SetTextureScaleMode(device.output, SDL_ScaleModeBest);
#endif

  }
  else
  {
    destroyDevice(&device);
  }

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

/* Function:  resetTms9918Device
 * --------------------
 * called when the machine is reset. resets the tms internal state
 */
static void resetTms9918Device(HBC56Device* device)
{
  TMS9918Device* tmsDevice = getTms9918Device(device);
  if (tmsDevice)
  {
    vrEmuTms9918aReset(tmsDevice->tms9918);
  }
}

/* Function:  destroyTms9918Device
 * --------------------
 * destroy/clean up the tms data structure
 */
static void destroyTms9918Device(HBC56Device *device)
{
  TMS9918Device *tmsDevice = getTms9918Device(device);
  if (tmsDevice)
  {
    vrEmuTms9918aDestroy(tmsDevice->tms9918);
  }
  free(tmsDevice);
  device->data = NULL;

  SDL_DestroyTexture(device->output);
  device->output = NULL;
}

/* Function:  renderTms9918Device
 * --------------------
 * renders the TMS9918 to the output texture
 */
static void renderTms9918Device(HBC56Device* device)
{
  TMS9918Device* tmsDevice = getTms9918Device(device);
  if (tmsDevice)
  {
    void *pixels = NULL;
    int pitch = 0;
    SDL_LockTexture(device->output, NULL, &pixels, &pitch);
    memcpy(pixels, tmsDevice->frameBuffer, sizeof(tmsDevice->frameBuffer));
    SDL_UnlockTexture(device->output);
  }
}

/* Function:  tickTms9918Device
 * --------------------
 * renders the portion of the screen since the last call. relies on deltaTime to determine
 * how much of the screen to render. this style of rendering allows mid-frame changes to be
 * shown in the display if called frequently enough
 */
 int c = 0;
static void tickTms9918Device(HBC56Device* device, uint32_t delataTicks, double deltaTime)
{
  TMS9918Device* tmsDevice = getTms9918Device(device);
  if (tmsDevice)
  {
    /* determine portion of frame to render */
    deltaTime += tmsDevice->unusedTime;

    double thisStepTotalPixelsDbl = 0.0;
    tmsDevice->unusedTime = modf(deltaTime / (double)TMS9918_PIXEL_TIME, &thisStepTotalPixelsDbl) * TMS9918_PIXEL_TIME;
    int thisStepTotalPixels = (uint32_t)thisStepTotalPixelsDbl;
    if (thisStepTotalPixels < TMS9918_TICK_MIN_PIXELS)
    {
      tmsDevice->unusedTime += thisStepTotalPixels * TMS9918_PIXEL_TIME;
      return;
    }

    if (tmsDevice->currentFramePixels + thisStepTotalPixels >= TMS9918_DISPLAY_PIXELS)
    {
      tmsDevice->unusedTime += ((tmsDevice->currentFramePixels + thisStepTotalPixels) - TMS9918_DISPLAY_PIXELS) * TMS9918_PIXEL_TIME;
      thisStepTotalPixels = TMS9918_DISPLAY_PIXELS - tmsDevice->currentFramePixels;
    }

    div_t currentPos = div((int)tmsDevice->currentFramePixels, (int)TMS9918_DISPLAY_WIDTH);

    int currentRow = currentPos.quot;
    int currentCol = currentPos.rem;

    uint8_t bgColor = (vrEmuTms9918aDisplayEnabled(tmsDevice->tms9918)
      ? vrEmuTms9918aRegValue(tmsDevice->tms9918, TMS_REG_7)
      : TMS_BLACK) & 0x0f;

    //bgColor = (++c) & 0x0f;
    int firstPix = 1;
    uint32_t* fbPtr = tmsDevice->frameBuffer + tmsDevice->currentFramePixels;

    int tmsRow = 0;

    for (int p = 0; p < thisStepTotalPixels; ++p)
    {
      currentPos = div((int)tmsDevice->currentFramePixels, (int)TMS9918_DISPLAY_WIDTH);

      currentRow = currentPos.quot;
      currentCol = currentPos.rem;

      if (firstPix || currentCol == 0)
      {
        tmsRow = currentRow - TMS9918_BORDER_Y;
        memset(tmsDevice->scanlineBuffer, bgColor, sizeof(tmsDevice->scanlineBuffer));
        if (tmsRow >=0 && tmsRow < TMS9918A_PIXELS_Y)
          vrEmuTms9918aScanLine(tmsDevice->tms9918, tmsRow, tmsDevice->scanlineBuffer + TMS9918_BORDER_X);
        firstPix = 0;
      }

      *(fbPtr++) = tms9918Pal[tmsDevice->scanlineBuffer[currentCol]];
      ++tmsDevice->currentFramePixels;

      if (tmsDevice->currentFramePixels == (TMS9918_DISPLAY_WIDTH * (TMS9918_DISPLAY_HEIGHT - TMS9918_BORDER_Y)))
      {
        if (vrEmuTms9918aDisplayEnabled(tmsDevice->tms9918) &&
          (vrEmuTms9918aRegValue(tmsDevice->tms9918, TMS_REG_1) & 0x20))
        {
          cpu6502_irq(); /* TODO: abstract this away */
        }
      }
      tmsDevice->currentFramePixels = tmsDevice->currentFramePixels % TMS9918_DISPLAY_PIXELS;
    }
  }
}


/* Function:  readTms9918Device
 * --------------------
 * read from the tms. address determines status or data
 */
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

/* Function:  writeTms9918Device
 * --------------------
 * write to the tms. address determines address/register or data
 */
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


uint8_t readTms9918Vram(HBC56Device* device, uint16_t vramAddr)
{
  TMS9918Device* tmsDevice = getTms9918Device(device);
  if (tmsDevice)
  {
    return vrEmuTms9918aVramValue(tmsDevice->tms9918, vramAddr);
  }
  return 0;
}

uint8_t readTms9918Reg(HBC56Device* device, uint8_t reg)
{
  TMS9918Device* tmsDevice = getTms9918Device(device);
  if (tmsDevice)
  {
    return vrEmuTms9918aRegValue(tmsDevice->tms9918, reg);
  }
  return 0;
}