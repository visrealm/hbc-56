#include "lcd.h"
#include <memory.h>

LCDWindow* lcdWindowCreate(LCDType lcdType) {

  LCDWindow* lcdw = (LCDWindow*)malloc(sizeof(LCDWindow));
  if (lcdw != NULL)
  {
    switch (lcdType)
    {
      case LCD_1602:
        lcdw->lcd = vrEmuLcdNew(16, 2, EmuLcdRomA00);
        break;

      case LCD_2004:
        lcdw->lcd = vrEmuLcdNew(20, 4, EmuLcdRomA00);
        break;

      case LCD_GRAPHICS:
        lcdw->lcd = vrEmuLcdNew(128, 64, EmuLcdRomA00);
        break;
      
      default:
        free(lcdw);
        return NULL;
    }

    int scale = 5;

    size_t nativeWidth = vrEmuLcdNumPixelsX(lcdw->lcd);
    size_t nativeHeight = vrEmuLcdNumPixelsY(lcdw->lcd);

    Uint32 windowFlags = 0;
    lcdw->window = SDL_CreateWindow("HBC-56 LCD Display", 50, 50,
                              nativeWidth * scale,
                              nativeHeight * scale,
                              windowFlags);


    lcdw->renderer = SDL_CreateRenderer(lcdw->window, -1, SDL_RENDERER_SOFTWARE);
    SDL_RenderSetLogicalSize(lcdw->renderer, nativeWidth, nativeHeight);
    SDL_SetRenderDrawColor(lcdw->renderer, 0xA8, 0xC6, 0x4E, 0xFF);
    SDL_RenderClear(lcdw->renderer);
    lcdw->tex = SDL_CreateTexture(lcdw->renderer, SDL_PIXELFORMAT_RGB24, SDL_TEXTUREACCESS_STREAMING, nativeWidth, nativeHeight);
    lcdw->frameBuffer = malloc(nativeWidth * nativeHeight * 3);
    if (lcdw->frameBuffer) memset(lcdw->frameBuffer, 0, nativeWidth * nativeHeight * 3);

    lcdWindowUpdate(lcdw);
  }

  return lcdw;  
}

void lcdWindowDestroy(LCDWindow* lcdw)
{
  if (lcdw)
  {
    VrEmuLcd *tmpLcd = lcdw->lcd;
    lcdw->lcd= NULL;

    vrEmuLcdDestroy(tmpLcd);
    SDL_DestroyRenderer(lcdw->renderer);
    SDL_DestroyTexture(lcdw->tex);
    SDL_DestroyWindow(lcdw->window);
    free(lcdw->frameBuffer);
    free(lcdw);
  }
}

static lcdColors[3][3] = {{0x7d, 0xbe, 0x00},  /* no pixel */
                          {0x6f, 0xb9, 0x00},  /* off */
                          {0x2c, 0x24, 0x00}}; /* on */

void lcdWindowUpdate(LCDWindow* lcdw) {
  if (lcdw && lcdw->lcd)
  {
    vrEmuLcdUpdatePixels(lcdw->lcd);

    int w = vrEmuLcdNumPixelsX(lcdw->lcd);
    int h = vrEmuLcdNumPixelsY(lcdw->lcd);

    char *ptr = lcdw->frameBuffer - 1;

    for (int y = 0; y < h; ++y)
    {
      for (int x = 0; x < w; ++x)
      {
        char state = vrEmuLcdPixelState(lcdw->lcd, x, y);

        ++state;

        *(++ptr) = lcdColors[state][0];
        *(++ptr) = lcdColors[state][1];
        *(++ptr) = lcdColors[state][2];
      }
    }

    SDL_UpdateTexture(lcdw->tex, NULL, lcdw->frameBuffer, w * 3);
    SDL_RenderCopy(lcdw->renderer, lcdw->tex, NULL, NULL);

    SDL_RenderPresent(lcdw->renderer);

  }

}
