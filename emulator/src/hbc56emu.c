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

#include "hbc56emu.h"
#include "window.h"

#include "audio.h"

#include "debugger/debugger.h"

#include "devices/memory_device.h"
#include "devices/6502_device.h"
#include "devices/tms9918_device.h"
#include "devices/lcd_device.h"
#include "devices/keyboard_device.h"
#include "devices/nes_device.h"
#include "devices/ay38910_device.h"

#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <string.h>

static HBC56Device devices[HBC56_MAX_DEVICES];
static int deviceCount = 0;

static HBC56Device* cpuDevice = NULL;
static HBC56Device* romDevice = NULL;

static char tempBuffer[256];
static int debugWindowShown = 1;


/* Function:  hbc56Reset
 * --------------------
 * hardware reset the hbc-56
 */
void hbc56Reset()
{
  for (size_t i = 0; i < deviceCount; ++i)
  {
    resetDevice(&devices[i]);
  }

  debug6502State(cpuDevice, CPU_RUNNING);
}

/* Function:  hbc56NumDevices
 * --------------------
 * return the number of devices present
 */
int hbc56NumDevices()
{
  return deviceCount;
}

/* Function:  hbc56Device
 * --------------------
 * return a pointer to the given device
 */
HBC56Device* hbc56Device(size_t deviceNum)
{
  if (deviceNum < deviceCount)
    return &devices[deviceNum];
  return NULL;
}

/* Function:  hbc56AddDevice
 * --------------------
 * add a new device
 * returns a pointer to the added device
 */
HBC56Device* hbc56AddDevice(HBC56Device device)
{
  if (deviceCount < (HBC56_MAX_DEVICES - 1))
  {
    devices[deviceCount] = device;
    return &devices[deviceCount++];
  }
  return NULL;
}

/* Function:  hbc56Interrupt
 * --------------------
 * raise or release an interrupt
 */
void hbc56Interrupt(HBC56InterruptType type, HBC56InterruptSignal signal)
{
  if (cpuDevice)
  {
    interrupt6502(cpuDevice, type, signal);
  }
}

/* Function:  hbc56LoadRom
 * --------------------
 * load rom data. rom data bust be HBC56_ROM_SIZE bytes
 */
int hbc56LoadRom(const uint8_t* romData, int romDataSize)
{
  int status = 1;

  if (romDataSize != HBC56_ROM_SIZE)
  {
#ifndef __EMSCRIPTEN__
    SDL_snprintf(tempBuffer, sizeof(tempBuffer), "Error. ROM file must be %d bytes.", HBC56_ROM_SIZE);
    SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR, "Troy's HBC-56 Emulator", tempBuffer, NULL);
#endif
    status = 0;
  }

  if (status)
  {
    debug6502State(cpuDevice, CPU_BREAK);
    SDL_Delay(1);
    if (!romDevice)
    {
      romDevice = hbc56AddDevice(createRomDevice(HBC56_ROM_START, HBC56_ROM_END, romData));
    }
    else
    {
      status = setMemoryDeviceContents(romDevice, romData, romDataSize);
    }
    hbc56Reset();
  }
  return status;
}

/* Function:  hbc56LoadLabels
 * --------------------
 * load labels. labelFileContents is a null terminated string (lmap file contents)
 */
void hbc56LoadLabels(const char* labelFileContents)
{
  debuggerLoadLabels(labelFileContents);
}

/* Function:  hbc56ToggleDebugger
 * --------------------
 * toggle the debugger
 */
void hbc56ToggleDebugger()
{
  debugWindowShown = !debugWindowShown;
  debug6502State(cpuDevice, debugWindowShown ? CPU_BREAK : CPU_RUNNING);
}

/* Function:  hbc56DebugBreak
 * --------------------
 * break
 */
void hbc56DebugBreak()
{
  debugWindowShown = 1;
  debug6502State(cpuDevice, CPU_BREAK);
}

/* Function:  hbc56DebugRun
 * --------------------
 * run / continue
 */
void hbc56DebugRun()
{
  debug6502State(cpuDevice, CPU_RUNNING);
}

/* Function:  hbc56DebugStepInto
 * --------------------
 * step in
 */
void hbc56DebugStepInto()
{
  debug6502State(cpuDevice, CPU_STEP_INTO);
}

/* Function:  hbc56DebugStepOver
 * --------------------
 * step over
 */
void hbc56DebugStepOver()
{
  debug6502State(cpuDevice, CPU_STEP_OVER);
}

/* Function:  hbc56DebugStepOut
 * --------------------
 * step out
 */
void hbc56DebugStepOut()
{
  debug6502State(cpuDevice, CPU_STEP_OUT);
}



/* Function:  mem_read_impl
 * --------------------
 * read a value from a device
 */
static uint8_t mem_read_impl(uint16_t addr, int dbg)
{
  uint8_t val = 0xff;
  for (size_t i = 0; i < deviceCount; ++i)
  {
    if (readDevice(&devices[i], addr, &val, dbg))
      break;
  }

  return val;
}


/* Function:  mem_read
 * --------------------
 * read a value from a device (regular mode)
 */
uint8_t mem_read(uint16_t addr) {
  return mem_read_impl(addr, 0);
}

/* Function:  mem_read_dbg
 * --------------------
 * read a value from a device (debugger mode)
 */
uint8_t mem_read_dbg(uint16_t addr) {
  return mem_read_impl(addr, 1);
}

/* Function:  mem_write
 * --------------------
 * write a valude to a device
 */
void mem_write(uint16_t addr, uint8_t val)
{
  for (size_t i = 0; i < deviceCount; ++i)
  {
    if (writeDevice(&devices[i], addr, val))
      break;
  }
}


/* emulator constants */
#define LOGICAL_DISPLAY_SIZE_X 320
#define LOGICAL_DISPLAY_SIZE_Y 240
#define LOGICAL_DISPLAY_BPP    3

/* emulator state */
static SDLCommonState* state;
static int done;
static double perfFreq = 0.0;
static int tickCount = 0;

static uint8_t debugFrameBuffer[DEBUGGER_WIDTH_PX * DEBUGGER_HEIGHT_PX * LOGICAL_DISPLAY_BPP];
static SDL_Texture* debugWindowTex = NULL;


/* Function:  doTick
 * --------------------
 * regular "tick" for devices. devices can use either real time or clock ticks
 * to update their state
 */
static void doTick()
{
  static double lastTime = 0.0;
  static double unusedClockTicksTime = 0.0;

  double thisTime = (double)SDL_GetPerformanceCounter() / perfFreq;

  double deltaClockTicksDbl = HBC56_CLOCK_FREQ * (thisTime - lastTime) + unusedClockTicksTime;

  uint32_t deltaClockTicks = (uint32_t)deltaClockTicksDbl;
  unusedClockTicksTime = deltaClockTicksDbl - (double)deltaClockTicks;

  if (lastTime != 0)
  {
    for (size_t i = 0; i < deviceCount; ++i)
    {
      tickDevice(&devices[i], deltaClockTicks, thisTime - lastTime);
    }
  }

  lastTime = thisTime;
}

/* Function:  doRender
 * --------------------
 * render the various displays to the window
 */
static void doRender()
{
  SDL_RenderClear(state->renderers[0]);

  SDL_Rect dest;
  dest.x = 0;
  dest.y = 0;
  dest.w = (int)(LOGICAL_DISPLAY_SIZE_X * 3);
  dest.h = (int)(LOGICAL_DISPLAY_SIZE_Y * 3);

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


/* Function:  doEvents
 * --------------------
 * handle events which control emulator / debugger
 */
static void doEvents()
{
  extern uint16_t debugMemoryAddr;
  extern uint16_t debugTmsMemoryAddr;

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
          hbc56ToggleDebugger();
        }
        break;
      case SDLK_F2:
        hbc56Audio(withControl == 0);
        break;
      case SDLK_F12:
        hbc56DebugBreak();
        break;
      case SDLK_F5:
        hbc56DebugRun();
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
        if (withShift)
        {
          hbc56DebugStepOut();
        }
        else
        {
          hbc56DebugStepInto();
        }
        break;
      case SDLK_F10:
        hbc56DebugStepOver();
        break;
      case SDLK_ESCAPE:
#ifdef __EMSCRIPTEN__
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
}

/* Function:  loop
 * --------------------
 * the main loop. will be called many times per frame
 */
static void loop()
{
  static uint32_t lastRenderTicks = 0;

  doTick();

  ++tickCount;

  uint32_t currentTicks = SDL_GetTicks();
  if ((currentTicks - lastRenderTicks) > 17)
  {
    doRender();

    lastRenderTicks = currentTicks;
    tickCount = 0;

    doEvents();
  }


#ifdef __EMSCRIPTEN__
  if (done) {
    emscripten_cancel_main_loop();
  }
#endif
}

#ifdef __EMSCRIPTEN__
/* Function:  wasmLoop
 * --------------------
 * calls loop() as many times as it can per frame
 */
static void wasmLoop()
{
  while (1)
  {
    loop();
    if (tickCount == 0) break;
  }
}
#endif


static char labelMapFile[FILENAME_MAX] = { 0 };


/* Function:  loadRom
 * --------------------
 * loads a rom from disk and creates the rom device
 */
static int loadRom(const char* filename)
{
  FILE* ptr = NULL;
  int romLoaded = 0;

#ifdef __EMSCRIPTEN__
  ptr = fopen(filename, "rb");
#else
  fopen_s(&ptr, filename, "rb");
#endif

  SDL_snprintf(tempBuffer, sizeof(tempBuffer), "Troy's HBC-56 Emulator - %s", filename);
  state->window_title = tempBuffer;

  if (ptr)
  {
    uint8_t rom[HBC56_ROM_SIZE];
    size_t romBytesRead = fread(rom, 1, sizeof(rom), ptr);
    fclose(ptr);

    romLoaded = hbc56LoadRom(rom, (int)romBytesRead);

    if (romLoaded)
    {
      SDL_strlcpy(labelMapFile, filename, FILENAME_MAX);
      size_t ln = SDL_strlen(labelMapFile);
      SDL_strlcpy(labelMapFile + ln, ".lmap", FILENAME_MAX - ln);

#ifdef __EMSCRIPTEN__
      ptr = fopen(labelMapFile, "rb");
#else
      fopen_s(&ptr, labelMapFile, "rb");
#endif
      if (ptr)
      {
        fseek(ptr, 0, SEEK_END);
        long fsize = ftell(ptr);
        fseek(ptr, 0, SEEK_SET);  /* same as rewind(f); */

        char *lblFileContent = malloc(fsize + 1);
        fread(lblFileContent, fsize, 1, ptr);
        fclose(ptr);

        hbc56LoadLabels(lblFileContent);
        free(lblFileContent);
      }
    }
  }
  else
  {
#ifndef __EMSCRIPTEN__
    SDL_snprintf(tempBuffer, sizeof(tempBuffer), "Error. ROM file '%s' does not exist.", filename);
    SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR, "Troy's HBC-56 Emulator", tempBuffer, NULL);
#endif
    return 2;
  }

  return romLoaded;
}

/* Function:  main
 * --------------------
 * the program entry point
 */
int main(int argc, char* argv[])
{
  perfFreq = (double)SDL_GetPerformanceFrequency();

  /* enable standard application logging */
  SDL_LogSetPriority(SDL_LOG_CATEGORY_APPLICATION, SDL_LOG_PRIORITY_INFO);

  /* initialize test framework */
  state = SDLCommonCreateState(argv, SDL_INIT_VIDEO | SDL_INIT_AUDIO);
  if (!state) {
    return 1;
  }

  /* window title */
  SDL_snprintf(tempBuffer, sizeof(tempBuffer), "Troy's HBC-56 Emulator");
  state->window_title = tempBuffer;

  /* add the cpu device */
  cpuDevice = hbc56AddDevice(create6502CpuDevice());

  int romLoaded = 0;
  LCDType lcdType = LCD_NONE;

#if __EMSCRIPTEN__
  /* load the hard-coded rom */
  romLoaded = loadRom("rom.bin");
  lcdType = LCD_GRAPHICS;
#endif

  /* parse arguments */
  for (int i = 1; i < argc;)
  {
    int consumed;

    consumed = SDLCommonArg(state, i);
    if (consumed <= 0)
    {
      consumed = -1;
      if (SDL_strcasecmp(argv[i], "--rom") == 0)
      {
        if (argv[i + 1])
        {
          consumed = 1;
          romLoaded = loadRom(argv[++i]);
        }
      }
      /* start paused? */
      else if (SDL_strcasecmp(argv[i], "--brk") == 0)
      {
        consumed = 1;
        debug6502State(cpuDevice, CPU_BREAK);
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
    if (consumed < 0)
    {
      static const char* options[] = { "--rom <romfile>","[--brk]","[--keyboard]", NULL };
      SDLCommonLogUsage(state, argv[0], options);
      return 2;
    }
    i += consumed;
  }

  if (romLoaded == 0)
  {
    static const char* options[] = { "--rom <romfile>","[--brk]","[--keyboard]","[--lcd 1602|2004|12864]", NULL };
    SDLCommonLogUsage(state, argv[0], options);

#ifndef __EMSCRIPTEN__
    SDL_snprintf(tempBuffer, sizeof(tempBuffer), "No HBC-56 ROM file.\n\nUse --rom <romfile>");
    SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR, "Troy's HBC-56 Emulator", tempBuffer, NULL);
#endif

    return 2;
  }

  if (!SDLCommonInit(state)) {
    return 2;
  }


  /* add the various devices */
  hbc56AddDevice(createRamDevice(HBC56_RAM_START, HBC56_RAM_END));

#if HBC56_HAVE_TMS9918
  HBC56Device *tms9918Device = hbc56AddDevice(createTms9918Device(HBC56_IO_ADDRESS(HBC56_TMS9918_DAT_PORT), HBC56_IO_ADDRESS(HBC56_TMS9918_REG_PORT), state->renderers[0]));
  debuggerInitTms(tms9918Device);
#endif

#if HBC56_HAVE_KB
  hbc56AddDevice(createKeyboardDevice(HBC56_IO_ADDRESS(HBC56_KB_PORT)));
#endif

#if HBC56_HAVE_NES
  hbc56AddDevice(createNESDevice(HBC56_IO_ADDRESS(HBC56_NES_PORT)));
#endif

#if HBC56_HAVE_LCD
  hbc56AddDevice(createLcdDevice(lcdType, HBC56_IO_ADDRESS(HBC56_LCD_DAT_PORT), HBC56_IO_ADDRESS(HBC56_LCD_CMD_PORT), state->renderers[0]));
#endif

#if HBC56_HAVE_AY_3_8910
  hbc56AddDevice(createAY38910Device(HBC56_IO_ADDRESS(HBC56_AY38910_A_PORT), HBC56_AY38910_CLOCK, HBC56_AUDIO_FREQ));
  #if HBC56_AY_3_8910_COUNT > 1
    hbc56AddDevice(createAY38910Device(HBC56_IO_ADDRESS(HBC56_AY38910_B_PORT), HBC56_AY38910_CLOCK, HBC56_AUDIO_FREQ));
  #endif
#endif


  /* set up the display */
  SDL_Renderer* renderer = state->renderers[0];
  SDL_SetTextureBlendMode(state->targets[0], SDL_BLENDMODE_ADD);
  SDL_RenderClear(renderer);
  debugWindowTex = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGB24, SDL_TEXTUREACCESS_STREAMING, DEBUGGER_WIDTH_PX, DEBUGGER_HEIGHT_PX);

#ifndef __EMSCRIPTEN__
  SDL_SetTextureScaleMode(debugWindowTex, SDL_ScaleModeBest);
#endif

  /* randomise */
  srand((unsigned int)time(NULL));

  done = 0;

  /* initialise audio */
  hbc56Audio(1);

  /* reset the machine */
  hbc56Reset();

  /* initialise the debugger */
  debuggerInit(cpu6502_get_regs());

  SDL_Delay(100);

  /* loop until done */
#ifdef __EMSCRIPTEN__
  emscripten_set_main_loop(wasmLoop, 0, 1);
#else
  while (!done)
  {
    loop();
  }
#endif

  /* clean up  */
  for (size_t i = 0; i < deviceCount; ++i)
  {
    destroyDevice(&devices[i]);
  }

  hbc56Audio(0);

  SDL_AudioQuit();

  SDLCommonQuit(state);

  return 0;
}
