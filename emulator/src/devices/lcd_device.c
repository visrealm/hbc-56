/*
 * Troy's HBC-56 Emulator - character lcd device
 *
 * Copyright (c) 2021 Troy Schrapel
 *
 * This code is licensed under the MIT license
 *
 * https://github.com/visrealm/hbc-56/emulator
 *
 */

#include "lcd_device.h"

#include "vrEmuLcd.h"

#include "SDL.h"

#include <stdlib.h>
#include <string.h>
#include <math.h>

extern void cpu6502_irq(void);

static void resetLcdDevice(HBC56Device*);
static void destroyLcdDevice(HBC56Device*);
static void renderLcdDevice(HBC56Device* device);
static uint8_t readLcdDevice(HBC56Device*, uint16_t, uint8_t*, uint8_t);
static uint8_t writeLcdDevice(HBC56Device*, uint16_t, uint8_t);

/* lcd constants */
#define LCD_PIXEL_SCALE     5
#define LCD_BORDER_X        5
#define LCD_BORDER_Y        5

typedef enum
{
  LCD_PIXEL_NONE,
  LCD_PIXEL_OFF,
  LCD_PIXEL_ON
} LCDPixelState;


/* lcd palette */
static const uint32_t lcdPal[] = {
  0x7dbe00ff, /* no pixel  */
  0x5fa900ff, /* pixel off */
  0x000000ff  /* pixel on  */
};

/* lcd device data */
struct LCDDevice
{
  uint16_t       dataAddr;
  uint16_t       cmdAddr;
  VrEmuLcd      *lcd;
  int            pixelsX;
  int            pixelsY;
  uint32_t      *frameBuffer;
  SDL_Texture   *hiddenOutput;
};
typedef struct LCDDevice LCDDevice;


 /* Function:  createLcdDevice
  * --------------------
  * create a LCD device
  */
HBC56Device createLcdDevice(LCDType type, uint16_t dataAddr, uint16_t cmdAddr, SDL_Renderer* renderer)
{
  HBC56Device device = createDevice("LCD");
  LCDDevice* lcdDevice = (LCDDevice*)malloc(sizeof(LCDDevice));
  if (lcdDevice)
  {
    lcdDevice->dataAddr = dataAddr;
    lcdDevice->cmdAddr = cmdAddr;

    switch (type)
    {
      case LCD_1602:
        lcdDevice->lcd = vrEmuLcdNew(16, 2, EmuLcdRomA00);
        device.name = "LCD (1602)";
        break;

      case LCD_2004:
        lcdDevice->lcd = vrEmuLcdNew(20, 4, EmuLcdRomA00);
        device.name = "LCD (2004)";
        break;

      case LCD_GRAPHICS:
        lcdDevice->lcd = vrEmuLcdNew(128, 64, EmuLcdRomA00);
        device.name = "LCD (12864B)";
        break;

      default:
        lcdDevice->lcd = NULL;
        break;
    }

    if (lcdDevice->lcd)
    {
      int nativeWidth = vrEmuLcdNumPixelsX(lcdDevice->lcd);
      int nativeHeight = vrEmuLcdNumPixelsY(lcdDevice->lcd);

      lcdDevice->pixelsX = (nativeWidth + (LCD_BORDER_X * 2)) * LCD_PIXEL_SCALE;
      lcdDevice->pixelsY = (nativeHeight + (LCD_BORDER_Y * 2)) * LCD_PIXEL_SCALE;

      size_t numPixels = (size_t)lcdDevice->pixelsX * (size_t)lcdDevice->pixelsY;
      lcdDevice->frameBuffer = malloc(numPixels * sizeof(uint32_t));
      
      if (lcdDevice->frameBuffer)
      {
        for (size_t i = 0; i < numPixels; ++i)
        {
          lcdDevice->frameBuffer[i] = lcdPal[LCD_PIXEL_NONE];
        }
      }
      else
      {
        destroyDevice(&device);
        return device;
      }

      device.data = lcdDevice;
      device.destroyFn = &destroyLcdDevice;
      device.resetFn = &resetLcdDevice;
      device.readFn = &readLcdDevice;
      device.writeFn = &writeLcdDevice;
      device.renderFn = &renderLcdDevice;

      lcdDevice->hiddenOutput = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_STREAMING,
                                          lcdDevice->pixelsX, lcdDevice->pixelsY);
      #ifndef __CLANG__   // this doesn't work under linux
      SDL_SetTextureScaleMode(lcdDevice->hiddenOutput, SDL_ScaleModeBest);
      #endif
    }
  }
  else
  {
    destroyDevice(&device);
  }

  return device;
}


/* Function:  getLcdDevice
 * --------------------
 * helper funtion to get private structure
 */
inline static LCDDevice* getLcdDevice(HBC56Device* device)
{
  if (!device) return NULL;
  return (LCDDevice*)device->data;
}

/* Function:  resetLcdDevice
 * --------------------
 * reset the lcd data structure
 */
static void resetLcdDevice(HBC56Device* device)
{
  LCDDevice* lcdDevice = getLcdDevice(device);
  if (lcdDevice)
  {
    device->output = NULL;
  }
}

/* Function:  destroyLcdDevice
 * --------------------
 * destroy/clean up the lcd data structure
 */
static void destroyLcdDevice(HBC56Device *device)
{
  LCDDevice *lcdDevice = getLcdDevice(device);
  if (lcdDevice)
  {
    vrEmuLcdDestroy(lcdDevice->lcd);
    lcdDevice->lcd = NULL;

    free(lcdDevice->frameBuffer);
    lcdDevice->frameBuffer = NULL;

    SDL_DestroyTexture(lcdDevice->hiddenOutput);
    lcdDevice->hiddenOutput = NULL;
  }
  free(lcdDevice);
  device->data = NULL;

  device->output = NULL;
}

/* Function:  renderLcdDevice
 * --------------------
 * renders the LCD to the output texture
 */
static void renderLcdDevice(HBC56Device* device)
{
  LCDDevice* lcdDevice = getLcdDevice(device);
  if (lcdDevice)
  {
    if (device->output)
    {
      vrEmuLcdUpdatePixels(lcdDevice->lcd);

      int w = vrEmuLcdNumPixelsX(lcdDevice->lcd);
      int h = vrEmuLcdNumPixelsY(lcdDevice->lcd);

      uint32_t* fbPtr = (lcdDevice->frameBuffer - 1)
                            + (LCD_BORDER_X * LCD_PIXEL_SCALE) 
                            + (LCD_BORDER_Y * LCD_PIXEL_SCALE * lcdDevice->pixelsX);

      for (int y = 0; y < h; ++y)
      {
        for (int x = 0; x < w; ++x)
        {
          uint32_t  currentColor = lcdPal[vrEmuLcdPixelState(lcdDevice->lcd, x, y) + 1];

          for (int iy = 0; iy < LCD_PIXEL_SCALE - 1; ++iy)
          {
            uint32_t* ptr = fbPtr + iy * lcdDevice->pixelsX;

            for (int ix = 0; ix < LCD_PIXEL_SCALE - 1; ++ix)
            {
              *(++ptr) = currentColor;
            }
          }

          fbPtr += LCD_PIXEL_SCALE;
        }
      
        fbPtr += LCD_PIXEL_SCALE * lcdDevice->pixelsX - w * LCD_PIXEL_SCALE;
      }

      void* pixels = NULL;
      int pitch = 0;
      SDL_LockTexture(device->output, NULL, &pixels, &pitch);
      memcpy(pixels, lcdDevice->frameBuffer, lcdDevice->pixelsX * lcdDevice->pixelsY * sizeof(uint32_t));
      SDL_UnlockTexture(device->output);
    }
  }
}

/* Function:  readLcdDevice
 * --------------------
 * read from the lcd. address determines status or data
 */
static uint8_t readLcdDevice(HBC56Device* device, uint16_t addr, uint8_t *val, uint8_t dbg)
{
  LCDDevice* lcdDevice = getLcdDevice(device);
  if (lcdDevice && val)
  {
    if (addr == lcdDevice->cmdAddr)
    {
      *val = vrEmuLcdReadAddress(lcdDevice->lcd);
      return 1;
    }
    else if (addr == lcdDevice->dataAddr)
    {
      if (dbg)
      {
        *val = vrEmuLcdReadByteNoInc(lcdDevice->lcd);
      }
      else
      {
        *val = vrEmuLcdReadByte(lcdDevice->lcd);
      }
      return 1;
    }
  }
  return 0;
}

/* Function:  writeLcdDevice
 * --------------------
 * write to the lcd. address determines address/register or data
 */
static uint8_t writeLcdDevice(HBC56Device* device, uint16_t addr, uint8_t val)
{
  LCDDevice* lcdDevice = getLcdDevice(device);
  if (lcdDevice)
  {
    if (addr == lcdDevice->cmdAddr)
    {
      device->output = lcdDevice->hiddenOutput;
      vrEmuLcdSendCommand(lcdDevice->lcd, val);
      return 1;
    }
    else if (addr == lcdDevice->dataAddr)
    {
      vrEmuLcdWriteByte(lcdDevice->lcd, val);
      return 1;
    }
  }
  return 0;
}
