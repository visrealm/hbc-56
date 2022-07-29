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

#include "vrEmuTms9918.h"
#include "vrEmuTms9918Util.h"

#include "../hbc56emu.h"

#include "SDL.h"

#include <stdlib.h>
#include <string.h>
#include <math.h>

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
#define TMS9918_BORDER_X        ((TMS9918_DISPLAY_WIDTH - TMS9918_PIXELS_X) / 2)
#define TMS9918_BORDER_Y        ((TMS9918_DISPLAY_HEIGHT - TMS9918_PIXELS_Y) / 2)
#define TMS9918_DISPLAY_PIXELS  (TMS9918_DISPLAY_WIDTH * TMS9918_DISPLAY_HEIGHT)

/* tms9918 device data */
struct TMS9918Device
{
  uint16_t       dataAddr;
  uint16_t       regAddr;
  VrEmuTms9918  *tms9918;
  uint32_t       frameBuffer[TMS9918_DISPLAY_PIXELS];
  double         unusedTime;
  int            currentFramePixels;
  uint8_t        scanlineBuffer[TMS9918_DISPLAY_WIDTH];
  uint8_t        irq;
};
typedef struct TMS9918Device TMS9918Device;


 /* Function:  createTms9918Device
  * --------------------
  * create a TMS9918 device
  */
HBC56Device createTms9918Device(uint16_t dataAddr, uint16_t regAddr, uint8_t irq, SDL_Renderer* renderer)
{
  HBC56Device device = createDevice("TMS9918 VDP");
  TMS9918Device* tmsDevice = (TMS9918Device*)malloc(sizeof(TMS9918Device));
  if (tmsDevice)
  {
    tmsDevice->dataAddr = dataAddr;
    tmsDevice->regAddr = regAddr;
    tmsDevice->irq = irq;
    tmsDevice->tms9918 = vrEmuTms9918New();
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
    #ifndef __CLANG__
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
    vrEmuTms9918Reset(tmsDevice->tms9918);
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
    vrEmuTms9918Destroy(tmsDevice->tms9918);
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
 * shown in the display if called frequently enough. you can achieve beam racing effects.
 */
int c = 0;
static void tickTms9918Device(HBC56Device* device, uint32_t deltaTicks, double deltaTime)
{
  TMS9918Device* tmsDevice = getTms9918Device(device);
  if (tmsDevice)
  {
    /* determine portion of frame to render */
    deltaTime += tmsDevice->unusedTime;

    /* how many pixels are we rendering? */
    double thisStepTotalPixelsDbl = 0.0;
    tmsDevice->unusedTime = modf(deltaTime / (double)TMS9918_PIXEL_TIME, &thisStepTotalPixelsDbl) * TMS9918_PIXEL_TIME;
    int thisStepTotalPixels = (uint32_t)thisStepTotalPixelsDbl;

    /* if we haven't reached the minimum, accumulate time for the next call and return */
    if (thisStepTotalPixels < TMS9918_TICK_MIN_PIXELS)
    {
      tmsDevice->unusedTime += thisStepTotalPixels * TMS9918_PIXEL_TIME;
      return;
    }

    /* we only render the end end of a frame. if we need to go further, accumulate the time for the next call */
    if (tmsDevice->currentFramePixels + thisStepTotalPixels >= TMS9918_DISPLAY_PIXELS)
    {
      tmsDevice->unusedTime += ((tmsDevice->currentFramePixels + thisStepTotalPixels) - TMS9918_DISPLAY_PIXELS) * TMS9918_PIXEL_TIME;
      thisStepTotalPixels = TMS9918_DISPLAY_PIXELS - tmsDevice->currentFramePixels;
    }

    /* get the background color for this run of pixels */
    uint8_t bgColor = (vrEmuTms9918DisplayEnabled(tmsDevice->tms9918)
                        ? vrEmuTms9918RegValue(tmsDevice->tms9918, TMS_REG_7)
                        : TMS_BLACK) & 0x0f;

    //bgColor = (++c) & 0x0f;  /* for testing */
    int firstPix = 1;
    uint32_t* fbPtr = tmsDevice->frameBuffer + tmsDevice->currentFramePixels;

    int tmsRow = 0;

    /* iterate over the pixels we need to update in this call */
    for (int p = 0; p < thisStepTotalPixels; ++p)
    {
      div_t currentPos = div((int)tmsDevice->currentFramePixels, (int)TMS9918_DISPLAY_WIDTH);

      int currentRow = currentPos.quot;
      int currentCol = currentPos.rem;

      /* if this is the first pixel or the first pixel of a new row, update the scanline buffer */
      if (firstPix || currentCol == 0)
      {
        tmsRow = currentRow - TMS9918_BORDER_Y;
        memset(tmsDevice->scanlineBuffer, bgColor, sizeof(tmsDevice->scanlineBuffer));
        if (tmsRow >=0 && tmsRow < TMS9918_PIXELS_Y)
        {
          vrEmuTms9918ScanLine(tmsDevice->tms9918, (uint8_t)tmsRow, tmsDevice->scanlineBuffer + TMS9918_BORDER_X);
        }

        firstPix = 0;
      }

      /* update the frame buffer pixel from the scanline pixel */
      *(fbPtr++) = vrEmuTms9918Palette[tmsDevice->scanlineBuffer[currentCol]];

      /* if we're at the end of the main tms9918 frame, trigger an interrupt */
      if (++tmsDevice->currentFramePixels == (TMS9918_DISPLAY_WIDTH * (TMS9918_DISPLAY_HEIGHT - TMS9918_BORDER_Y)))
      {
        if (vrEmuTms9918DisplayEnabled(tmsDevice->tms9918) &&
            (vrEmuTms9918RegValue(tmsDevice->tms9918, TMS_REG_1) & 0x20))
        {
          hbc56Interrupt(tmsDevice->irq, INTERRUPT_RAISE);
        }
      }
    }

    /* reset pixel count if frame finished */
    if (tmsDevice->currentFramePixels >= TMS9918_DISPLAY_PIXELS) tmsDevice->currentFramePixels= 0;
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
      *val = vrEmuTms9918ReadStatus(tmsDevice->tms9918);
      if (!dbg) hbc56Interrupt(tmsDevice->irq, INTERRUPT_RELEASE);
      return 1;
    }
    else if (addr == tmsDevice->dataAddr)
    {
      if (dbg)
      {
        *val = vrEmuTms9918ReadDataNoInc(tmsDevice->tms9918);
      }
      else
      {
        *val = vrEmuTms9918ReadData(tmsDevice->tms9918);
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
      vrEmuTms9918WriteAddr(tmsDevice->tms9918, val);
      return 1;
    }
    else if (addr == tmsDevice->dataAddr)
    {
      vrEmuTms9918WriteData(tmsDevice->tms9918, val);
      return 1;
    }
  }
  return 0;
}

/* Function:  readTms9918Vram
 * --------------------
 * read a value from vram directly
 */
uint8_t readTms9918Vram(HBC56Device* device, uint16_t vramAddr)
{
  TMS9918Device* tmsDevice = getTms9918Device(device);
  if (tmsDevice)
  {
    return vrEmuTms9918VramValue(tmsDevice->tms9918, vramAddr);
  }
  return 0;
}

/* Function:  readTms9918Reg
 * --------------------
 * read a registry value directly
 */
uint8_t readTms9918Reg(HBC56Device* device, uint8_t reg)
{
  TMS9918Device* tmsDevice = getTms9918Device(device);
  if (tmsDevice)
  {
    return vrEmuTms9918RegValue(tmsDevice->tms9918, reg);
  }
  return 0;
}

/* Function:  writeTms9918Reg
 * --------------------
 * write a regiter value directly to the tms9918
 */
void writeTms9918Reg(HBC56Device* device, uint8_t reg, uint8_t value)
{
  TMS9918Device* tmsDevice = getTms9918Device(device);
  if (tmsDevice)
  {
    vrEmuTms9918WriteRegValue(tmsDevice->tms9918, reg, value);
  }
}
