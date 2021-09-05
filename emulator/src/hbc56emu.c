

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

byte ram[0x8000];
byte rom[0x8000];

uint16_t ioPage = 0x7f00;

#define TMS9918_DAT_ADDR 0x10
#define TMS9918_REG_ADDR 0x11
#define NES_IO_PORT 0x81

SDL_AudioDeviceID dev0;
SDL_AudioDeviceID dev1;


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

SDL_mutex* tmsMutex = NULL;
SDL_mutex* ay0Mutex = NULL;
SDL_mutex* ay1Mutex = NULL;


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

    case NES_IO_PORT:
    {
      const Uint8* keystate = SDL_GetKeyboardState(NULL);

      //continuous-response keys
      if (keystate[SDL_SCANCODE_LEFT])
      {
        val |= NES_LEFT;
      }
      if (keystate[SDL_SCANCODE_RIGHT])
      {
        val |= NES_RIGHT;
      }
      if (keystate[SDL_SCANCODE_UP])
      {
        val |= NES_B;
        val |= NES_UP;
      }
      if (keystate[SDL_SCANCODE_DOWN])
      {
        val |= NES_DOWN;
      }
      if (keystate[SDL_SCANCODE_A])
      {
        val |= NES_B;
      }
      if (keystate[SDL_SCANCODE_LSHIFT])
      {
        val |= NES_A;
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

  case (AY3891X_S0 | AY3891X_ADDR):
    psg0Addr = val;
    break;

  case (AY3891X_S0 | AY3891X_WRITE):
    if (SDL_LockMutex(ay0Mutex) == 0)
    {
      PSG_writeReg(psg0, psg0Addr, val);
      SDL_UnlockMutex(ay0Mutex);
    }
    break;

  case (AY3891X_S1 | AY3891X_ADDR):
    psg1Addr = val;
    break;

  case (AY3891X_S1 | AY3891X_WRITE):
    if (SDL_LockMutex(ay1Mutex) == 0)
    {
      PSG_writeReg(psg1, psg1Addr, val);
      SDL_UnlockMutex(ay1Mutex);
    }
    break;

  }

}

uint8_t mem_read(uint16_t addr)
{
  if (addr >= ioPage && addr <= ioPage + 255)
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
  if (addr >= ioPage && addr <= ioPage + 255)
  {
    io_write(addr & 0xff, val);
  }

  else if (addr < 0x8000)
  {
    ram[addr] = val;
  }
}


#define NUM_OBJECTS 100

static SDLCommonState* state;
static int num_objects;
static SDL_bool cycle_color;
static SDL_bool cycle_alpha;
static int cycle_direction = 1;
static int current_alpha = 255;
static int current_color = 255;
static SDL_BlendMode blendMode = SDL_BLENDMODE_NONE;

int done;


void hbc56Audio1Callback(
  void* userdata,
  Uint8* stream,
  int    len)
{
  int samples = len / sizeof(float);
  float*str = (float *)stream;
  if (SDL_LockMutex(ay1Mutex) == 0)
  {
    for (int i = 0; i < samples; ++i)
    {
      str[i] = ((float)PSG_calc(psg0)) / (float)0xffff;
    }
    SDL_UnlockMutex(ay1Mutex);
  }
}

void hbc56Audio0Callback(
  void* userdata,
  Uint8* stream,
  int    len)
{
  int samples = len / sizeof(float);
  float* str = (float*)stream;
  if (SDL_LockMutex(ay0Mutex) == 0)
  {
    for (int i = 0; i < samples; ++i)
    {
      str[i] = ((float)PSG_calc(psg1)) / (float)0xffff;
    }
    SDL_UnlockMutex(ay0Mutex);
  }
}


Uint32 lastRenderTicks = 0;
byte lineBuffer[TMS9918A_PIXELS_X];

Uint8 tms9918Reds[]   = {0x00, 0x00, 0x21, 0x5E, 0x54, 0x7D, 0xD3, 0x43, 0xFd, 0xFF, 0xD3, 0xE5, 0x21, 0xC9, 0xCC, 0xFF};
Uint8 tms9918Greens[] = {0x00, 0x00, 0xC9, 0xDC, 0x55, 0x75, 0x52, 0xEB, 0x55, 0x79, 0xC1, 0xCE, 0xB0, 0x5B, 0xCC, 0xFF};
Uint8 tms9918Blues[]  = {0x00, 0x00, 0x42, 0x78, 0xED, 0xFC, 0x4D, 0xF6, 0x54, 0x78, 0x53, 0x80, 0x3C, 0xBA, 0xCC, 0xFF};

int callCount = 0;
int numTicks = 0;
int triggerIrq = 0;


#define CLOCK_FREQ 4000000
#define AVG_CYCLE_COUNT 3

int SDLCALL cpuThread(void* unused)
{
  Uint64 lastTick = SDL_GetPerformanceCounter();
  Uint64 ticksPerClock = SDL_GetPerformanceFrequency() / (CLOCK_FREQ / AVG_CYCLE_COUNT);
  while (1)
  {
    Uint64 currentTick = SDL_GetPerformanceCounter();

    if (currentTick - lastTick < ticksPerClock)
      continue;

    lastTick = currentTick;

    if (triggerIrq)
    {
      cpu6502_irq();
      triggerIrq = 0;
      SDL_PauseAudioDevice(dev0, 0);
      SDL_PauseAudioDevice(dev1, 0);

    }

    cpu6502_single_step();

    ++numTicks;
  }
  return 0;
}

void
loop()
{
  int i;
  SDL_Event event;

  Uint32 currentTicks = SDL_GetTicks();
  if ((currentTicks - lastRenderTicks) < 16)
    return;

  lastRenderTicks = currentTicks;

  /* Check for events */

  for (i = 0; i < state->num_windows; ++i) {
    SDL_Renderer* renderer = state->renderers[i];
    if (state->windows[i] == NULL)
      continue;

    SDL_Rect viewport;
    //SDL_Rect rect;

    /* Query the sizes */
    SDL_RenderGetViewport(renderer, &viewport);


    for (int y = 0; y < 240; ++y)
    {
      int mainAreaRow = (y >= 24) && y < (TMS9918A_PIXELS_Y + 24);
      if (mainAreaRow)
      {
        if (SDL_LockMutex(tmsMutex) == 0)
        {
          vrEmuTms9918aScanLine(tms9918, y - 24, lineBuffer);
          SDL_UnlockMutex(tmsMutex);
        }
      }
      else if (y == TMS9918A_PIXELS_Y + 24)
      {
        /* are vsync interrupts enabled? */
        if (SDL_LockMutex(tmsMutex) == 0)
        {
          byte r1 = vrEmuTms9918aRegValue(tms9918, 1);
          if (r1 & 0x20)
          {
            triggerIrq = 1;
          }
          SDL_UnlockMutex(tmsMutex);
        }
      }

      for (int x = 0; x < 320; ++x)
      {
        int mainAreaCol = (x >= 32) && x < (TMS9918A_PIXELS_X + 32);
        if (mainAreaRow && mainAreaCol)
        {
          int color = lineBuffer[x - 32];
          SDL_SetRenderDrawColor(renderer, tms9918Reds[color], tms9918Greens[color], tms9918Blues[color], 255);
          SDL_RenderDrawPoint(renderer, x, y);
        }
        else
        {
          int color = 0;
          if (SDL_LockMutex(tmsMutex) == 0)
          {
            color = vrEmuTms9918aRegValue(tms9918, 7) & 0x0f;
            SDL_UnlockMutex(tmsMutex);
          }
          SDL_SetRenderDrawColor(renderer, tms9918Reds[color], tms9918Greens[color], tms9918Blues[color], 255);
          SDL_RenderDrawPoint(renderer, x, y);
        }
      }
    }
    SDL_RenderPresent(renderer);
  }

  while (SDL_PollEvent(&event)) {
    SDLCommonEvent(state, &event, &done);
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

  /* Initialize parameters */
  num_objects = NUM_OBJECTS;

  /* Initialize test framework */
  state = SDLCommonCreateState(argv, SDL_INIT_VIDEO | SDL_INIT_AUDIO);
  if (!state) {
    return 1;
  }
  for (i = 1; i < argc;) {
    int consumed;

    consumed = SDLCommonArg(state, i);
    if (consumed == 0) {
      consumed = -1;
      if (SDL_strcasecmp(argv[i], "--rom") == 0) {
        if (argv[i + 1]) {
          consumed = 1;
          FILE* ptr = NULL;

          fopen_s(&ptr, argv[i + 1], "rb");  // r for read, b for binary
          ++i;

          if (ptr)
          {
            fread(rom, 1, sizeof(rom), ptr);

            fclose(ptr);
          }
        }
      }
    }
    if (consumed < 0) {
      static const char* options[] = { "[--blend none|blend|add|mod]", "[--cyclecolor]", "[--cyclealpha]", NULL };
      SDLCommonLogUsage(state, argv[0], options);
      return 1;
    }
    i += consumed;
  }
  if (!SDLCommonInit(state)) {
    return 2;
  }

  /* Create the windows and initialize the renderers */
  for (i = 0; i < state->num_windows; ++i) {
    SDL_Renderer* renderer = state->renderers[i];
    SDL_RenderSetLogicalSize(renderer, 320, 240);
    SDL_SetRenderDrawBlendMode(renderer, blendMode);
    SDL_SetRenderDrawColor(renderer, 0xA0, 0xA0, 0xA0, 0xFF);
    SDL_RenderClear(renderer);
  }


  tmsMutex = SDL_CreateMutex();
  ay0Mutex = SDL_CreateMutex();
  ay1Mutex = SDL_CreateMutex();

  SDL_AudioSpec want, have;

  SDL_memset(&want, 0, sizeof(want)); /* or SDL_zero(want) */
  want.freq = 44100;
  want.format = AUDIO_F32LSB;
  want.channels = 1;
  want.samples = 800;
  want.callback = hbc56Audio0Callback;  // you wrote this function elsewhere.
  dev0 = SDL_OpenAudioDevice(NULL, 0, &want, &have, SDL_AUDIO_ALLOW_FORMAT_CHANGE);
  want.callback = hbc56Audio1Callback;  // you wrote this function elsewhere.
  dev1 = SDL_OpenAudioDevice(NULL, 0, &want, &have, SDL_AUDIO_ALLOW_FORMAT_CHANGE);

  srand((unsigned int)time(NULL));

  tms9918 = vrEmuTms9918aNew();
  cpu6502_rst();

  psg0 = PSG_new(2000000, have.freq);
  psg1 = PSG_new(2000000, have.freq);

  SDL_CreateThread(cpuThread, "CPU", NULL);

  /* Main render loop */
  frames = 0;
  then = SDL_GetTicks();
  done = 0;

  PSG_reset(psg0);
  PSG_reset(psg1);


#ifdef __EMSCRIPTEN__
  emscripten_set_main_loop(loop, 0, 1);
#else
  while (!done) {
    ++frames;
    loop();
}
#endif

  vrEmuTms9918aDestroy(tms9918);
  tms9918 = NULL;

  SDL_DestroyMutex(tmsMutex);
  tmsMutex = NULL;

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
