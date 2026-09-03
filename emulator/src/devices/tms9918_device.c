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

#include "pico9918.h"
#include "pico9918_config.h"
#include "pico9918_frame.h"
#include "pico9918_util.h"
#include "gpu/gpu.h"
#include "overlay/diag.h"
#include "overlay/splash.h"

#include "../hbc56emu.h"

#include "SDL.h"

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

static void resetTms9918Device(HBC56Device*);
static void destroyTms9918Device(HBC56Device*);
static void renderTms9918Device(HBC56Device* device);
static void tickTms9918Device(HBC56Device*, uint32_t, float);
static uint8_t readTms9918Device(HBC56Device*, uint16_t, uint8_t*, uint8_t);
static uint8_t writeTms9918Device(HBC56Device*, uint16_t, uint8_t);

/* The VDP drives a full 640x480 VGA frame. The border is part of the picture: the
   overlays are drawn into it.

   No horizontal geometry of our own: pico9918-core lays a line out in 32-bit words
   holding two 16-bit pixels, which is the one pixel width it ships. So its own
   numbers land finished - 320 words, 640 pixels, the picture at 64..575 with 64 of
   border each side - and there is nothing to halve, re-derive or stretch after. */
#define TMS9918_DISPLAY_WIDTH   640
#define TMS9918_DISPLAY_HEIGHT  480
#define TMS9918_DISPLAY_PIXELS  (TMS9918_DISPLAY_WIDTH * TMS9918_DISPLAY_HEIGHT)

/* A fine-h-scrolled tile layer's last quad can reach past the line. */
#define TMS9918_LINE_SLACK      16

/* NTSC: 262 lines a field including the porch, sixty fields a second. */
#define TMS9918_FPS             60.0f
#define TMS9918_SCANLINES       262

/* One emulated scanline's worth of time - the granularity this renders at. */
#define TMS9918_FRAME_TIME      (1.0f / TMS9918_FPS)
#define TMS9918_ROW_TIME        (TMS9918_FRAME_TIME / (float)TMS9918_SCANLINES)

/* First config byte the device may write back; 0-7 are identity. */
#define TMS9918_CONFIG_SETTABLE 8

/* Where the board's 256-byte config block is kept between sessions. */
#define TMS9918_CONFIG_FILE     "pico9918.cfg"

/* Packed major(4) | minor(4) | patch(8), as pico9918_config_fields wants it. */
#define TMS9918_CONFIG_VERSION ((uint16_t)(((PICO9918_CORE_VER_MAJOR & 0x0f) << 12) | \
                                           ((PICO9918_CORE_VER_MINOR & 0x0f) <<  8) | \
                                            (PICO9918_CORE_VER_PATCH & 0xff)))

/* Board v1.0 as a packed nibble pair; byte 0 doubles as "is this block ours". */
#define TMS9918_CONFIG_MODEL      0
#define TMS9918_CONFIG_HW_VERSION 0x10

/* An HBC-56 reset is a hardware one: the video board is power-cycled with the rest of
   the machine, so the splash comes back with it. What the library publishes is the
   CONSOLE reset, which deliberately keeps both of these - the splash hand-off and the
   startup diagnostics screen are once-per-run latches it will not re-arm - and it has
   no public entry for the power-on case. These two globals, owned by the library's
   frame module, are the whole difference. */
extern int  pico9918_frame_count;
extern bool pico9918_valid_writes;

/* tms9918 device data */
struct TMS9918Device
{
  uint16_t       dataAddr;
  uint16_t       regAddr;
  pico9918_t    *vdp;
  uint32_t       frameBuffer[TMS9918_DISPLAY_PIXELS];
  float          unusedTime;

  /* Where the raster is, and how many virtual lines an emulated scanline is worth:
     one at vPixelScale 2, two under double rows. fieldLines includes the porch. */
  unsigned int   line;
  unsigned int   linesPerCall;
  unsigned int   fieldLines;

  pico9918_scanline_params_t params;
  pico9918_frame_display_t   display;
  pico9918_frame_geometry_t  geometry;

  PICO9918_PIXEL_T pixels[TMS9918_DISPLAY_WIDTH + TMS9918_LINE_SLACK];

  /* Our validated copy of the 256-byte block, and the instance's live one. */
  uint8_t        config[CONFIG_BYTES];
  uint8_t       *deviceConfig;
  int            configCapturing;
  int            configPending;

  uint8_t        irq;
  int            irqLevel;
};
typedef struct TMS9918Device TMS9918Device;

/* BGR12 in the low 12 bits is what the library hands back - the board's format - and
   the SDL texture takes RGBA8888. One lookup a pixel, in the copy into the frame
   buffer that had to happen anyway. */
static uint32_t bgr12Rgba[4096];

/* The chip the next device created answers as. The HBC-56 ships a TMS9918A; the two
   above it are what a drop-in replacement board offers. */
static pico9918_chip_t requestedChip = PICO9918_CHIP_TMS9918A;

/* The library's config-action and config-reload hooks carry no user pointer, and the
   machine has one VDP, so they reach it through here. */
static TMS9918Device* configOwner = NULL;

/* Function:  setTms9918Chip
 * --------------------
 * choose which chip the vdp answers as. call before creating the device.
 */
void setTms9918Chip(int chip)
{
  if (chip < PICO9918_CHIP_TMS9918A) chip = PICO9918_CHIP_TMS9918A;
  if (chip > PICO9918_CHIP_MAX)      chip = PICO9918_CHIP_MAX;

  requestedChip = (pico9918_chip_t)chip;
}

/* Function:  getTms9918Chip
 * --------------------
 * which chip the vdp answers as. a change lands on the next reset, so this is what
 * the machine will be running as, not necessarily what it is running as right now.
 */
int getTms9918Chip(void)
{
  return (int)requestedChip;
}

/* Function:  tms9918ChipName
 * --------------------
 * the name of a chip, as --vdp spells it
 */
const char* tms9918ChipName(int chip)
{
  switch (chip)
  {
    case PICO9918_CHIP_F18A:     return "F18A";
    case PICO9918_CHIP_PICO9918: return "PICO9918";
    default:                     return "TMS9918A";
  }
}

/* Function:  tms9918ChipFromName
 * --------------------
 * parse a chip name. -1 if it is none of them.
 */
int tms9918ChipFromName(const char* name)
{
  if (!name || !*name) return -1;

  if (SDL_strcasecmp(name, "tms9918a") == 0 || SDL_strcasecmp(name, "tms9918") == 0 ||
      SDL_strcasecmp(name, "tms") == 0      || SDL_strcasecmp(name, "9918") == 0)
    return PICO9918_CHIP_TMS9918A;

  if (SDL_strcasecmp(name, "f18a") == 0)
    return PICO9918_CHIP_F18A;

  if (SDL_strcasecmp(name, "pico9918") == 0 || SDL_strcasecmp(name, "pico") == 0)
    return PICO9918_CHIP_PICO9918;

  return -1;
}

/* Function:  tms9918InitPixelMap
 * --------------------
 * BGR12 to RGBA8888, through the library's own transform so the nibble order lives in
 * one place. indexed by the low 12 bits, the dead copy of green in 15-12 masked off
 * as the library masks it wherever it matters.
 */
static void tms9918InitPixelMap(void)
{
  for (unsigned int v = 0; v < 4096u; ++v)
  {
    const uint32_t rgb = pico9918_pixel_rgb888((PICO9918_PIXEL_T)v);
    bgr12Rgba[v] = (rgb << 8) | 0xffu;
  }
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

/* Function:  tms9918ConfigStore
 * --------------------
 * write the config block out, as saving to the board's flash would
 */
static void tms9918ConfigStore(TMS9918Device* tmsDevice)
{
  tmsDevice->configPending = 0;

  FILE* file = fopen(TMS9918_CONFIG_FILE, "wb");
  if (!file) return;

  fwrite(tmsDevice->config, 1, CONFIG_BYTES, file);
  fclose(file);
}

/* Function:  tms9918ConfigStamp
 * --------------------
 * the identity bytes are ours, not the file's
 */
static void tms9918ConfigStamp(TMS9918Device* tmsDevice)
{
  tmsDevice->config[PICO9918_CONF_PICO_MODEL]       = TMS9918_CONFIG_MODEL;
  tmsDevice->config[PICO9918_CONF_HW_VERSION]       = TMS9918_CONFIG_HW_VERSION;
  tmsDevice->config[PICO9918_CONF_SW_VERSION]       = (uint8_t)(TMS9918_CONFIG_VERSION >> 8);
  tmsDevice->config[PICO9918_CONF_SW_PATCH_VERSION] = (uint8_t)(TMS9918_CONFIG_VERSION & 0xff);
}

/* Function:  tms9918ConfigLoad
 * --------------------
 * read the block back and let the library validate it: a bad one is defaulted, an old
 * one migrated
 */
static void tms9918ConfigLoad(TMS9918Device* tmsDevice)
{
  bool wasReset = false;
  uint8_t identity[TMS9918_CONFIG_SETTABLE];

  memset(tmsDevice->config, 0, sizeof(tmsDevice->config));

  FILE* file = fopen(TMS9918_CONFIG_FILE, "rb");
  if (file)
  {
    if (fread(tmsDevice->config, 1, CONFIG_BYTES, file) != CONFIG_BYTES)
      memset(tmsDevice->config, 0, sizeof(tmsDevice->config));
    fclose(file);
  }

  bool rewrite = pico9918_config_validate(tmsDevice->config,
                                          tmsDevice->config[PICO9918_CONF_PICO_MODEL] == TMS9918_CONFIG_MODEL,
                                          TMS9918_CONFIG_VERSION, &wasReset);

  memcpy(identity, tmsDevice->config, sizeof(identity));
  tms9918ConfigStamp(tmsDevice);

  if (rewrite || memcmp(identity, tmsDevice->config, sizeof(identity)) != 0)
    tms9918ConfigStore(tmsDevice);
}

/* Function:  tms9918ConfigSaved
 * --------------------
 * the GPU's config-action hook, which is also the only route the public API offers to
 * the instance's live block
 */
static void tms9918ConfigSaved(uint8_t* live, uint8_t key)
{
  TMS9918Device* tmsDevice = configOwner;
  if (!tmsDevice) return;

  tmsDevice->deviceConfig = live;

  if (tmsDevice->configCapturing) return;

  /* Cancel means discard what the configurator staged, not persist it. */
  if (key == PICO9918_CONF_PENDING_CANCEL)
  {
    memcpy(live + TMS9918_CONFIG_SETTABLE, tmsDevice->config + TMS9918_CONFIG_SETTABLE,
           CONFIG_BYTES - TMS9918_CONFIG_SETTABLE);
    return;
  }

  memcpy(tmsDevice->config + TMS9918_CONFIG_SETTABLE, live + TMS9918_CONFIG_SETTABLE,
         CONFIG_BYTES - TMS9918_CONFIG_SETTABLE);
  tms9918ConfigStamp(tmsDevice);

  /* Deferred: this runs from the per-scanline GPU step, not a place to block. */
  tmsDevice->configPending = 1;
}

/* Function:  tms9918ConfigReload
 * --------------------
 * restores the settings the startup diagnostics screen takes away
 */
static void tms9918ConfigReload(void)
{
  TMS9918Device* tmsDevice = configOwner;
  if (!tmsDevice || !tmsDevice->deviceConfig) return;

  pico9918_t* tms9918 = tmsDevice->vdp;

  memcpy(tmsDevice->deviceConfig, tmsDevice->config, CONFIG_BYTES);
  pico9918_diag_config_updated(PICO9918_INST_ONLY);
}

/* Function:  tms9918DiagSetup
 * --------------------
 * the diagnostics panel's host half: the glyph table, and values only a host knows
 */
static void tms9918DiagSetup(void)
{
  static int initialised = 0;
  char firmware[16];

  if (!initialised)
  {
    pico9918_diag_init();
    initialised = 1;
  }

  snprintf(firmware, sizeof(firmware), "%u.%u.%u", PICO9918_CORE_VER_MAJOR,
           PICO9918_CORE_VER_MINOR, PICO9918_CORE_VER_PATCH);
  pico9918_diag_set_version_info("1.0", firmware);

  /* Retained by pointer, so literals only. */
  pico9918_diag_set_output_name("480P ", "@60");
  pico9918_diag_set_clock_hz(252000000.0f);
}

/* Function:  tms9918Seed
 * --------------------
 * leave the board as a power-on does: settings loaded, sprite limit and palette
 * seeded, display off. seeded at the top personality then stepped down, since the
 * config port is gated on it but the values are not.
 */
static void tms9918Seed(TMS9918Device* tmsDevice)
{
  pico9918_t* tms9918 = tmsDevice->vdp;

  configOwner = tmsDevice;
  tmsDevice->configCapturing = 1;

  pico9918_set_chip(PICO9918_INST PICO9918_CHIP_PICO9918);

  /* Unlock: two consecutive VR57 writes with the low two bits clear. */
  pico9918_write_reg_value(PICO9918_INST 0x80u | 0x39u, 0x1Cu);
  pico9918_write_reg_value(PICO9918_INST 0x80u | 0x39u, 0x1Cu);

  /* Arm the save command as the configurator does, purely to be handed the block. */
  pico9918_write_reg_value(PICO9918_INST 0x80u | 58u, PICO9918_CONF_SAVE_TO_FLASH);
  pico9918_write_reg_value(PICO9918_INST 0x80u | 59u, 1u);
  pico9918_gpu_step(PICO9918_INST_ONLY);
  tmsDevice->configCapturing = 0;

  tms9918ConfigLoad(tmsDevice);
  if (tmsDevice->deviceConfig)
    memcpy(tmsDevice->deviceConfig, tmsDevice->config, CONFIG_BYTES);

  pico9918_write_reg_value(PICO9918_INST 0x80u | 0x32u, 0xC0u);
  pico9918_config_apply(PICO9918_INST_ONLY);
  pico9918_diag_config_updated(PICO9918_INST_ONLY);

  pico9918_write_reg_value(PICO9918_INST 0x80u | 1u, 0x00u);
  pico9918_write_reg_value(PICO9918_INST 0x80u | 7u, 0x00u);

  pico9918_set_chip(PICO9918_INST requestedChip);
}

/* Function:  tms9918RecomputeCadence
 * --------------------
 * how many virtual lines one emulated scanline is worth, now the geometry has moved
 */
static void tms9918RecomputeCadence(TMS9918Device* tmsDevice)
{
  tmsDevice->linesPerCall = (tmsDevice->display.vPixelScale >= 2u) ? 1u : 2u;
  tmsDevice->fieldLines   = TMS9918_SCANLINES * tmsDevice->linesPerCall;
  tmsDevice->params.vVirtualPixels = tmsDevice->display.vVirtualPixels;
}

/* Function:  tms9918Configure
 * --------------------
 * vPixelScale and vVirtualPixels are seeded here, then owned by the library
 */
static void tms9918Configure(TMS9918Device* tmsDevice)
{
  pico9918_t* tms9918 = tmsDevice->vdp;

  tmsDevice->params.hVirtualPixels       = (uint16_t)TMS9918_DISPLAY_WIDTH;
  tmsDevice->params.interlaced           = false;
  tmsDevice->params.interlacedFieldOrder = 0u;

  tmsDevice->display.displayPixels  = TMS9918_DISPLAY_HEIGHT;
  tmsDevice->display.interlaced     = false;
  tmsDevice->display.vPixelScale    = 2u;
  tmsDevice->display.vVirtualPixels = (uint16_t)(TMS9918_DISPLAY_HEIGHT / 2);

  tmsDevice->geometry = pico9918_frame_geometry(PICO9918_INST &tmsDevice->display);
  tms9918RecomputeCadence(tmsDevice);
}

/* Function:  tms9918GpuIps
 * --------------------
 * the gpu's clock, which HBC56_GPU_IPS overrides. the library paces it from here.
 */
static uint32_t tms9918GpuIps(void)
{
  unsigned long ips = PICO9918_GPU_IPS_PRO;
  const char* env = getenv("HBC56_GPU_IPS");

  /* strtoul wraps a negative to ULONG_MAX rather than failing, so reject the sign
     before it rather than after. */
  if (env && *env && *env != '-')
  {
    char* end = NULL;
    errno = 0;
    unsigned long parsed = strtoul(env, &end, 0);
    if (end != env && *end == '\0' && errno != ERANGE && parsed != 0ul)
      ips = parsed;
  }

  return (ips > UINT32_MAX) ? UINT32_MAX : (uint32_t)ips;
}

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
    memset(tmsDevice, 0, sizeof(TMS9918Device));

    tmsDevice->dataAddr = dataAddr;
    tmsDevice->regAddr = regAddr;
    tmsDevice->irq = irq;
    tmsDevice->vdp = pico9918_new();

    if (!tmsDevice->vdp)
    {
      free(tmsDevice);
      destroyDevice(&device);
      return device;
    }

    tms9918InitPixelMap();

    pico9918_t* tms9918 = tmsDevice->vdp;
    pico9918_gpu_init(PICO9918_INST_ONLY);
    pico9918_gpu_set_config_save_callback(&tms9918ConfigSaved);
    pico9918_frame_set_config_reload_callback(&tms9918ConfigReload);
    pico9918_set_chip(PICO9918_INST requestedChip);
    configOwner = tmsDevice;

    tms9918Configure(tmsDevice);

    device.data = tmsDevice;
    device.resetFn = &resetTms9918Device;
    device.destroyFn = &destroyTms9918Device;
    device.readFn = &readTms9918Device;
    device.writeFn = &writeTms9918Device;
    device.tickFn = &tickTms9918Device;
    device.renderFn = &renderTms9918Device;

    device.output = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_STREAMING,
                                      TMS9918_DISPLAY_WIDTH, TMS9918_DISPLAY_HEIGHT);
    #ifndef __linux__
    SDL_SetTextureScaleMode(device.output, SDL_ScaleModeBest);
    #endif
  }
  else
  {
    destroyDevice(&device);
  }

  return device;
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
    pico9918_t* tms9918 = tmsDevice->vdp;

    tmsDevice->line = 0u;
    tmsDevice->unusedTime = 0.0f;
    tmsDevice->irqLevel = 0;

    /* Clears VR56, so a program still running stops here. */
    pico9918_reset(PICO9918_INST_ONLY);
    pico9918_gpu_init(PICO9918_INST_ONLY);

    tms9918DiagSetup();
    tms9918Seed(tmsDevice);
    tms9918Configure(tmsDevice);

    /* Hands the gpu to the library: it runs a program from the write that arms it, so
       a detection probe reading its result back cannot miss it, and paces the rest per
       scanline. Resolved here rather than per scanline - it reads the environment. */
    pico9918_gpu_set_clock(PICO9918_INST tms9918GpuIps());

    /* Power-cycle the board: the animation back to its start, and the frame counter
       and display-enable latch that gate it back to power-on. Only a PICO9918 has the
       overlay, so on the two chips below this changes nothing anyone can see. */
    pico9918_splash_reset();
    pico9918_frame_count  = 0;
    pico9918_valid_writes = false;
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
    if (tmsDevice->configPending)
      tms9918ConfigStore(tmsDevice);

    if (configOwner == tmsDevice)
    {
      pico9918_gpu_set_config_save_callback(NULL);
      pico9918_frame_set_config_reload_callback(NULL);
      configOwner = NULL;
    }

    pico9918_destroy(tmsDevice->vdp);
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

    /* A 640-wide RGBA row is 2560 bytes and the driver almost always hands that back
       unpadded, but "almost always" is not the contract - honour the pitch it gave. */
    if (pitch == TMS9918_DISPLAY_WIDTH * (int)sizeof(uint32_t))
    {
      memcpy(pixels, tmsDevice->frameBuffer, sizeof(tmsDevice->frameBuffer));
    }
    else
    {
      for (unsigned int y = 0; y < TMS9918_DISPLAY_HEIGHT; ++y)
        memcpy((uint8_t*)pixels + (size_t)y * pitch,
               tmsDevice->frameBuffer + (size_t)y * TMS9918_DISPLAY_WIDTH,
               TMS9918_DISPLAY_WIDTH * sizeof(uint32_t));
    }

    SDL_UnlockTexture(device->output);
  }
}

/* Function:  tms9918BlitLine
 * --------------------
 * one rendered line into the frame buffer, BGR12 to RGBA8888
 */
static void tms9918BlitLine(TMS9918Device* tmsDevice, unsigned int dy)
{
  uint32_t* dest = tmsDevice->frameBuffer + (size_t)dy * TMS9918_DISPLAY_WIDTH;

  for (unsigned int x = 0; x < TMS9918_DISPLAY_WIDTH; ++x)
    dest[x] = bgr12Rgba[tmsDevice->pixels[x] & 0x0fffu];
}

/* Function:  tms9918VirtualLine
 * --------------------
 * one virtual (VGA) line, written out vPixelScale times
 */
static void tms9918VirtualLine(TMS9918Device* tmsDevice)
{
  pico9918_t* tms9918 = tmsDevice->vdp;

  if (tmsDevice->line < tmsDevice->params.vVirtualPixels)
  {
    /* Through the frame module, not the bare scan line: SR3, the gpu trigger, the
       palette LUT, the overlays and the CRT dim all live in there. It fills the whole
       320-word line - both borders and the picture - so there is nothing left to
       paint, and it renders once per virtual line however many output rows share it. */
    const unsigned int scale = tmsDevice->display.vPixelScale ? tmsDevice->display.vPixelScale : 1u;

    for (unsigned int rep = 0; rep < scale; ++rep)
    {
      const unsigned int dy = tmsDevice->line * scale + rep;

      if (dy >= TMS9918_DISPLAY_HEIGHT) continue;

      /* False means the buffer is untouched, so this row is still the last one's. */
      if (pico9918_frame_output_line(PICO9918_INST dy, &tmsDevice->params, tmsDevice->pixels))
      {
        tms9918BlitLine(tmsDevice, dy);
      }
      else
      {
        memcpy(tmsDevice->frameBuffer + (size_t)dy * TMS9918_DISPLAY_WIDTH,
               tmsDevice->frameBuffer + (size_t)(dy - 1u) * TMS9918_DISPLAY_WIDTH,
               TMS9918_DISPLAY_WIDTH * sizeof(uint32_t));
      }
    }

    /* Tested inside the visible field, as the library's reference host does: in row-30
       modes the trigger sits at vVirtualPixels, where a board raises the interrupt
       from end-of-frame instead. */
    if (tmsDevice->line == tmsDevice->geometry.triggerScanline)
      pico9918_frame_end_of_scanline(PICO9918_INST_ONLY);
  }

  if (tmsDevice->line == tmsDevice->params.vVirtualPixels)
    pico9918_frame_porch(PICO9918_INST_ONLY);

  if (++tmsDevice->line >= tmsDevice->fieldLines)
  {
    tmsDevice->line = 0u;
    tmsDevice->geometry = pico9918_frame_end(PICO9918_INST 40.0f, TMS9918_FPS, &tmsDevice->display);
    tms9918RecomputeCadence(tmsDevice);
  }
}

/* Function:  tickTms9918Device
 * --------------------
 * renders the whole scanlines that have fallen due since the last call. deltaTime says
 * how many; the remainder is carried, so a caller ticking faster than a line takes
 * simply renders nothing until one is owed.
 */
static void tickTms9918Device(HBC56Device* device, uint32_t deltaTicks, float deltaTime)
{
  TMS9918Device* tmsDevice = getTms9918Device(device);
  if (tmsDevice)
  {
    pico9918_t* tms9918 = tmsDevice->vdp;

    deltaTime += tmsDevice->unusedTime;

    float rowsFlt = 0.0f;
    tmsDevice->unusedTime = modff(deltaTime / (float)TMS9918_ROW_TIME, &rowsFlt) * TMS9918_ROW_TIME;

    const int rows = (int)rowsFlt;

    for (int row = 0; row < rows; ++row)
    {
      /* Latched: a mode change inside the loop rewrites linesPerCall, and re-reading it
         would run a line of the next field before this one had finished. */
      const unsigned int calls = tmsDevice->linesPerCall;

      for (unsigned int i = 0; i < calls; ++i)
        tms9918VirtualLine(tmsDevice);
    }

    if (tmsDevice->configPending)
      tms9918ConfigStore(tmsDevice);

    /* /INT is a level: the library holds it while both the status flag and R1's
       interrupt enable are set, and reading the status register drops it. */
    const int level = pico9918_interrupt_status(PICO9918_INST_ONLY) ? 1 : 0;
    if (level != tmsDevice->irqLevel)
    {
      tmsDevice->irqLevel = level;
      hbc56Interrupt(tmsDevice->irq, level ? INTERRUPT_RAISE : INTERRUPT_RELEASE);
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
    pico9918_t* tms9918 = tmsDevice->vdp;

    if (addr == tmsDevice->regAddr)
    {
      *val = pico9918_read_status(PICO9918_INST_ONLY);
      if (!dbg)
      {
        tmsDevice->irqLevel = 0;
        hbc56Interrupt(tmsDevice->irq, INTERRUPT_RELEASE);
      }
      return 1;
    }
    else if (addr == tmsDevice->dataAddr)
    {
      if (dbg)
      {
        *val = pico9918_read_data_no_inc(PICO9918_INST_ONLY);
      }
      else
      {
        *val = pico9918_read_data(PICO9918_INST_ONLY);
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
    pico9918_t* tms9918 = tmsDevice->vdp;

    if (addr == tmsDevice->regAddr)
    {
      pico9918_write_addr(PICO9918_INST val);
      return 1;
    }
    else if (addr == tmsDevice->dataAddr)
    {
      pico9918_write_data(PICO9918_INST val);
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
    pico9918_t* tms9918 = tmsDevice->vdp;
    return pico9918_vram_value(PICO9918_INST vramAddr);
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
    pico9918_t* tms9918 = tmsDevice->vdp;
    return pico9918_reg_value(PICO9918_INST (pico9918_register_t)reg);
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
    pico9918_t* tms9918 = tmsDevice->vdp;
    pico9918_write_reg_value(PICO9918_INST (pico9918_register_t)reg, value);
  }
}

/* Function:  getTms9918Mode
  * --------------------
  * current display mode
  */
int getTms9918Mode(HBC56Device* device)
{
  TMS9918Device* tmsDevice = getTms9918Device(device);
  if (tmsDevice)
  {
    pico9918_t* tms9918 = tmsDevice->vdp;
    return (int)pico9918_display_mode(PICO9918_INST_ONLY);
  }
  return 0;
}
