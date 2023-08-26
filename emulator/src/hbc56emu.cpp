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
#else
#define HAVE_FOPEN_S 1
#endif

#include "hbc56emu.h"

#include "imgui.h"
#include "imgui_impl_sdl2.h"
#include "imgui_impl_sdlrenderer2.h"

#if !__EMSCRIPTEN__
#include "ImGuiFileBrowser.h"
#endif

#include "audio.h"

#include "debugger/debugger.h"

#include "devices/memory_device.h"
#include "devices/6502_device.h"
#include "devices/tms9918_device.h"
#include "devices/lcd_device.h"
#include "devices/keyboard_device.h"
#include "devices/nes_device.h"
#include "devices/ay38910_device.h"
#include "devices/uart_device.h"
#include "devices/via_device.h"


#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <string.h>
#include <queue>

#define DEFAULT_WINDOW_WIDTH  640
#define DEFAULT_WINDOW_HEIGHT 480



static HBC56Device devices[HBC56_MAX_DEVICES];
static int deviceCount = 0;

static HBC56Device* cpuDevice = NULL;
static HBC56Device* romDevice = NULL;
static HBC56Device* kbDevice = NULL;

static SDL_Window* window = NULL;

static char tempBuffer[256];

#define MAX_IRQS 5
static HBC56InterruptSignal irqs[MAX_IRQS];

static SDL_Renderer* renderer = NULL;
SDL_mutex* kbQueueMutex = nullptr;

static std::queue<SDL_KeyboardEvent> pasteQueue;

static int loadRom(const char* filename);

#if !__EMSCRIPTEN__
static imgui_addons::ImGuiFileBrowser file_dialog; // As a class member or globally
#endif

#ifdef __cplusplus
extern "C" {
#endif


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

  for (int i = 0; i < MAX_IRQS; ++i)
  {
    irqs[i] = INTERRUPT_RELEASE;
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
 * add a new device * returns a pointer to the added device
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
 raise or release an interrupt (irq# and signal)
 */
void hbc56Interrupt(uint8_t irq, HBC56InterruptSignal signal)
{
  if (irq == 0 || irq > MAX_IRQS) return;
  irq--;

  irqs[irq] = signal;

  if (cpuDevice)
  {
    signal = INTERRUPT_RELEASE;

    for (int i = 0; i < MAX_IRQS;++i)
    {
      if (irqs[i] == INTERRUPT_RAISE)
      {
        signal = INTERRUPT_RAISE;
      }
      else if (irqs[i] == INTERRUPT_TRIGGER)
      {
        irqs[i] = INTERRUPT_RELEASE;
        signal = INTERRUPT_RAISE;
      }
    }

    interrupt6502(cpuDevice, INTERRUPT_INT, signal);
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

/* Function:  hbc56LoadSource
 * --------------------
 * load labels. rptFileContents is a null terminated string (rpt file contents)
 */
void hbc56LoadSource(const char* labelFileContents)
{
  debuggerLoadSource(labelFileContents);
}

/* Function:  hbc56LoadLayout
 * --------------------
 * load the ui layout. layoutFile is a null terminated string (imgui.ini contents)
 */
void hbc56LoadLayout(const char* layoutFile)
{
  if (layoutFile[0] == 0)
  {
    ImGui::LoadIniSettingsFromDisk("imgui.ini");
    return;
  }

  ImGui::LoadIniSettingsFromMemory(layoutFile);
}

/* Function:  hbc56GetLayout
 * --------------------
 * get the ui layout.
 */
const char* hbc56GetLayout()
{
  return ImGui::SaveIniSettingsToMemory(0);
}

/* Function:  hbc56PasteText
 * --------------------
 * paste text (emulates key presses)
 */
void hbc56PasteText(const char* text)
{
  SDL_LockMutex(kbQueueMutex);

  SDL_KeyboardEvent ev;
  ev.type = SDL_KEYUP;
  ev.keysym.scancode = SDL_SCANCODE_LCTRL;
  pasteQueue.push(ev);
  ev.keysym.scancode = SDL_SCANCODE_RCTRL;
  pasteQueue.push(ev);

  while (*text)
  {
    char c = *(text++);
    SDL_Scancode sc = SDL_SCANCODE_UNKNOWN;
    bool shift = false;
    if (SDL_islower(c)) {
      sc = (SDL_Scancode)(c - 'a' + SDL_SCANCODE_A);
    }
    else if (SDL_isupper(c)) 
    {
      sc = (SDL_Scancode)(c - 'A' + SDL_SCANCODE_A);
      shift = true;
    }
    else if (SDL_isdigit(c))
    {
      if (c == '0') sc = SDL_SCANCODE_0;
      else sc = (SDL_Scancode)(c - '1' + SDL_SCANCODE_1);
    }
    else
    {
      switch (c)
      {
        case ' ': sc = SDL_SCANCODE_SPACE; break;
        case '!': sc = SDL_SCANCODE_1; shift = true; break;
        case '\"': sc = SDL_SCANCODE_APOSTROPHE; shift = true; break;
        case '#': sc = SDL_SCANCODE_3; shift = true; break;
        case '$': sc = SDL_SCANCODE_4; shift = true; break;
        case '%': sc = SDL_SCANCODE_5; shift = true; break;
        case '&': sc = SDL_SCANCODE_7; shift = true; break;
        case '\'': sc = SDL_SCANCODE_APOSTROPHE; break;
        case '(': sc = SDL_SCANCODE_9; shift = true; break;
        case ')': sc = SDL_SCANCODE_0; shift = true; break;
        case '*': sc = SDL_SCANCODE_8; shift = true; break;
        case '+': sc = SDL_SCANCODE_EQUALS; shift = true; break;
        case ',': sc = SDL_SCANCODE_COMMA;  break;
        case '-': sc = SDL_SCANCODE_MINUS;  break;
        case '.': sc = SDL_SCANCODE_PERIOD;  break;
        case '/': sc = SDL_SCANCODE_SLASH;  break;
        case ':': sc = SDL_SCANCODE_SEMICOLON; shift = true; break;
        case ';': sc = SDL_SCANCODE_SEMICOLON; break;
        case '<': sc = SDL_SCANCODE_COMMA; shift = true; break;
        case '=': sc = SDL_SCANCODE_EQUALS;  break;
        case '>': sc = SDL_SCANCODE_PERIOD; shift = true; break;
        case '?': sc = SDL_SCANCODE_SLASH; shift = true; break;
        case '[': sc = SDL_SCANCODE_LEFTBRACKET; break;
        case '\\': sc = SDL_SCANCODE_BACKSLASH; break;
        case ']': sc = SDL_SCANCODE_RIGHTBRACKET; break;
        case '^': sc = SDL_SCANCODE_6; shift = true; break;
        case '_': sc = SDL_SCANCODE_MINUS; shift = true; break;
        case '`': sc = SDL_SCANCODE_GRAVE; break;
        case '{': sc = SDL_SCANCODE_LEFTBRACKET; shift = true; break;
        case '|': sc = SDL_SCANCODE_BACKSLASH; shift = true; break;
        case '}': sc = SDL_SCANCODE_RIGHTBRACKET; shift = true; break;
        case '~': sc = SDL_SCANCODE_GRAVE; shift = true; break;
        case '\t': sc = SDL_SCANCODE_TAB; break;
        case '\n': sc = SDL_SCANCODE_RETURN; break;
      }
    }

    if (sc != SDL_SCANCODE_UNKNOWN)
    {
      ev.type = SDL_KEYDOWN;
      if (shift)
      {
        ev.keysym.scancode = SDL_SCANCODE_LSHIFT;
        pasteQueue.push(ev);
      }

      ev.keysym.scancode = sc;
      pasteQueue.push(ev);
      ev.type = SDL_KEYUP;
      pasteQueue.push(ev);

      if (shift)
      {
        ev.keysym.scancode = SDL_SCANCODE_LSHIFT;
        pasteQueue.push(ev);
      }
    }    
  }
  SDL_UnlockMutex(kbQueueMutex);
}

/* Function:  hbc56ToggleDebugger
 * --------------------
 * toggle the debugger
 */
void hbc56ToggleDebugger()
{
  debug6502State(cpuDevice, (getDebug6502State(cpuDevice) == CPU_RUNNING) ? CPU_BREAK : CPU_RUNNING);
}

/* Function:  hbc56DebugBreak
 * --------------------
 * break
 */
void hbc56DebugBreak()
{
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

/* Function:  hbc56DebugBreakOnInt
 * --------------------
 * break on interrupt
 */
void hbc56DebugBreakOnInt()
{
  debug6502State(cpuDevice, CPU_BREAK_ON_INTERRUPT);
}

/* Function:  hbc56MemRead
 * --------------------
 * read a value from a device
 */
uint8_t hbc56MemRead(uint16_t addr, bool dbg)
{
  uint8_t val = 0x00;
  if (addr == 0x7fdf)
  {
    for (int i = 0; i < MAX_IRQS; ++i)
    {
      val |= !!irqs[i] << i;
    }
    return val;
  }

  SDL_LockMutex(kbQueueMutex);
  for (size_t i = 0; i < deviceCount; ++i)
  {
    if (readDevice(&devices[i], addr, &val, dbg))
      break;
  }
  SDL_UnlockMutex(kbQueueMutex);

  return val;
}

/* Function:  hbc56MemWrite
 * --------------------
 * write a valude to a device
 */
void hbc56MemWrite(uint16_t addr, uint8_t val)
{
  for (size_t i = 0; i < deviceCount; ++i)
  {
    if (writeDevice(&devices[i], addr, val))
      break;
  }
}

#ifdef __cplusplus
}
#endif



/* emulator constants */
#define LOGICAL_DISPLAY_SIZE_X 320
#define LOGICAL_DISPLAY_SIZE_Y 240
#define LOGICAL_DISPLAY_BPP    3

/* emulator state */
static int done;
static double perfFreq = 0.0;
static int tickCount = 0;
static int mouseZ = 0;


/* Function:  doTick
 * --------------------
 * regular "tick" for devices. devices can use either real time or clock ticks
 * to update their state
 */
static void doTick()
{
  static double lastTime = 0.0;
  static double unusedClockTicksTime = 0.0;
  static const double maxTime = 1.0 / 60.0;

  double thisTime = (double)SDL_GetPerformanceCounter() / perfFreq;
  if (thisTime - lastTime > maxTime) lastTime = thisTime - maxTime;

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


static void aboutDialog(bool *aboutOpen)
{
  if (ImGui::Begin("About HBC-56 Emulator", aboutOpen, ImGuiWindowFlags_AlwaysAutoResize | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoDocking | ImGuiWindowFlags_NoCollapse))
  {
    ImGui::Text("HBC-56 Emulator v0.2\n\n");
    ImGui::Text("(C) 2022 Troy Schrapel\n\n");
    ImGui::Separator();
    ImGui::Text("HBC-56 Emulator is licensed under the MIT License,\nsee LICENSE for more information.\n\n");
    ImGui::Text("https://github.com/visrealm/hbc-56");
  }
  ImGui::End();
}


/* Function:  doRender
 * --------------------
 * render the various displays to the window
 */
static void doRender()
{
  static bool aboutOpen = false;

  static bool showRegisters = true;
  static bool showStack = true;
  static bool showDisassembly = true;
  static bool showSource = true;
  static bool showBreakpoints = true;

  static bool showMemory = true;
  static bool showTms9918Memory = true;
  static bool showTms9918Registers = true;
  static bool showTms9918Patterns = true;
  static bool showTms9918Sprites = true;
  static bool showVia6522 = true;

  ImGui_ImplSDLRenderer2_NewFrame();
  ImGui_ImplSDL2_NewFrame();
  ImGui::NewFrame();

  static ImGuiDockNodeFlags dockspace_flags = ImGuiDockNodeFlags_None;

  ImGuiWindowFlags window_flags = ImGuiWindowFlags_MenuBar | ImGuiWindowFlags_NoDocking;
  const ImGuiViewport* viewport = ImGui::GetMainViewport();
  ImGui::SetNextWindowPos(viewport->WorkPos);
  ImGui::SetNextWindowSize(viewport->WorkSize);
  ImGui::SetNextWindowViewport(viewport->ID);
  ImGui::PushStyleVar(ImGuiStyleVar_WindowRounding, 0.0f);
  ImGui::PushStyleVar(ImGuiStyleVar_WindowBorderSize, 0.0f);
  window_flags |= ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoCollapse | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoMove;
  window_flags |= ImGuiWindowFlags_NoBringToFrontOnFocus | ImGuiWindowFlags_NoNavFocus;

  // When using ImGuiDockNodeFlags_PassthruCentralNode, DockSpace() will render our background
  // and handle the pass-thru hole, so we ask Begin() to not render a background.
  if (dockspace_flags & ImGuiDockNodeFlags_PassthruCentralNode)
    window_flags |= ImGuiWindowFlags_NoBackground;

  // Important: note that we proceed even if Begin() returns false (aka window is collapsed).
  // This is because we want to keep our DockSpace() active. If a DockSpace() is inactive,
  // all active windows docked into it will lose their parent and become undocked.
  // We cannot preserve the docking relationship between an active window and an inactive docking, otherwise
  // any change of dockspace/settings would lead to windows being stuck in limbo and never being visible.
  static bool open = true;
  ImGui::PushStyleVar(ImGuiStyleVar_WindowPadding, ImVec2(0.0f, 0.0f));
  ImGui::PushStyleVar(ImGuiStyleVar_ItemSpacing, ImVec2(0.0f, 0.0f));
  ImGui::PushStyleColor(ImGuiCol_WindowBg, ImVec4(1.0f, 0.0f, 0.0f, 1.0f));
  ImGui::Begin("Workspace", &open, window_flags);
  ImGui::PopStyleColor();
  ImGui::PopStyleVar(2);
  ImGui::PopStyleVar(2);

  ImGuiID dockspace_id = ImGui::GetID("Workspace");
  ImGui::PushStyleColor(ImGuiCol_WindowBg, ImVec4(0.12f, 0.12f, 0.12f, 1.0f));
  ImGui::PushStyleColor(ImGuiCol_TitleBg, ImVec4(0.12f, 0.12f, 0.12f, 1.0f));
  ImGui::PushStyleColor(ImGuiCol_ScrollbarBg, ImVec4(0.12f, 0.12f, 0.12f, 1.0f));
  ImGui::PushStyleColor(ImGuiCol_TableHeaderBg, ImVec4(0.1f, 0.1f, 0.1f, 1.0f));
  ImGui::DockSpace(dockspace_id, ImVec2(0.0f, 0.0f), dockspace_flags);

  bool fileOpen = false;

  if (ImGui::BeginMenuBar())
  {
    if (ImGui::BeginMenu("File"))
    {
#if !__EMSCRIPTEN__
      if (ImGui::MenuItem("Open...", "<Ctrl> + O")) { fileOpen = true; }
#endif
        if (ImGui::MenuItem("Reset", "<Ctrl> + R")) { hbc56Reset(); }
#if !__EMSCRIPTEN__
      if (ImGui::MenuItem("Exit", "Esc")) { done = true; }
#endif
      ImGui::EndMenu();
    }

    if (ImGui::BeginMenu("Debug"))
    {
      bool isRunning = getDebug6502State(cpuDevice) == CPU_RUNNING;

      if (ImGui::MenuItem("Break", "<F12>", false, isRunning)) { hbc56DebugBreak(); }
      if (ImGui::MenuItem("Break on Interrupt", "<F7>", false, isRunning)) { hbc56DebugBreakOnInt(); }
      ImGui::Separator();
      if (ImGui::MenuItem("Continue", "<F5>", false, !isRunning)) { hbc56DebugRun(); }
      ImGui::Separator();
      if (ImGui::MenuItem("Step In", "<F11>", false, !isRunning)) { hbc56DebugStepInto(); }
      if (ImGui::MenuItem("Step Over", "<F10>", false, !isRunning)) { hbc56DebugStepOver(); }
      if (ImGui::MenuItem("Step Out", "<Shift> + <F11>", false, !isRunning)) { hbc56DebugStepOut(); }
      ImGui::EndMenu();
    }

    //ImGui::PushStyleColor(ImGuiCol_WindowBg, ImVec4(0.12f, 0.12f, 0.12f, 1.0f));
    if (ImGui::BeginMenu("Window"))
    {
      if (ImGui::BeginMenu("Debugger"))
      {
        ImGui::MenuItem("Registers", "<Ctrl> + E", &showRegisters);
        ImGui::MenuItem("Stack", "<Ctrl> + S", &showStack);
        ImGui::MenuItem("Disassembly", "<Ctrl> + D", &showDisassembly);
        ImGui::MenuItem("Source", "<Ctrl> + O", &showSource);
        ImGui::MenuItem("Memory", "<Ctrl> + M", &showMemory);
        ImGui::MenuItem("Breakpoints", "<Ctrl> + B", &showBreakpoints);
        ImGui::Separator();
        ImGui::MenuItem("TMS9918A VRAM", "<Ctrl> + G", &showTms9918Memory);
        ImGui::MenuItem("TMS9918A Registers", "<Ctrl> + T", &showTms9918Registers);
        ImGui::MenuItem("TMS9918A Patterns", "<Ctrl> + P", &showTms9918Patterns);
        ImGui::MenuItem("TMS9918A Sprites", "<Ctrl> + I", &showTms9918Sprites);
        ImGui::Separator();
        ImGui::MenuItem("65C22 VIA", "<Ctrl> + V", &showVia6522);
        ImGui::EndMenu();
      }

      for (size_t i = 0; i < deviceCount; ++i)
      {
        if (devices[i].output)
        {
          ImGui::MenuItem(devices[i].name, "", &devices[i].visible);
        }
      }
      ImGui::EndMenu();
    }

    if (ImGui::BeginMenu("Help"))
    {
      if (ImGui::MenuItem("About...")) { aboutOpen = true; }

      ImGui::EndMenu();
    }
    ImGui::EndMenuBar();
  }

#if !__EMSCRIPTEN__
  if (fileOpen) ImGui::OpenPopup("Open File");

  if (file_dialog.showFileDialog("Open File", imgui_addons::ImGuiFileBrowser::DialogMode::OPEN, ImVec2(700, 310), ".o"))
  {
    loadRom(file_dialog.selected_path.c_str());
  }
#endif


  for (size_t i = 0; i < deviceCount; ++i)
  {
    renderDevice(&devices[i]);
    if (devices[i].output && devices[i].visible)
    {
      int texW, texH;
      SDL_QueryTexture(devices[i].output, NULL, NULL, &texW, &texH);
      
      ImGui::PushStyleVar(ImGuiStyleVar_WindowPadding, ImVec2(0, 0));
      ImGui::Begin(devices[i].name, &devices[i].visible);
      ImGui::PopStyleVar();

      ImVec2 windowSize = ImGui::GetContentRegionAvail();

      double scaleX = windowSize.x / (double)texW;
      double scaleY = windowSize.y / (double)texH;

      double scale = (scaleX < scaleY) ? scaleX : scaleY;

      ImVec2 imageSize = windowSize;
      imageSize.x = (float)(texW * scale);
      imageSize.y = (float)(texH * scale);

      ImVec2 pos = ImGui::GetCursorPos();
      pos.x += (windowSize.x - imageSize.x) / 2;
      pos.y += (windowSize.y - imageSize.y) / 2;
      ImGui::SetCursorPos(pos);

      ImGui::Image(devices[i].output, imageSize);
      ImGui::End();
    }
  }

  if (aboutOpen) aboutDialog(&aboutOpen);

  if (showRegisters) debuggerRegistersView(&showRegisters);
  if (showStack) debuggerStackView(&showStack);
  if (showDisassembly)debuggerDisassemblyView(&showDisassembly);
  if (showSource) debuggerSourceView(&showSource);
  if (showMemory) debuggerMemoryView(&showMemory);
  if (showBreakpoints) debuggerBreakpointsView(&showBreakpoints);
  if (showTms9918Memory) debuggerVramMemoryView(&showTms9918Memory);
  if (showTms9918Registers) debuggerTmsRegistersView(&showTms9918Registers);
  if (showTms9918Patterns) debuggerTmsPatternsView(renderer, &showTms9918Registers);
  if (showTms9918Sprites) debuggerTmsSpritesView(renderer, &showTms9918Registers);
  if (showVia6522) debuggerVia6522View(&showVia6522);

  ImGui::PopStyleColor(4);

  ImGui::End();

  ImGui::Render();
  //SDL_SetRenderDrawColor(renderer, (Uint8)(clear_color.x * 255), (Uint8)(clear_color.y * 255), (Uint8)(clear_color.z * 255), (Uint8)(clear_color.w * 255));
  SDL_RenderClear(renderer);
  ImGui_ImplSDLRenderer2_RenderDrawData(ImGui::GetDrawData());
  SDL_RenderPresent(renderer);
}


/* Function:  doEvents
 * --------------------
 * handle events which control emulator / debugger
 */
static void doEvents()
{
  SDL_LockMutex(kbQueueMutex);
    
  SDL_Event event;
  while (SDL_PollEvent(&event))
  {
    ImGui_ImplSDL2_ProcessEvent(&event);

    int skipProcessing = 0;
    switch (event.type)
    {
      case SDL_WINDOWEVENT:
        switch (event.window.event)
        {
          case SDL_WINDOWEVENT_CLOSE:
            done = 1;
            break;

          default:
            break;
        }
        break;

      case SDL_KEYDOWN:
      {
        bool withControl = (event.key.keysym.mod & KMOD_CTRL) ? 1 : 0;
        bool withShift = (event.key.keysym.mod & KMOD_SHIFT) ? 1 : 0;

        switch (event.key.keysym.sym)
        {
          case SDLK_r:
            if (withControl)
            {
              skipProcessing = 1;
              hbc56Reset();
            }
            break;

          case SDLK_d:
            if (withControl)
            {
              hbc56ToggleDebugger();
            }
            break;

          case SDLK_v:
            if (withControl)
            {
              skipProcessing = 1;
              if (SDL_HasClipboardText()) {
                char *text = SDL_GetClipboardText();
                hbc56PasteText(text);
                SDL_free(text);
              }
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

          case SDLK_F7:
            hbc56DebugBreakOnInt();
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
          break;
        }
      }

      case SDL_KEYUP:
      {
        bool withControl = (event.key.keysym.mod & KMOD_CTRL) ? 1 : 0;

        switch (event.key.keysym.sym)
        {
          case SDLK_r:
            if (withControl) skipProcessing = 1;
            break;

          case SDLK_d:
            if (withControl) skipProcessing = 1;
            break;

          case SDLK_v:
            if (withControl) skipProcessing = 1;
            break;

          default:
            break;
        }
        break;
      }

      case SDL_MOUSEWHEEL:
      {
        mouseZ = event.wheel.y;
        break;
      }

      case SDL_DROPFILE:
      {
        loadRom(event.drop.file);
        SDL_free(event.drop.file);
        hbc56Reset();
        return;
      }

    }

    if (!skipProcessing)
    {
      if (event.type == SDL_KEYDOWN || event.type == SDL_KEYUP)
      {
        pasteQueue.push(event.key);
      }
      else
      {
        for (size_t i = 0; i < deviceCount; ++i)
        {
          eventDevice(&devices[i], &event);
        }
      }
    }
  }

  if (keyboardDeviceQueueEmpty(kbDevice))
  {
    for (int j = 0; j < 2 && !pasteQueue.empty(); ++j)
    {
      SDL_Event ev;
      ev.type = pasteQueue.front().type;
      ev.key = pasteQueue.front();
      pasteQueue.pop();

      for (size_t i = 0; i < deviceCount; ++i)
      {
        eventDevice(&devices[i], &ev);
      }
    }
  }
  SDL_UnlockMutex(kbQueueMutex);
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

    SDL_snprintf(tempBuffer, sizeof(tempBuffer), "Troy's HBC-56 Emulator - %0.6f%%", getCpuUtilization(cpuDevice) * 100.0f);
    SDL_SetWindowTitle(window, tempBuffer);

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

#ifndef HAVE_FOPEN_S
  ptr = fopen(filename, "rb");
#else
  fopen_s(&ptr, filename, "rb");
#endif

  SDL_snprintf(tempBuffer, sizeof(tempBuffer), "Troy's HBC-56 Emulator - %s", filename);
  SDL_SetWindowTitle(window, tempBuffer);

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

#ifndef HAVE_FOPEN_S
      ptr = fopen(labelMapFile, "rb");
#else
      fopen_s(&ptr, labelMapFile, "rb");
#endif
      if (ptr)
      {
        fseek(ptr, 0, SEEK_END);
        long fsize = ftell(ptr);
        fseek(ptr, 0, SEEK_SET);  /* same as rewind(f); */

        char *lblFileContent = (char*)malloc(fsize + 1);
        fread(lblFileContent, fsize, 1, ptr);
        lblFileContent[fsize] = 0;
        fclose(ptr);

        hbc56LoadLabels(lblFileContent);
        free(lblFileContent);
      }

      SDL_strlcpy(labelMapFile, filename, FILENAME_MAX);
      ln = SDL_strlen(labelMapFile);
      SDL_strlcpy(labelMapFile + ln, ".rpt", FILENAME_MAX - ln);

#ifndef HAVE_FOPEN_S
      ptr = fopen(labelMapFile, "rb");
#else
      fopen_s(&ptr, labelMapFile, "rb");
#endif
      if (ptr)
      {
        fseek(ptr, 0, SEEK_END);
        long fsize = ftell(ptr);
        fseek(ptr, 0, SEEK_SET);  /* same as rewind(f); */

        char* lblFileContent = (char*)malloc(fsize + 1);
        fread(lblFileContent, fsize, 1, ptr);
        lblFileContent[fsize] = 0;
        fclose(ptr);

        hbc56LoadSource(lblFileContent);
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
  if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER | SDL_INIT_GAMECONTROLLER) != 0)
  {
    printf("Error: %s\n", SDL_GetError());
    return -1;
  }

  kbQueueMutex = SDL_CreateMutex();

  int window_flags = 0;
#if !__EMSCRIPTEN__
  window_flags |= SDL_WINDOW_RESIZABLE;
#endif
  window = SDL_CreateWindow("HBC-56 Emulator", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 1600, 800, (SDL_WindowFlags)window_flags);

  // Setup SDL_Renderer instance
  renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_PRESENTVSYNC | SDL_RENDERER_ACCELERATED);
  if (renderer == NULL)
  {
    SDL_Log("Error creating SDL_Renderer!");
    return 0;
  }
  //SDL_RendererInfo info;
  //SDL_GetRendererInfo(renderer, &info);
  //SDL_Log("Current SDL_Renderer: %s", info.name);


  // Setup Dear ImGui context
  IMGUI_CHECKVERSION();
  ImGui::CreateContext();

#if !__EMSCRIPTEN__
  char *basePath = SDL_GetBasePath();

  char tmpBuf[512];
  SDL_snprintf(tmpBuf, sizeof(tmpBuf), "%simgui.ini", basePath);
  SDL_free(basePath);

  ImGui::LoadIniSettingsFromDisk(tmpBuf);
  ImGui::LoadIniSettingsFromDisk("imgui.ini");
#endif


  ImGuiIO& io = ImGui::GetIO(); (void)io;
  io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;       // Enable Keyboard Controls
  io.ConfigFlags |= ImGuiConfigFlags_DockingEnable;           // Enable Docking
  io.ConfigFlags |= ImGuiConfigFlags_ViewportsEnable;         // Enable Multi-Viewport / Platform Windows


  // Setup Dear ImGui style
  ImGui::StyleColorsDark();

  ImGuiStyle& style = ImGui::GetStyle();
  if (io.ConfigFlags & ImGuiConfigFlags_ViewportsEnable)
  {
    style.WindowRounding = 0.0f;
    style.Colors[ImGuiCol_WindowBg].w = 1.0f;
    style.WindowMenuButtonPosition = ImGuiDir_Right;
  }


  // Setup Platform/Renderer backends
  ImGui_ImplSDL2_InitForSDLRenderer(window, renderer);
  ImGui_ImplSDLRenderer2_Init(renderer);


  perfFreq = (double)SDL_GetPerformanceFrequency();

  /* enable standard application logging */
  SDL_LogSetPriority(SDL_LOG_CATEGORY_APPLICATION, SDL_LOG_PRIORITY_INFO);

  /* add the cpu device */
  cpuDevice = hbc56AddDevice(create6502CpuDevice(debuggerIsBreakpoint));

  /* initialise the debugger */
  debuggerInit(getCpuDevice(cpuDevice));

  int romLoaded = 0;
  LCDType lcdType = LCD_GRAPHICS;

#if __EMSCRIPTEN__
  /* load the hard-coded rom */
  romLoaded = loadRom("rom.bin");
  lcdType = LCD_GRAPHICS;
#endif
  int doBreak = 0;

  /* parse arguments */
  for (int i = 1; i < argc;)
  {
    int consumed;

    consumed = 0;//SDLCommonArg(state, i);
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
        doBreak = 1;
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
      //SDLCommonLogUsage(state, argv[0], options);
      return 2;
    }
    i += consumed;
  }

  if (romLoaded == 0)
  {
    static const char* options[] = { "--rom <romfile>","[--brk]","[--keyboard]","[--lcd 1602|2004|12864]", NULL };
    //SDLCommonLogUsage(state, argv[0], options);

#ifndef __EMSCRIPTEN__
    SDL_snprintf(tempBuffer, sizeof(tempBuffer), "No HBC-56 ROM file.\n\nUse --rom <romfile>");
    SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR, "Troy's HBC-56 Emulator", tempBuffer, NULL);
#endif

    return 2;
  }

  /* randomise */
  srand((unsigned int)time(NULL));

  /* add the various devices */
  hbc56AddDevice(createRamDevice(HBC56_RAM_START, HBC56_RAM_END));

#if HBC56_HAVE_TMS9918
  HBC56Device *tms9918Device = hbc56AddDevice(createTms9918Device(HBC56_IO_ADDRESS(HBC56_TMS9918_DAT_PORT), HBC56_IO_ADDRESS(HBC56_TMS9918_REG_PORT), HBC56_TMS9918_IRQ, renderer));
  debuggerInitTms(tms9918Device);
#endif

#if HBC56_HAVE_KB
  kbDevice = hbc56AddDevice(createKeyboardDevice(HBC56_IO_ADDRESS(HBC56_KB_PORT), HBC56_KB_IRQ));
#endif

#if HBC56_HAVE_NES
  hbc56AddDevice(createNESDevice(HBC56_IO_ADDRESS(HBC56_NES_PORT)));
  hbc56AddDevice(createNESDevice(HBC56_IO_ADDRESS(HBC56_NES_PORT | 0x01)));
#endif

#if HBC56_HAVE_LCD
  //if (lcdType != LCD_NONE)
  {
    hbc56AddDevice(createLcdDevice(lcdType, HBC56_IO_ADDRESS(HBC56_LCD_DAT_PORT), HBC56_IO_ADDRESS(HBC56_LCD_CMD_PORT), renderer));
  }
#endif

#if HBC56_HAVE_VIA
  debuggerInitVia(hbc56AddDevice(create65C22ViaDevice(HBC56_IO_ADDRESS(HBC56_VIA_PORT), HBC56_VIA_IRQ)));
#endif

  /* initialise audio */
  hbc56Audio(1);

#if HBC56_HAVE_AY_3_8910
  hbc56AddDevice(createAY38910Device(HBC56_IO_ADDRESS(HBC56_AY38910_A_PORT), HBC56_AY38910_CLOCK, hbc56AudioFreq(), hbc56AudioChannels()));
  #if HBC56_AY_3_8910_COUNT > 1
    hbc56AddDevice(createAY38910Device(HBC56_IO_ADDRESS(HBC56_AY38910_B_PORT), HBC56_AY38910_CLOCK, hbc56AudioFreq(), hbc56AudioChannels()));
  #endif
#endif

#ifdef _WINDOWS
#if HBC56_HAVE_UART
  hbc56AddDevice(createUartDevice(HBC56_IO_ADDRESS(HBC56_UART_PORT), HBC56_UART_PORTNAME, HBC56_UART_CLOCK_FREQ, HBC56_UART_IRQ));
#endif
#endif

  done = 0;

  /* reset the machine */
  hbc56Reset();

  if (doBreak)hbc56DebugBreak();

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

  ImGui_ImplSDLRenderer2_Shutdown();
  ImGui_ImplSDL2_Shutdown();
  ImGui::DestroyContext();

  SDL_DestroyRenderer(renderer);
  SDL_DestroyWindow(window);
  SDL_Quit();

  SDL_DestroyMutex(kbQueueMutex);

  return 0;
}
