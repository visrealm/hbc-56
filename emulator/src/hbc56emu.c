/*
 * Troy's HBC-56 Emulator
 *
 * Copyright (c) 2021 Troy Schrapel
 *
 * This code is licensed under the MIT license
 *
 * https://github.com/visrealm/hbc-56/emulator
 *
 */


#include <stdlib.h>
#include <stdio.h>
#include <time.h>

#ifdef __EMSCRIPTEN__
#include <emscripten/emscripten.h>
#endif

#include "window.h"
#include "cpu6502.h"
#include "tms9918_core.h"
#include "emu2149.h"
#include "debugger.h"
#include "keyboard.h"
#include "lcd.h"

char winTitleBuffer[_MAX_PATH];


byte ram[0x8000];
byte rom[0x8000];

uint16_t ioPage = 0x7f00;

#define TMS9918_FPS 60
#define TMS9918_DAT_ADDR 0x10
#define TMS9918_REG_ADDR 0x11

// currently keyboard and NES use the same port (I haven't built separate hardware... yet)
// NES controller is the default.  Use the --keyboard command-line to enable the keyboard instead
#define NES_IO_PORT 0x81  
#define KB_IO_PORT 0x81

#define LCD_IO_PORT 0x02

#define LCD_IO_CMD   LCD_IO_PORT
#define LCD_IO_DATA  (LCD_IO_CMD | 0x01)


SDL_AudioDeviceID audioDevice;


#define NES_RIGHT  0b10000000
#define NES_LEFT   0b01000000
#define NES_DOWN   0b00100000
#define NES_UP     0b00010000
#define NES_START  0b00001000
#define NES_SELECT 0b00000100
#define NES_B      0b00000010
#define NES_A      0b00000001

VrEmuTms9918a *tms9918 = NULL;
PSG* psg0 = NULL;
PSG* psg1 = NULL;
LCDWindow *lcdw = NULL;

SDL_mutex* tmsMutex = NULL;
SDL_mutex* ayMutex = NULL;
SDL_mutex* debugMutex = NULL;

char kbQueue[16] = {0};
int kbStart = 0, kbEnd = 0;


#define AY3891X_IO_ADDR 0x40

#define AY3891X_PSG0 0x00
#define AY3891X_PSG1 0x04

#define AY3891X_S0 (AY3891X_IO_ADDR | AY3891X_PSG0)
#define AY3891X_S1 (AY3891X_IO_ADDR | AY3891X_PSG1)

#define AY3891X_INACTIVE 0x03
#define AY3891X_READ     0x02
#define AY3891X_WRITE    0x01
#define AY3891X_ADDR     0x00

byte psg0Addr = 0;
byte psg1Addr = 0;

byte kbReadCount = 0;
int keyboardMode = 0;

uint8_t io_read(uint8_t addr)
{
  uint8_t val = 0;
  switch (addr)
  {
    case TMS9918_DAT_ADDR:
      if (SDL_LockMutex(tmsMutex) == 0)
      {
        val = vrEmuTms9918aReadData(tms9918);
        SDL_UnlockMutex(tmsMutex);
      }
      break;

    case TMS9918_REG_ADDR:
      if (SDL_LockMutex(tmsMutex) == 0)
      {
        val = vrEmuTms9918aReadStatus(tms9918);
        SDL_UnlockMutex(tmsMutex);
      }
      break;

    case LCD_IO_CMD:
      if (lcdw && lcdw->lcd) val = vrEmuLcdReadAddress(lcdw->lcd);
      break;

    case LCD_IO_DATA:
      if (lcdw && lcdw->lcd) val = vrEmuLcdReadByte(lcdw->lcd);
      break;

    case NES_IO_PORT:  /* same as KB_IO_PORT */
    if (keyboardMode)
    {
      if (kbEnd != kbStart)
      {
        val = kbQueue[kbStart];

        if (++kbReadCount & 0x01)
        {
          ++kbStart;
          kbStart &= 0x0f;
        }

      }
    }
    else
    {
      const Uint8* keystate = SDL_GetKeyboardState(NULL);
      int isNumLockOff = (SDL_GetModState() & KMOD_NUM) == 0;

      //continuous-response keys
      if (keystate[SDL_SCANCODE_LEFT] || (keystate[SDL_SCANCODE_KP_4] && isNumLockOff))
      {
        val |= NES_LEFT;
      }
      if (keystate[SDL_SCANCODE_RIGHT] || (keystate[SDL_SCANCODE_KP_6] && isNumLockOff))
      {
        val |= NES_RIGHT;
      }
      if (keystate[SDL_SCANCODE_UP] || (keystate[SDL_SCANCODE_KP_8] && isNumLockOff))
      {
        val |= NES_UP;
      }
      if (keystate[SDL_SCANCODE_DOWN] || (keystate[SDL_SCANCODE_KP_2] && isNumLockOff))
      {
        val |= NES_DOWN;
      }
      if (keystate[SDL_SCANCODE_LCTRL] || keystate[SDL_SCANCODE_RCTRL])
      {
        val |= NES_B;
      }
      if (keystate[SDL_SCANCODE_LSHIFT] || keystate[SDL_SCANCODE_RSHIFT])
      {
        val |= NES_A;
      }
      if (keystate[SDL_SCANCODE_TAB])
      {
        val |= NES_SELECT;
      }
      if (keystate[SDL_SCANCODE_SPACE])
      {
        val |= NES_START;
      }

      val = ~val;
    }
    break;
  }

  return val;
}

void io_write(uint8_t addr, uint8_t val)
{
  switch (addr)
  {
  case TMS9918_DAT_ADDR:
    if (SDL_LockMutex(tmsMutex) == 0)
    {
      vrEmuTms9918aWriteData(tms9918, val);
      SDL_UnlockMutex(tmsMutex);
    }
    break;

  case TMS9918_REG_ADDR:
    if (SDL_LockMutex(tmsMutex) == 0)
    {
      vrEmuTms9918aWriteAddr(tms9918, val);
      SDL_UnlockMutex(tmsMutex);
    }
    break;

  case LCD_IO_CMD:
    if (lcdw && lcdw->lcd) vrEmuLcdSendCommand(lcdw->lcd, val);
    break;

  case LCD_IO_DATA:
    if (lcdw && lcdw->lcd) vrEmuLcdWriteByte(lcdw->lcd, val);
    break;

  case (AY3891X_S0 | AY3891X_ADDR):
    psg0Addr = val;
    break;

  case (AY3891X_S0 | AY3891X_WRITE):
    if (SDL_LockMutex(ayMutex) == 0)
    {
      PSG_writeReg(psg0, psg0Addr, val);
      SDL_UnlockMutex(ayMutex);
    }
    break;

  case (AY3891X_S1 | AY3891X_ADDR):
    psg1Addr = val;
    break;

  case (AY3891X_S1 | AY3891X_WRITE):
    if (SDL_LockMutex(ayMutex) == 0)
    {
      PSG_writeReg(psg1, psg1Addr, val);
      SDL_UnlockMutex(ayMutex);
    }
    break;

  }

}

uint8_t mem_read(uint16_t addr)
{
  if ((addr & 0xff00) == ioPage)
  {
    return io_read(addr & 0xff);
  }

  else if (addr < 0x8000)
  {
    return ram[addr];
  }
  else
  {
    return rom[addr & 0x7fff];
  }

  return 0;
}

void mem_write(uint16_t addr, uint8_t val)
{
  if ((addr & 0xff00) == ioPage)
  {
    io_write(addr & 0xff, val);
  }

  else if (addr < 0x8000)
  {
    ram[addr & 0x7fff] = val;
  }
}



static SDLCommonState* state;

int done;

void hbc56AudioCallback(
  void* userdata,
  Uint8* stream,
  int    len)
{
  int samples = len / (sizeof(float) * 2);
  float* str = (float*)stream;
  if (SDL_LockMutex(ayMutex) == 0)
  {
    for (int i = 0; i < samples; ++i)
    {
      PSG_calc(psg0);
      PSG_calc(psg1);

      int16_t l = psg0->ch_out[0] + psg1->ch_out[0] + (psg0->ch_out[2] + psg1->ch_out[2]);
      int16_t r = psg0->ch_out[1] + psg1->ch_out[1] + (psg0->ch_out[2] + psg1->ch_out[2]);

      str[i * 2] = ((float)l) / (float)SHRT_MAX;
      str[i * 2 + 1] = ((float)r) / (float)SHRT_MAX;
    }
    SDL_UnlockMutex(ayMutex);
  }
}

Uint32 lastRenderTicks = 0;
byte lineBuffer[TMS9918A_PIXELS_X];

Uint8 tms9918Reds[]   = {0x00, 0x00, 0x21, 0x5E, 0x54, 0x7D, 0xD3, 0x43, 0xFd, 0xFF, 0xD3, 0xE5, 0x21, 0xC9, 0xCC, 0xFF};
Uint8 tms9918Greens[] = {0x00, 0x00, 0xC9, 0xDC, 0x55, 0x75, 0x52, 0xEB, 0x55, 0x79, 0xC1, 0xCE, 0xB0, 0x5B, 0xCC, 0xFF};
Uint8 tms9918Blues[]  = {0x00, 0x00, 0x42, 0x78, 0xED, 0xFC, 0x4D, 0xF6, 0x54, 0x78, 0x53, 0x80, 0x3C, 0xBA, 0xCC, 0xFF};

int callCount = 0;
double currentFreq = 0.0;
int triggerIrq = 0;

Uint32 lastSecond = 0;

#define LOGICAL_DISPLAY_SIZE_X 320
#define LOGICAL_DISPLAY_SIZE_Y 240
#define LOGICAL_DISPLAY_BPP    3

#define LOGICAL_WINDOW_SIZE_X (LOGICAL_DISPLAY_SIZE_X * 2)
#define LOGICAL_WINDOW_SIZE_Y (LOGICAL_DISPLAY_SIZE_Y * 1.5)


#define TMS_OFFSET_X ((LOGICAL_DISPLAY_SIZE_X - TMS9918A_PIXELS_X) / 2)
#define TMS_OFFSET_Y ((LOGICAL_DISPLAY_SIZE_Y - TMS9918A_PIXELS_Y) / 2)

byte frameBuffer[LOGICAL_DISPLAY_SIZE_X * LOGICAL_DISPLAY_SIZE_Y * LOGICAL_DISPLAY_BPP];
byte debugFrameBuffer[DEBUGGER_WIDTH_PX * DEBUGGER_HEIGHT_PX * LOGICAL_DISPLAY_BPP];
SDL_Texture* screenTex = NULL;
SDL_Texture* debugWindowTex = NULL;
int debugWindowShown = 1;
int debugStep = 0;
int debugStepOver = 0;
int debugPaused = 0;

#define CLOCK_FREQ 4000000

int SDLCALL cpuThread(void* unused)
{
  double perfFreq = (double)SDL_GetPerformanceFrequency();
  double ticksPerClock = 1.0 / (double)CLOCK_FREQ;

  double lastTime = (double)SDL_GetPerformanceCounter() / perfFreq;
  double thisLoopStartTime = 0;
  double initialLastTime = 0;
  uint16_t breakPc = 0;

  while (1)
  {
    double currentTime = (double)SDL_GetPerformanceCounter() / perfFreq;
    Uint64 thisLoopTicks = 0;
    initialLastTime = lastTime;
    while (lastTime < currentTime)
    {
      if (triggerIrq)
      {
        cpu6502_irq();
        triggerIrq = 0;
      }

      if (SDL_LockMutex(debugMutex) == 0)
      {
        if (debugStepOver && !breakPc)
        {
          if (mem_read(cpu6502_get_regs()->pc) == 0x20)
          {
            breakPc = cpu6502_get_regs()->pc + 3;
          }
          debugStepOver = 0;
        }

        if (!debugPaused || debugStep || breakPc)
        {
          thisLoopTicks += cpu6502_single_step();
          debugStep = 0;
          if (cpu6502_get_regs()->pc == breakPc)
          {
            breakPc = 0;
          }
          else if (cpu6502_get_regs()->lastOpcode == 0xDB)
          {
            debugPaused = debugWindowShown = 1;
          }
        }
        SDL_UnlockMutex(debugMutex);
      }
      lastTime = initialLastTime + (thisLoopTicks * ticksPerClock);

    }

    SDL_Delay(1);

    double tmpFreq = (double)SDL_GetPerformanceCounter() / perfFreq - currentTime;
    currentFreq = currentFreq * 0.9 + (((double)thisLoopTicks / tmpFreq) / 1000000.0) * 0.1;
  }
  return 0;
}


void hbc56Reset()
{
  kbStart = 0;
  kbEnd = 0;

  cpu6502_rst();
  PSG_reset(psg0);
  PSG_reset(psg1);
}


void
loop()
{
  int i;
  SDL_Event event;

  Uint32 currentTicks = SDL_GetTicks();
  if ((currentTicks - lastRenderTicks) < 15)//(1000 / TMS9918_FPS))
    return;

  lastRenderTicks = lastRenderTicks + 15;//(1000 / TMS9918_FPS);
  Uint32 currentSecond = currentTicks / 1000;

  /* Check for events */

  for (i = 0; i < state->num_windows; ++i) {
    SDL_Renderer* renderer = state->renderers[i];
    if (state->windows[i] == NULL)
      continue;

    SDL_Rect viewport;
    //SDL_Rect rect;

    /* Query the sizes */
    SDL_RenderGetViewport(renderer, &viewport);
    
    byte *fbPtr = frameBuffer - 1;

    for (int y = 0; y < LOGICAL_DISPLAY_SIZE_Y; ++y)
    {
      int mainAreaRow = (y >= TMS_OFFSET_Y) && y < (TMS9918A_PIXELS_Y + TMS_OFFSET_Y);
      if (mainAreaRow)
      {
        vrEmuTms9918aScanLine(tms9918, y - TMS_OFFSET_Y, lineBuffer);
      }
      else if (y == TMS9918A_PIXELS_Y + TMS_OFFSET_Y)
      {
        /* are vsync interrupts enabled? */
        byte r1 = vrEmuTms9918aRegValue(tms9918, 1);
        if (r1 & 0x20)
        {
          triggerIrq = 1;
        }
      }

      for (int x = 0; x < LOGICAL_DISPLAY_SIZE_X; ++x)
      {
        int mainAreaCol = (x >= TMS_OFFSET_X) && x < (TMS9918A_PIXELS_X + TMS_OFFSET_X);
        int color = 0;
        if (mainAreaRow && mainAreaCol)
        {
          color = lineBuffer[(x - TMS_OFFSET_X) & 0xff];
        }
        else
        {
          color = vrEmuTms9918aRegValue(tms9918, 7) & 0x0f;
        }
        *(++fbPtr) = tms9918Reds[color];
        *(++fbPtr) = tms9918Greens[color];
        *(++fbPtr) = tms9918Blues[color];
      }
    }
    SDL_UpdateTexture(screenTex, NULL, frameBuffer, LOGICAL_DISPLAY_SIZE_X * LOGICAL_DISPLAY_BPP);

    SDL_Rect dest;
    dest.x = (int)(LOGICAL_DISPLAY_SIZE_X * 1.5 - LOGICAL_DISPLAY_SIZE_X) / 2;
    dest.y = 0;
    dest.w = (int)(LOGICAL_DISPLAY_SIZE_X * 1.5);
    dest.h = (int)(LOGICAL_WINDOW_SIZE_Y);
    if (debugWindowShown)
    {
      dest.x = 0;
    }

    SDL_RenderClear(renderer);
    SDL_RenderCopy(renderer, screenTex, NULL, &dest);

    if (debugWindowShown)
    {
      for (int i = 0; i < sizeof(debugFrameBuffer); ++i)
      {
        debugFrameBuffer[i] = i & 0xff;
      }

      debuggerUpdate(debugWindowTex);//, NULL, debugFrameBuffer, DEBUGGER_WIDTH_PX * LOGICAL_DISPLAY_BPP);
      dest.x = dest.w;
      dest.w = (int)(DEBUGGER_WIDTH_PX * .5);
      dest.h = (int)(DEBUGGER_HEIGHT_PX * .5);
      SDL_RenderCopy(renderer, debugWindowTex, NULL, &dest);
    }

    SDL_RenderPresent(renderer);
  }

  lcdWindowUpdate(lcdw);

  while (SDL_PollEvent(&event)) {
    switch (event.type) {
      case SDL_KEYDOWN:
        {
          SDL_bool withControl = (event.key.keysym.mod & KMOD_CTRL) ? 1 : 0;

          if (event.key.keysym.sym == SDLK_F5) break;
          if (event.key.keysym.sym == SDLK_F10) break;
          if (event.key.keysym.sym == SDLK_F11) break;
          if (event.key.keysym.sym == SDLK_F12) break;
          if (withControl && event.key.keysym.sym == SDLK_r)
          {
            break;
          }

          uint64_t ps2ScanCode = sdl2ps2map[event.key.keysym.scancode][0];
          for (int i = 0; i < 8; ++i)
          {
            uint8_t scanCodeByte = (ps2ScanCode & 0xff00000000000000) >> 56;
            if (scanCodeByte)
            {
              kbQueue[kbEnd++] = scanCodeByte; kbEnd &= 0x0f;
            }
            ps2ScanCode <<= 8;
          }
        }
        break;

      case SDL_KEYUP:
        {
          SDL_bool withControl = (event.key.keysym.mod & KMOD_CTRL) ? 1 : 0;
          if (event.key.keysym.sym == SDLK_F5) break;
          if (event.key.keysym.sym == SDLK_F10) break;
          if (event.key.keysym.sym == SDLK_F11) break;
          if (event.key.keysym.sym == SDLK_F12) break;
          if (withControl && event.key.keysym.sym == SDLK_r)
          {
            hbc56Reset();
            break;
          }
          if (event.key.keysym.sym == SDLK_LCTRL) break;
          if (event.key.keysym.sym == SDLK_RCTRL) break;

          uint64_t ps2ScanCode = sdl2ps2map[event.key.keysym.scancode][1];
          for (int i = 0; i < 8; ++i)
          {
            uint8_t scanCodeByte = (ps2ScanCode & 0xff00000000000000) >> 56;
            if (scanCodeByte)
            {
              kbQueue[kbEnd++] = scanCodeByte; kbEnd &= 0x0f;
            }
            ps2ScanCode <<= 8;
          }
        }
        break;
    }


    SDLCommonEvent(state, &event, &done);
  }

  if (currentSecond != lastSecond)
  {
    char tempTitleBuffer[_MAX_PATH];
    SDL_snprintf(tempTitleBuffer, sizeof(tempTitleBuffer), "%s (%.3f MHz)", winTitleBuffer, currentFreq);
    for (i = 0; i < state->num_windows; ++i) 
      SDL_SetWindowTitle(state->windows[i], tempTitleBuffer);

    lastSecond = currentSecond;
  }


#ifdef __EMSCRIPTEN__
  if (done) {
    emscripten_cancel_main_loop();
  }
#endif
}


int
main(int argc, char* argv[])
{
  int i;
  Uint32 then, now, frames;

  /* Enable standard application logging */
  SDL_LogSetPriority(SDL_LOG_CATEGORY_APPLICATION, SDL_LOG_PRIORITY_INFO);

  SDL_snprintf(winTitleBuffer, sizeof(winTitleBuffer), "Troy's HBC-56 Emulator");

  char labelMapFile[FILENAME_MAX] = {0};

  memset(ram, 0xff, sizeof(ram));
  memset(rom, 0xff, sizeof(rom));

  /* Initialize test framework */
  state = SDLCommonCreateState(argv, SDL_INIT_VIDEO | SDL_INIT_AUDIO);
  if (!state) {
    return 1;
  }
  int romLoaded = 0;
  LCDType lcdType = LCD_NONE;
  for (i = 1; i < argc;) {
    int consumed;

    consumed = SDLCommonArg(state, i);
    if (consumed <= 0) {
      consumed = -1;
      if (SDL_strcasecmp(argv[i], "--rom") == 0) {
        if (argv[i + 1]) {
          consumed = 1;
          FILE* ptr = NULL;

          fopen_s(&ptr, argv[i + 1], "rb");  // r for read, b for binary
          SDL_snprintf(winTitleBuffer, sizeof(winTitleBuffer), "Troy's HBC-56 Emulator - %s", argv[i + 1]);

          if (ptr)
          {
            size_t romBytesRead = fread(rom, 1, sizeof(rom), ptr);
            fclose(ptr);

            if (romBytesRead != sizeof(rom))
            {
              SDL_snprintf(winTitleBuffer, sizeof(winTitleBuffer), "Error. ROM file '%s' must be %d bytes.", argv[i + 1], (int)sizeof(rom));
              SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR, "Troy's HBC-56 Emulator", winTitleBuffer, NULL);
            }
            else
            {
              romLoaded = 1;
              SDL_strlcpy(labelMapFile, argv[i + 1], FILENAME_MAX);
              size_t ln = SDL_strlen(labelMapFile);
              SDL_strlcpy(labelMapFile + ln - 2, ".o.lmap", FILENAME_MAX - ln);
            }
          }
          else
          {
            SDL_snprintf(winTitleBuffer, sizeof(winTitleBuffer), "Error. ROM file '%s' does not exist.", argv[i + 1]);
            SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR, "Troy's HBC-56 Emulator", winTitleBuffer, NULL);
            return 2;
          }

          ++i;
        }
      }
      /* start paused? */
      else if (SDL_strcasecmp(argv[i], "--brk") == 0)
      {
        consumed = 1;
        debugPaused = 1;
      }
      /* use keyboard instead of NES controller */
      else if (SDL_strcasecmp(argv[i], "--keyboard") == 0)
      {
        consumed = 1;
        keyboardMode = 1;
      }
      /* enable the lcd? */
      else if (SDL_strcasecmp(argv[i], "--lcd") == 0)
      {
        if (argv[i + 1])
        {
          consumed = 1;
          switch (atoi(argv[i + 1]))
          {
            case 1602:
              lcdType = LCD_1602;
              break;
            case 2004:
              lcdType = LCD_2004;
              break;
            case 12864:
              lcdType = LCD_GRAPHICS;
              break;
          }
          ++i;
        }
      }
    }
    if (consumed < 0) {
      static const char* options[] = { "--rom <romfile>","[--brk]","[--keyboard]", NULL};
      SDLCommonLogUsage(state, argv[0], options);
      return 2;
    }
    i += consumed;
  }

  if (romLoaded == 0) {
    static const char* options[] = { "--rom <romfile>","[--brk]","[--keyboard]","[--lcd 1602|2004|12864]", NULL};
    SDLCommonLogUsage(state, argv[0], options);

    SDL_snprintf(winTitleBuffer, sizeof(winTitleBuffer), "No HBC-56 ROM file.\n\nUse --rom <romfile>");
    SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR, "Troy's HBC-56 Emulator", winTitleBuffer, NULL);

    return 2;
  }

  state->window_title = winTitleBuffer;

  if (!SDLCommonInit(state)) {
    return 2;
  }

  /* Create the windows and initialize the renderers */
  for (i = 0; i < state->num_windows; ++i) {
    SDL_Renderer* renderer = state->renderers[i];
    SDL_RenderSetLogicalSize(renderer, DEFAULT_WINDOW_WIDTH / 2, DEFAULT_WINDOW_HEIGHT / 2);
    SDL_SetRenderDrawColor(renderer, 0,0,0, 0xFF);
    SDL_RenderClear(renderer);
    screenTex = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGB24, SDL_TEXTUREACCESS_STREAMING, LOGICAL_DISPLAY_SIZE_X, LOGICAL_DISPLAY_SIZE_Y);
    
    SDL_SetTextureScaleMode(screenTex, SDL_ScaleModeBest); // remove this for sharp scaling

    debugWindowTex = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGB24, SDL_TEXTUREACCESS_STREAMING, DEBUGGER_WIDTH_PX, DEBUGGER_HEIGHT_PX);
    memset(frameBuffer, 0, sizeof(frameBuffer));
  }


  tmsMutex = SDL_CreateMutex();
  ayMutex = SDL_CreateMutex();
  debugMutex = SDL_CreateMutex();

  SDL_AudioSpec want, have;

  SDL_memset(&want, 0, sizeof(want));
  want.freq = 44100;
  want.format = AUDIO_F32SYS;
  want.channels = 2;
  want.samples = want.freq / TMS9918_FPS;
  want.callback = hbc56AudioCallback;
  audioDevice = SDL_OpenAudioDevice(NULL, 0, &want, &have, SDL_AUDIO_ALLOW_FORMAT_CHANGE);

  srand((unsigned int)time(NULL));

  tms9918 = vrEmuTms9918aNew();

  psg0 = PSG_new(2000000, have.freq);
  psg1 = PSG_new(2000000, have.freq);

  SDL_CreateThread(cpuThread, "CPU", NULL);

  /* Main render loop */
  frames = 0;
  then = SDL_GetTicks();
  done = 0;

  hbc56Reset();

  debuggerInit(cpu6502_get_regs(), labelMapFile, tms9918);

  SDL_PauseAudioDevice(audioDevice, 0);

  lcdw = lcdWindowCreate(lcdType);

//  SDL_CreateWindow("Debugger", 50, 50, 320, 200, 0);


#ifdef __EMSCRIPTEN__
  emscripten_set_main_loop(loop, 0, 1);
#else
  while (!done) {
    ++frames;
    loop();
    SDL_Delay(1);
}
#endif

  vrEmuTms9918aDestroy(tms9918);
  tms9918 = NULL;

  SDL_DestroyMutex(tmsMutex);
  tmsMutex = NULL;

  lcdWindowDestroy(lcdw);
  lcdw = NULL;

  SDLCommonQuit(state);


  /* Print out some timing information */
  now = SDL_GetTicks();
  if (now > then) {
    double fps = ((double)frames * 1000) / (now - then);
    SDL_Log("%2.2f frames per second\n", fps);
  }
  return 0;
}

/* vi: set ts=4 sw=4 expandtab: */
