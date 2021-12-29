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


#ifdef __EMSCRIPTEN__
#include <emscripten/emscripten.h>
#endif

#include "config.h"
#include "window.h"
#include "cpu6502.h"

#include "debugger/debugger.h"

#include "devices/memory_device.h"
#include "devices/tms9918_device.h"
#include "devices/lcd_device.h"
#include "devices/keyboard_device.h"
#include "devices/nes_device.h"
#include "devices/ay38910_device.h"

#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <string.h>

extern uint16_t debugMemoryAddr;
extern uint16_t debugTmsMemoryAddr;

#ifndef _MAX_PATH 
#define _MAX_PATH 256
#endif

char winTitleBuffer[_MAX_PATH];

#define MAX_DEVICES 16
HBC56Device devices[MAX_DEVICES];
int deviceCount = 0;

SDL_AudioDeviceID audioDevice = 0;

int keyboardMode = 0;

uint8_t mem_read_impl(uint16_t addr, int dbg)
{
  uint8_t val = 0xff;
  for (size_t i = 0; i < deviceCount; ++i)
  {
    if (readDevice(&devices[i], addr, &val, dbg))
      break;
  }

  return val;
}


uint8_t mem_read(uint16_t addr) {
  return mem_read_impl(addr, 0);
}

uint8_t mem_read_dbg(uint16_t addr) {
  return mem_read_impl(addr, 1);
}

void mem_write(uint16_t addr, uint8_t val)
{
  for (size_t i = 0; i < deviceCount; ++i)
  {
    if (writeDevice(&devices[i], addr, val))
      break;
  }
}


static SDLCommonState* state;

int done;
int completedWarmUpSamples = 0;

void hbc56AudioCallback(
  void* userdata,
  Uint8* stream,
  int    len)
{
  int samples = len / (sizeof(float) * 2);
  float* str = (float*)stream;

  memset(str, 0, len);

  for (size_t i = 0; i < deviceCount; ++i)
  {
    renderAudioDevice(&devices[i], str, samples);
  }
}


void hbc56Audio(int start)
{
  if (start)
  {
    SDL_InitSubSystem(SDL_INIT_AUDIO);

    SDL_AudioSpec want, have;

    SDL_memset(&want, 0, sizeof(want));
    want.freq = HBC56_AUDIO_FREQ;
    want.format = AUDIO_F32SYS;
    want.channels = 2;
    want.samples = want.freq / 60;
    want.callback = hbc56AudioCallback;
    audioDevice = SDL_OpenAudioDevice(NULL, 0, &want, &have, 0);
    SDL_PauseAudioDevice(audioDevice, 0);
  }
  else
  {
    SDL_PauseAudioDevice(audioDevice, 1);
    SDL_CloseAudioDevice(audioDevice);
  }
}


uint64_t totalCpuTicks = 0;
Uint32 lastRenderTicks = 0;

int callCount = 0;
double perfFreq = 0.0;
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

uint8_t debugFrameBuffer[DEBUGGER_WIDTH_PX * DEBUGGER_HEIGHT_PX * LOGICAL_DISPLAY_BPP];
SDL_Texture* debugWindowTex = NULL;
int debugWindowShown = 1;
int debugStep = 0;
int debugStepOver = 0;
int debugPaused = 0;
int debugStepOut = 0;
uint16_t callStack[128] = { 0 };
int callStackPtr = 0;

#if HBC56_HAVE_THREADS

int SDLCALL cpuThread(void* unused)
{
#endif
  double ticksPerClock = 1.0 / (double)HBC56_CLOCK_FREQ;

  double lastTime = 0.0;
  double thisLoopStartTime = 0;
  double initialLastTime = 0;
  uint16_t breakPc = 0;

#if !HBC56_HAVE_THREADS
  void cpuTick()
  {
#else
  while (1)
  {
#endif
    if (lastTime == 0.0)
    {
      lastTime = (double)SDL_GetPerformanceCounter() / perfFreq;
    }

    double currentTime = (double)SDL_GetPerformanceCounter() / perfFreq;
    Uint64 thisLoopTicks = 0;
    initialLastTime = lastTime;
    while (lastTime < currentTime)
    {
      if (triggerIrq && !debugPaused)
      {
        cpu6502_irq();
        triggerIrq = 0;
      }

      uint8_t opcode = mem_read(cpu6502_get_regs()->pc);
      int isJsr = (opcode == 0x20);
      int isRts = (opcode == 0x60);

      if (debugStepOver && !breakPc)
      {
        if (isJsr)
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
      lastTime = initialLastTime + (thisLoopTicks * ticksPerClock);
#if !HBC56_HAVE_THREADS
      if (debugPaused) break;
#endif
    }

    totalCpuTicks += thisLoopTicks;

    //SDL_Delay(1);

    double tmpFreq = (double)SDL_GetPerformanceCounter() / perfFreq - currentTime;
    currentFreq = currentFreq * 0.9 + (((double)thisLoopTicks / tmpFreq) / 1000000.0) * 0.1;
  }
#if HBC56_HAVE_THREADS
  return 0;
  }
#endif

void hbc56Reset()
{
  debugPaused = 0;

  for (size_t i = 0; i < deviceCount; ++i)
  {
    resetDevice(&devices[i]);
  }

  cpu6502_rst();
}


double mainLoopLastTime = 0.0;
uint64_t mainLoopLastTicks = 0;

void doTick()
{
  double thisTime = (double)SDL_GetPerformanceCounter() / perfFreq;

  if (mainLoopLastTime != 0)
  {
    for (size_t i = 0; i < deviceCount; ++i)
    {
      tickDevice(&devices[i], (uint32_t)(totalCpuTicks - mainLoopLastTicks), thisTime - mainLoopLastTime);
    }
  }

  mainLoopLastTime = thisTime;
  mainLoopLastTicks = totalCpuTicks;

}

void doRender()
{
  SDL_RenderClear(state->renderers[0]);

  SDL_Rect dest;
  dest.x = 0;
  dest.y = 0;
  dest.w = (int)(LOGICAL_DISPLAY_SIZE_X * 3);
  dest.h = (int)(LOGICAL_WINDOW_SIZE_Y * 2);

  if (!debugWindowShown)
  {
    dest.x = DEBUGGER_WIDTH_PX / 2;
  }

  for (size_t i = 0; i < deviceCount; ++i)
  {
    renderDevice(&devices[i]);
    if (devices[i].output)
    {
      SDL_Rect devRect = dest;

      int texW, texH;
      SDL_QueryTexture(devices[i].output, NULL, NULL, &texW, &texH);

      double scaleX = dest.w / (double)texW;
      double scaleY = dest.h / (double)texH;

      double scale = (scaleX < scaleY) ? scaleX : scaleY;

      devRect.w = (int)(texW * scale);
      devRect.h = (int)(texH * scale);

      devRect.x = dest.x + (dest.w - devRect.w) / 2;
      devRect.y = dest.y + (dest.h - devRect.h) / 2;

      SDL_RenderCopy(state->renderers[0], devices[i].output, NULL, &devRect);
    }
  }

  if (debugWindowShown)
  {
    int mouseX, mouseY;
    SDL_GetMouseState(&mouseX, &mouseY);

    int winSizeX, winSizeY;
    SDL_GetWindowSize(state->windows[0], &winSizeX, &winSizeY);

    double factorX = winSizeX / (double)DEFAULT_WINDOW_WIDTH;
    double factorY = winSizeY / (double)DEFAULT_WINDOW_HEIGHT;

    mouseX = (int)(mouseX / factorX);
    mouseY = (int)(mouseY / factorY);
    mouseX -= dest.w;// * 2;

    debuggerUpdate(debugWindowTex, mouseX, mouseY);
    dest.x = dest.w;
    dest.w = (int)(DEBUGGER_WIDTH_PX);
    dest.h = (int)(DEBUGGER_HEIGHT_PX);
    SDL_RenderCopy(state->renderers[0], debugWindowTex, NULL, &dest);
  }

  SDL_RenderPresent(state->renderers[0]);
}



int tickCount = 0;
void
loop()
{
#if !HBC56_HAVE_THREADS
  cpuTick();
#endif

  doTick();

  ++tickCount;

  Uint32 currentTicks = SDL_GetTicks();
  if ((currentTicks - lastRenderTicks) > 17)
  {
    doRender();

    lastRenderTicks = currentTicks;
    tickCount = 0;
  }
  
  SDL_Event event;
  while (SDL_PollEvent(&event))
  {
    int skipProcessing = 0;
    switch (event.type)
    {
      case SDL_KEYDOWN:
      {
        skipProcessing = 1;
        SDL_bool withControl = (event.key.keysym.mod & KMOD_CTRL) ? 1 : 0;
        SDL_bool withShift = (event.key.keysym.mod & KMOD_SHIFT) ? 1 : 0;
        SDL_bool withAlt = (event.key.keysym.mod & KMOD_ALT) ? 1 : 0;

        switch (event.key.keysym.sym)
        {
          case SDLK_r:
            if (withControl)
            {
              hbc56Reset();
            }
            else
            {
              skipProcessing = 0;
            }
            break;

          case SDLK_d:
            if (withControl)
            {
              debugWindowShown = !debugWindowShown;
              debugPaused = debugWindowShown;
              debugStep = 0;
            }
            break;
          case SDLK_F2:
            hbc56Audio(withControl == 0);
            break;
          case SDLK_F12:
            debugWindowShown = 1;
            debugPaused = 1;
            debugStep = 0;
            break;
          case SDLK_F5:
            debugPaused = 0;
            debugStep = 0;
            break;
          case SDLK_PAGEUP:
          case SDLK_KP_9:
            if (withControl)
            {
              debugTmsMemoryAddr -= withShift ? 0x1000 : 64;
            }
            else
            {
              debugMemoryAddr -= withShift ? 0x1000 : 64;
            }
            break;
          case SDLK_PAGEDOWN:
          case SDLK_KP_3:
            if (withControl)
            {
              debugTmsMemoryAddr += withShift ? 0x1000 : 64;
            }
            else
            {
              debugMemoryAddr += withShift ? 0x1000 : 64;
            }
            break;

          case SDLK_F11:
            if (debugPaused)
            {
              if (withShift)
              {
                debugStepOver = 0;
                debugStepOut = 1;
              }
              else
              {
                debugStepOver = 0;
                debugStep = 1;
              }
            }
            break;
          case SDLK_F10:
            if (debugPaused)
            {
              debugStepOver = 1;
              debugStep = 1;
            }
            break;
          case SDLK_ESCAPE:
#ifdef _EMSCRIPTEN
            hbc56Reset();
#else
            done = 1;
#endif
            break;

         default:
           skipProcessing = 0;
        }
      }

      case SDL_KEYUP:
      {
        skipProcessing = 1;
        SDL_bool withControl = (event.key.keysym.mod & KMOD_CTRL) ? 1 : 0;
        SDL_bool withShift = (event.key.keysym.mod & KMOD_SHIFT) ? 1 : 0;
        SDL_bool withAlt = (event.key.keysym.mod & KMOD_ALT) ? 1 : 0;

        switch (event.key.keysym.sym)
        {
          case SDLK_r:
            if (!withControl) skipProcessing = 0;
            break;

          case SDLK_d:
            if (!withControl) skipProcessing = 0;
            break;

          case SDLK_F2:
          case SDLK_F12:
          case SDLK_F5:
          case SDLK_PAGEUP:
          case SDLK_KP_9:
          case SDLK_PAGEDOWN:
          case SDLK_KP_3:
          case SDLK_F11:
          case SDLK_F10:
          case SDLK_ESCAPE:
            skipProcessing = 1;
            break;

          default:
            skipProcessing = 0;
            break;
        }
        break;
      }
    }

    if (!skipProcessing)
    {
      for (size_t i = 0; i < deviceCount; ++i)
      {
        eventDevice(&devices[i], &event);
      }
    }
    SDLCommonEvent(state, &event, &done);
  }

#ifdef __EMSCRIPTEN__
  if (done) {
    emscripten_cancel_main_loop();
  }
#endif
}

char labelMapFile[FILENAME_MAX] = { 0 };


int loadRom(const char* filename)
{
  FILE* ptr = NULL;
  int romLoaded = 0;

#ifdef _EMSCRIPTEN
  ptr = fopen(filename, "rb");
#else
  fopen_s(&ptr, filename, "rb");
#endif

  SDL_snprintf(winTitleBuffer, sizeof(winTitleBuffer), "Troy's HBC-56 Emulator - %s", filename);

  if (ptr)
  {
    uint8_t rom[HBC56_ROM_SIZE];
    size_t romBytesRead = fread(rom, 1, sizeof(rom), ptr);
    fclose(ptr);

    if (romBytesRead != sizeof(rom))
    {
#ifndef _EMSCRIPTEN
      SDL_snprintf(winTitleBuffer, sizeof(winTitleBuffer), "Error. ROM file '%s' must be %d bytes.", filename, (int)sizeof(rom));
      SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR, "Troy's HBC-56 Emulator", winTitleBuffer, NULL);
#endif
    }
    else
    {
      romLoaded = 1;

      devices[deviceCount++] = createRomDevice(HBC56_ROM_START, HBC56_ROM_END, rom);

      SDL_strlcpy(labelMapFile, filename, FILENAME_MAX);
      size_t ln = SDL_strlen(labelMapFile);
      SDL_strlcpy(labelMapFile + ln, ".lmap", FILENAME_MAX - ln);
    }
  }
  else
  {
#ifndef _EMSCRIPTEN
    SDL_snprintf(winTitleBuffer, sizeof(winTitleBuffer), "Error. ROM file '%s' does not exist.", filename);
    SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR, "Troy's HBC-56 Emulator", winTitleBuffer, NULL);
#endif
    return 2;
  }

  return romLoaded;
}


int
main(int argc, char* argv[])
{
  int i;
  Uint32 then, frames;

  perfFreq = (double)SDL_GetPerformanceFrequency();

  /* Enable standard application logging */
  SDL_LogSetPriority(SDL_LOG_CATEGORY_APPLICATION, SDL_LOG_PRIORITY_INFO);

  SDL_snprintf(winTitleBuffer, sizeof(winTitleBuffer), "Troy's HBC-56 Emulator");

  /* Initialize test framework */
  state = SDLCommonCreateState(argv, SDL_INIT_VIDEO | SDL_INIT_AUDIO);
  if (!state) {
    return 1;
  }
  int romLoaded = 0;
  LCDType lcdType = LCD_NONE;

#if _EMSCRIPTEN
  romLoaded = loadRom("rom.bin");
  keyboardMode = 1;
  lcdType = LCD_GRAPHICS;
#endif

  for (i = 1; i < argc;) {
    int consumed;

    consumed = SDLCommonArg(state, i);
    if (consumed <= 0) {
      consumed = -1;
      if (SDL_strcasecmp(argv[i], "--rom") == 0) {
        if (argv[i + 1]) {
          consumed = 1;
          romLoaded = loadRom(argv[++i]);
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
      static const char* options[] = { "--rom <romfile>","[--brk]","[--keyboard]", NULL };
      SDLCommonLogUsage(state, argv[0], options);
      return 2;
    }
    i += consumed;
  }

  if (romLoaded == 0) {
    static const char* options[] = { "--rom <romfile>","[--brk]","[--keyboard]","[--lcd 1602|2004|12864]", NULL };
    SDLCommonLogUsage(state, argv[0], options);

#ifndef _EMSCRIPTEN
    SDL_snprintf(winTitleBuffer, sizeof(winTitleBuffer), "No HBC-56 ROM file.\n\nUse --rom <romfile>");
    SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR, "Troy's HBC-56 Emulator", winTitleBuffer, NULL);
#endif

    return 2;
  }

  state->window_title = winTitleBuffer;

  if (!SDLCommonInit(state)) {
    return 2;
  }

  devices[deviceCount++] = createRamDevice(HBC56_RAM_START, HBC56_RAM_END);

#if HBC56_HAVE_TMS9918
  devices[deviceCount++] = createTms9918Device(HBC56_IO_ADDRESS(HBC56_TMS9918_DAT_PORT), HBC56_IO_ADDRESS(HBC56_TMS9918_REG_PORT), state->renderers[0]);
  debuggerInitTms(&devices[deviceCount - 1]);
#endif

#if HBC56_HAVE_KB
  if (keyboardMode) devices[deviceCount++] = createKeyboardDevice(HBC56_IO_ADDRESS(HBC56_KB_PORT));
#endif

#if HBC56_HAVE_NES
  if (!keyboardMode) devices[deviceCount++] = createNESDevice(HBC56_IO_ADDRESS(HBC56_NES_PORT));
#endif

#if HBC56_HAVE_LCD
  devices[deviceCount++] = createLcdDevice(lcdType, HBC56_IO_ADDRESS(HBC56_LCD_DAT_PORT), HBC56_IO_ADDRESS(HBC56_LCD_CMD_PORT), state->renderers[0]);
#endif

#if HBC56_HAVE_AY_3_8910
  devices[deviceCount++] = createAY38910Device(HBC56_IO_ADDRESS(HBC56_AY38910_A_PORT), HBC56_AY38910_CLOCK, HBC56_AUDIO_FREQ);
  #if HBC56_AY_3_8910_COUNT > 1
    devices[deviceCount++] = createAY38910Device(HBC56_IO_ADDRESS(HBC56_AY38910_B_PORT), HBC56_AY38910_CLOCK, HBC56_AUDIO_FREQ);
#endif
#endif

  SDL_Renderer* renderer = state->renderers[0];
  SDL_RenderClear(renderer);
  debugWindowTex = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGB24, SDL_TEXTUREACCESS_STREAMING, DEBUGGER_WIDTH_PX, DEBUGGER_HEIGHT_PX);

#ifndef _EMSCRIPTEN
  SDL_SetTextureScaleMode(debugWindowTex, SDL_ScaleModeBest);
#endif

  srand((unsigned int)time(NULL));

#if HBC56_HAVE_THREADS
  SDL_CreateThread(cpuThread, "CPU", NULL);
#endif

  /* Main render loop */
  frames = 0;
  then = SDL_GetTicks();
  done = 0;

  hbc56Reset();

  debuggerInit(cpu6502_get_regs(), labelMapFile);
  hbc56Audio(1);

  SDL_Delay(100);

#ifdef _EMSCRIPTEN
  emscripten_set_main_loop(loop, 0, 1);
#else
  while (!done) {
    ++frames;
    loop();
  }
#endif


  for (size_t i = 0; i < deviceCount; ++i)
  {
    destroyDevice(&devices[i]);
  }


  // cool down audio
  SDL_Delay(250);

  hbc56Audio(0);

  SDL_AudioQuit();

  SDLCommonQuit(state);

  return 0;
}
