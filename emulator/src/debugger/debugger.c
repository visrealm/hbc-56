/*
 * Troy's HBC-56 Emulator - Debugger
 *
 * Copyright (c) 2021 Troy Schrapel
 *
 * This code is licensed under the MIT license
 *
 * https://github.com/visrealm/hbc-56/emulator
 *
 */

#include "debugger.h"
#include "../devices/tms9918_device.h"
#include "vrEmu6502.h"

#include <stdlib.h>
#include <ctype.h>
#include <string.h>

#define DEBUGGER_STRIDE (DEBUGGER_WIDTH_PX * DEBUGGER_BPP)

static char debuggerFrameBuffer[DEBUGGER_STRIDE * DEBUGGER_HEIGHT_PX];

static unsigned int green = 0x80ff8000;
static unsigned int dkgreen = 0x54A55400;
static unsigned int blue =  0x8080ff00;
static unsigned int red = 0xff808000;
static unsigned int white = 0xffffff00;
static unsigned int yellow = 0xffff0000;

static int fgColor = 0;
static int bgColor = 0;

extern char console_font_6x8[];
uint8_t hbc56MemRead(uint16_t addr, bool dbg);

uint16_t debugMemoryAddr = 0;
uint16_t debugTmsMemoryAddr = 0;

static VrEmu6502 *cpu6502 = NULL;

static char *labelMap[0x10000] = {NULL};
static HBC56Device* tms9918 = NULL;

static char tmpBuffer[256] = {0};

static int isProbablyConstant(const char* str)
{
  SDL_strlcpy(tmpBuffer, str, sizeof(tmpBuffer) - 1);
  SDL_strupr(tmpBuffer);
  return SDL_strcmp(str, tmpBuffer) == 0;
}

void debuggerLoadLabels(const char* labelFileContents)
{
  for (int i = 0; i < sizeof(labelMap) / sizeof(const char*); ++i)
  {
    if (labelMap[i])
    {
      free(labelMap[i]);
      labelMap[i] = NULL;
    }
  }

  if (labelFileContents)
  {
    size_t currentPos = 0;
    char lineBuffer[256];

    char *p = (char*)labelFileContents;

    for (;;)
    {
      char* end = SDL_strchr(p, '\n');
      if (end == NULL)
        break;

      SDL_strlcpy(lineBuffer, p, end - p);
      p = end + 1;

      size_t labelStart = -1, labelEnd = -1, valueStart = -1, valueEnd = -1;

      int i = 0;
      for (i = 0; i < sizeof(lineBuffer); ++i)
      {
        char c = lineBuffer[i];
        if (c == 0) break;
        if (!isspace(c) && c != '=' && c != '$')
        {
          if (labelStart == -1)
          {
            labelStart = i;
          }
          else if (labelEnd != -1 && valueStart == -1)
          {
            valueStart = i;
          }
        }
        else
        {
          if (labelStart != -1 && labelEnd == -1)
          {
            labelEnd = i;
          }
          else if (valueStart != -1 && valueEnd == -1)
          {
            valueEnd = i;
          }
        }
      }

      if (valueStart == -1)
      {
        continue;
      }
      else if (valueEnd == -1)
      {
        valueEnd = i;
      }


      char valueStr[100] = { 0 };

      SDL_strlcpy(valueStr, lineBuffer + valueStart, valueEnd - valueStart + 1);

      unsigned int value = 0;
      SDL_sscanf(valueStr, "%x", &value);

      uint16_t addr = (uint16_t)value;

      SDL_bool isUnused = SDL_strstr(lineBuffer, "; unused") != NULL;

      if (!labelMap[addr] || (isProbablyConstant(labelMap[addr]) && !isUnused))
      {
        char* label = malloc((labelEnd - labelStart) + 1);
        SDL_strlcpy(label, lineBuffer + labelStart, labelEnd - labelStart + 1);
        labelMap[addr] = label;
      }
    }
  }
}

void debuggerInit(VrEmu6502* cpu6502_)
{
  cpu6502 = cpu6502_;
  fgColor = green;
  bgColor = 0x00000000;
}

void debuggerInitTms(HBC56Device* tms)
{
  tms9918 = tms;
}


static char hexDigit(char val)
{
  if (val < 10)
    return val + '0';
  return (val - 10) + 'A';
}

static void debuggerOutputChar(char c,int x,int y)
{
  if (x >= DEBUGGER_CHARS_X || y >= DEBUGGER_CHARS_Y || x < 0 || y < 0)
    return;

  x *= 6;
  y *= 8;
  char *rp = debuggerFrameBuffer + y * DEBUGGER_STRIDE + x * DEBUGGER_BPP;
  char *cp = console_font_6x8 + c * 8;

  for (int r = 0; r < 8; ++r)
  {
    char *p = rp;
    for (int px = 0; px < 6; ++px)
    {
      int color = ((*cp) & (0x80 >> px)) ? fgColor : bgColor;

      *(p++) = (color & 0xff000000) >> 24;
      *(p++) = (color & 0x00ff0000) >> 16;
      *(p++) = (color & 0x0000ff00) >> 8;
    }
    rp += DEBUGGER_STRIDE;
    ++cp;
  }
}

static void debuggerOutputRect(int x, int y, int w, int h) {
  char* rp = debuggerFrameBuffer + y * DEBUGGER_STRIDE + x * DEBUGGER_BPP;
  for (int r = 0; r < h; ++r)
  {
    char* p = rp;
    for (int px = 0; px < w; ++px)
    {
      *(p++) = (bgColor & 0xff000000) >> 24;
      *(p++) = (bgColor & 0x00ff0000) >> 16;
      *(p++) = (bgColor & 0x0000ff00) >> 8;
    }
    rp += DEBUGGER_STRIDE;
  }
}


static void debuggerOutputHex(char c,int x,int y)
{
  debuggerOutputChar(hexDigit((c & 0xf0) >> 4),x,y);
  debuggerOutputChar(hexDigit(c & 0x0f),x + 1,y);
}

static void debuggerOutputHex16(unsigned short w,int x,int y)
{
  debuggerOutputHex((w & 0xff00) >> 8,x,y);
  debuggerOutputHex(w & 0x00ff,x + 2,y);
}

static void debuggerOutput(const char* str,int x,int y)
{
  const char *p = str;

  while (*p != 0)
  {
    debuggerOutputChar(*(p++),x++,y);
  }
}

static const int disassemblyVpos = 6;

#define OUTPUT_HEX_WITH_LABEL 0


void debuggerUpdate(SDL_Texture* tex, int mouseX, int mouseY)
{
  char buffer[10];

  int mouseCharX = mouseX / DEBUGGER_CHAR_W;
  int mouseCharY = mouseY / DEBUGGER_CHAR_H;

  memset(debuggerFrameBuffer, 0, sizeof(debuggerFrameBuffer));

  static uint16_t lastPc;

  static uint16_t highlightAddr = 0;

  fgColor = green;
  debuggerOutput("A:  $", 0, 1);
  debuggerOutputHex(vrEmu6502GetAcc(cpu6502),5,1);
  debuggerOutput(SDL_itoa(vrEmu6502GetAcc(cpu6502),buffer,10),10,1);

  debuggerOutput("X:  $", 0, 2);
  debuggerOutputHex(vrEmu6502GetX(cpu6502),5,2);
  debuggerOutput(SDL_itoa(vrEmu6502GetX(cpu6502),buffer,10),10,2);

  debuggerOutput("Y:  $", 0, 3);
  debuggerOutputHex(vrEmu6502GetY(cpu6502),5,3);
  debuggerOutput(SDL_itoa(vrEmu6502GetY(cpu6502),buffer,10),10,3);

  debuggerOutput("PC: $", 20, 1);
  debuggerOutputHex16(vrEmu6502GetPC(cpu6502), 25, 1);
  debuggerOutput(SDL_itoa(vrEmu6502GetPC(cpu6502), buffer, 10), 30, 1);

  debuggerOutput("SP: $1", 20, 2);
  debuggerOutputHex(vrEmu6502GetStackPointer(cpu6502), 26, 2);
  debuggerOutput(SDL_itoa(vrEmu6502GetStackPointer(cpu6502), buffer, 10), 30, 2);

  debuggerOutput("F:", 20, 3);

  uint8_t flags = vrEmu6502GetStatus(cpu6502);
  fgColor = (flags & FlagN) ? green : red;
  debuggerOutputChar((flags & FlagN) ? 'N' : 'n', 24, 3);
  fgColor = (flags & FlagV) ? green : red;
  debuggerOutputChar((flags & FlagV) ? 'V' : 'v', 25, 3);
  fgColor = (flags & FlagD) ? green : red;
  debuggerOutputChar((flags & FlagD) ? 'D' : 'd', 26, 3);
  fgColor = (flags & FlagI) ? green : red;
  debuggerOutputChar((flags & FlagI) ? 'I' : 'i', 27, 3);
  fgColor = (flags & FlagZ) ? green : red;
  debuggerOutputChar((flags & FlagZ) ? 'Z' : 'z', 28, 3);
  fgColor = (flags & FlagC) ? green : red;
  debuggerOutputChar((flags & FlagC) ? 'C' : 'c', 29, 3);

  fgColor = green;

  if (lastPc != vrEmu6502GetPC(cpu6502))
  {
    lastPc = vrEmu6502GetPC(cpu6502);
  }

  uint16_t pc = vrEmu6502GetPC(cpu6502);
  fgColor = white;

  debuggerOutput("Disassembly", 0, disassemblyVpos - 1);

  fgColor = red;

  for (int i = 0; i < 30; ++i)
  {
    if (pc < 0x20)
    {
      continue;
    }

    if (labelMap[pc])
    {
      int oldFgColor = fgColor;
      if (i != 0) fgColor = blue;
      debuggerOutput(labelMap[pc], 0, i + disassemblyVpos);
      fgColor = oldFgColor;
      ++i;
    }

    int xPos = 1;

    uint8_t opcode = hbc56MemRead(pc, true);
    debuggerOutput("$", xPos, i + disassemblyVpos); xPos += 1;
    debuggerOutputHex16(pc, xPos, i + disassemblyVpos); xPos += 5;

    uint16_t refAddr = 0;
    char instructionBuffer[32];

    pc = vrEmu6502DisassembleInstruction(cpu6502, pc, sizeof(instructionBuffer), instructionBuffer, &refAddr, labelMap);

    debuggerOutput(instructionBuffer, xPos, i + disassemblyVpos);
    xPos += (int)strnlen(instructionBuffer, sizeof(instructionBuffer));

    if (refAddr && (mouseCharY == (i + disassemblyVpos)))
    {
      if (mouseCharX >= 10 && mouseCharX <= xPos)
      {
        int yPos = mouseCharY - 2;
        bgColor = 0xffffff00;
        fgColor = 0x00000000;
        uint8_t value = hbc56MemRead(refAddr, true);

        int labelWidth = 0;
        if (labelMap[refAddr]) labelWidth = (int)SDL_strlen(labelMap[refAddr]) + 2;
        int valueDecWidth = value < 10 ? 1 : (value < 100 ? 2 : 3);

        int boxWidthChars = (labelWidth + valueDecWidth) + 13;
        xPos = mouseCharX - (boxWidthChars/2);
        if (xPos < 1) xPos = 1;
        if (xPos + boxWidthChars > 50) xPos = 50 - boxWidthChars;

        debuggerOutputRect(xPos * DEBUGGER_CHAR_W - 4, yPos * DEBUGGER_CHAR_H - 4, boxWidthChars * DEBUGGER_CHAR_W + 8, DEBUGGER_CHAR_H + 8);

        xPos += 1;

        if (labelWidth)
        {
          debuggerOutput(labelMap[refAddr], xPos, yPos); xPos += labelWidth - 2;
          debuggerOutput(": ", xPos, yPos); xPos += 2;
        }

        debuggerOutput("$", xPos, yPos); xPos += 1;
        debuggerOutputHex16(refAddr, xPos, yPos); xPos += 4;
        debuggerOutput(": $", xPos, yPos); xPos += 3;
        debuggerOutputHex(value, xPos, yPos); xPos += 2;
        debuggerOutput(" ", xPos, yPos); xPos += 1;
        debuggerOutput(SDL_itoa(value, buffer, 10), xPos, yPos); xPos += valueDecWidth;

        bgColor = 0x00000000;

        int mouseX, mouseY;
        int buttons = SDL_GetMouseState(&mouseX, &mouseY);
        if (buttons & SDL_BUTTON(1)) {
          highlightAddr = refAddr;
          debugMemoryAddr = highlightAddr & 0xffc0;
        }

      }
    }
    fgColor = green;
  }

  /* stack */
  fgColor = white;
  debuggerOutput("Stack", 40, disassemblyVpos - 1);
  fgColor = green;
  uint8_t sp = vrEmu6502GetStackPointer(cpu6502) + 1;
  int y = 0;
  while (sp != 0)
  {
    uint8_t d = hbc56MemRead(0x100 + sp, true);
    debuggerOutput("$1   $", 40, y + disassemblyVpos);
    debuggerOutputHex(sp, 42, y + disassemblyVpos);
    debuggerOutputHex(d, 46, y + disassemblyVpos);
    debuggerOutput(SDL_itoa(d, buffer, 10), 49, y + disassemblyVpos);
    ++sp;
    ++y;
  }

  int memoryVpos = disassemblyVpos + 33;
  fgColor = white;
  debuggerOutput("Memory", 0, memoryVpos - 1);
  fgColor = green;

  uint16_t addr = debugMemoryAddr;
  for (uint8_t y = 0; y < 32; ++y)
  {
    debuggerOutput("$", 0, y + memoryVpos);
    debuggerOutputHex16(addr, 1, y + memoryVpos);

    for (uint8_t x = 0; x< 8; ++x)
    {
      uint8_t d = hbc56MemRead(addr, true);

      if (addr == highlightAddr) { fgColor = yellow; }

      debuggerOutputHex(d, 7 + x * 3, y + memoryVpos);
      debuggerOutputChar(d, 32 + x, y + memoryVpos);

      fgColor = green;

      ++addr;
    } 
  }

  if (tms9918)
  {
    memoryVpos += 34;
    fgColor = white;
    debuggerOutput("TMS9918 VRAM", 0, memoryVpos - 1);
    debuggerOutput("Reg", 42, memoryVpos - 1);
    fgColor = green;
    addr = debugTmsMemoryAddr & 0x3fff;
    for (uint8_t y = 0; y < 16; ++y)
    {
      debuggerOutput("$", 0, y + memoryVpos);
      debuggerOutputHex16(addr, 1, y + memoryVpos);

      for (uint8_t x = 0; x < 8; ++x)
      {
        uint8_t d = readTms9918Vram(tms9918, addr);
        debuggerOutputHex(d, 7 + x * 3, y + memoryVpos);
        debuggerOutputChar(d, 32 + x, y + memoryVpos);
        ++addr;
      }
    }

    for (uint8_t y = 0; y < 8; ++y)
    {
      uint8_t r = readTms9918Reg(tms9918, y);
      debuggerOutput("R  $", 42, y + memoryVpos);
      debuggerOutput(SDL_itoa(y, buffer, 10), 43, y + memoryVpos);
      debuggerOutputHex(r, 46, y + memoryVpos);
      debuggerOutput(SDL_itoa(r, buffer, 10), 49, y + memoryVpos);
    }

  }
  SDL_UpdateTexture(tex,NULL,debuggerFrameBuffer,DEBUGGER_STRIDE);
}