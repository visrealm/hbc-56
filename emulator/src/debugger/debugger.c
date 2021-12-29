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
extern uint8_t mem_read_dbg(uint16_t addr);

uint16_t debugMemoryAddr = 0;
uint16_t debugTmsMemoryAddr = 0;

CPU6502Regs *cpuStatus = NULL;

static const char *labelMap[0x10000] = {0};
static HBC56Device* tms9918 = NULL;

char tmpBuffer[256] = {0};

int isProbablyConstant(const char* str)
{
  SDL_strlcpy(tmpBuffer, str, sizeof(tmpBuffer) - 1);
  SDL_strupr(tmpBuffer);
  return SDL_strcmp(str, tmpBuffer) == 0;
}

void debuggerInit(CPU6502Regs* regs, const char* labelMapFilename)
{
  cpuStatus = regs;
  fgColor = green;
  bgColor = 0x00000000;

  FILE* ptr = NULL;
#ifdef _EMSCRIPTEN
  ptr = fopen(labelMapFilename, "r");
#else
  fopen_s(&ptr, labelMapFilename, "r");
#endif
  if (ptr)
  {
    char lineBuffer[FILENAME_MAX];

    while (fgets(lineBuffer, sizeof(lineBuffer), ptr))
    {
      size_t labelStart = -1, labelEnd = -1, valueStart = -1, valueEnd = -1;

      int i = 0;
      for (i = 0; i < FILENAME_MAX; ++i)
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

    fclose(ptr);
  }
}

void debuggerInitTms(HBC56Device* tms)
{
  tms9918 = tms;
}


char hexDigit(char val)
{
  if (val < 10)
    return val + '0';
  return (val - 10) + 'A';
}

void debuggerOutputChar(char c,int x,int y)
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

void debuggerOutputRect(int x, int y, int w, int h) {
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


void debuggerOutputHex(char c,int x,int y)
{
  debuggerOutputChar(hexDigit((c & 0xf0) >> 4),x,y);
  debuggerOutputChar(hexDigit(c & 0x0f),x + 1,y);
}

void debuggerOutputHex16(unsigned short w,int x,int y)
{
  debuggerOutputHex((w & 0xff00) >> 8,x,y);
  debuggerOutputHex(w & 0x00ff,x + 2,y);
}

void debuggerOutput(const char* str,int x,int y)
{
  const char *p = str;

  while (*p != 0)
  {
    debuggerOutputChar(*(p++),x++,y);
  }
}
enum
{
  imp,
  indx,
  zp,
  acc,
  abso,
  absx,
  rel,
  indy,
  imm,
  zpx,
  zpy,
  absy,
  ind
};

static int addrtable[256] = {
/* 0  |  1  |  2  |  3  |  4  |  5  |  6  |  7  |  8  |  9  |  A  |  B  |  C  |  D  |  E  |  F  |      */
   imp, indx,  imp, indx,   zp,   zp,   zp,   zp,  imp,  imm,  acc,  imm, abso, abso, abso, abso, /* 0 */
   rel, indy,  imp, indy,  zpx,  zpx,  zpx,  zpx,  imp, absy,  imp, absy, absx, absx, absx, absx, /* 1 */
  abso, indx,  imp, indx,   zp,   zp,   zp,   zp,  imp,  imm,  acc,  imm, abso, abso, abso, abso, /* 2 */
   rel, indy,  imp, indy,  zpx,  zpx,  zpx,  zpx,  imp, absy,  imp, absy, absx, absx, absx, absx, /* 3 */
   imp, indx,  imp, indx,   zp,   zp,   zp,   zp,  imp,  imm,  acc,  imm, abso, abso, abso, abso, /* 4 */
   rel, indy,  imp, indy,  zpx,  zpx,  zpx,  zpx,  imp, absy,  imp, absy, absx, absx, absx, absx, /* 5 */
   imp, indx,  imp, indx,   zp,   zp,   zp,   zp,  imp,  imm,  acc,  imm,  ind, abso, abso, abso, /* 6 */
   rel, indy,  imp, indy,  zpx,  zpx,  zpx,  zpx,  imp, absy,  imp, absy, absx, absx, absx, absx, /* 7 */
   imm, indx,  imm, indx,   zp,   zp,   zp,   zp,  imp,  imm,  imp,  imm, abso, abso, abso, abso, /* 8 */
   rel, indy,  imp, indy,  zpx,  zpx,  zpy,  zpy,  imp, absy,  imp, absy, absx, absx, absy, absy, /* 9 */
   imm, indx,  imm, indx,   zp,   zp,   zp,   zp,  imp,  imm,  imp,  imm, abso, abso, abso, abso, /* A */
   rel, indy,  imp, indy,  zpx,  zpx,  zpy,  zpy,  imp, absy,  imp, absy, absx, absx, absy, absy, /* B */
   imm, indx,  imm, indx,   zp,   zp,   zp,   zp,  imp,  imm,  imp,  imm, abso, abso, abso, abso, /* C */
   rel, indy,  imp, indy,  zpx,  zpx,  zpx,  zpx,  imp, absy,  imp, absy, absx, absx, absx, absx, /* D */
   imm, indx,  imm, indx,   zp,   zp,   zp,   zp,  imp,  imm,  imp,  imm, abso, abso, abso, abso, /* E */
   rel, indy,  imp, indy,  zpx,  zpx,  zpx,  zpx,  imp, absy,  imp, absy, absx, absx, absx, imp}; /* F */

static char *opcodes[256] = {
/* 0  |  1   |  2   |  3   |  4   |  5   |  6   |  7   |  8   |  9   |  A   |  B   |  C   |  D   |  E   |  F   |      */
 "brk", "ora", "nop", "slo", "nop", "ora", "asl", "slo", "php", "ora", "asl", "nop", "nop", "ora", "asl", "slo", /* 0 */
 "bpl", "ora", "nop", "slo", "nop", "ora", "asl", "slo", "clc", "ora", "nop", "slo", "nop", "ora", "asl", "slo", /* 1 */
 "jsr", "and", "nop", "rla", "bit", "and", "rol", "rla", "plp", "and", "rol", "nop", "bit", "and", "rol", "rla", /* 2 */
 "bmi", "and", "nop", "rla", "nop", "and", "rol", "rla", "sec", "and", "nop", "rla", "nop", "and", "rol", "rla", /* 3 */
 "rti", "eor", "nop", "sre", "nop", "eor", "lsr", "sre", "pha", "eor", "lsr", "nop", "jmp", "eor", "lsr", "sre", /* 4 */
 "bvc", "eor", "nop", "sre", "nop", "eor", "lsr", "sre", "cli", "eor", "nop", "sre", "nop", "eor", "lsr", "sre", /* 5 */
 "rts", "adc", "nop", "rra", "nop", "adc", "ror", "rra", "pla", "adc", "ror", "nop", "jmp", "adc", "ror", "rra", /* 6 */
 "bvs", "adc", "nop", "rra", "nop", "adc", "ror", "rra", "sei", "adc", "nop", "rra", "nop", "adc", "ror", "rra", /* 7 */
 "nop", "sta", "nop", "sax", "sty", "sta", "stx", "sax", "dey", "nop", "txa", "nop", "sty", "sta", "stx", "sax", /* 8 */
 "bcc", "sta", "nop", "nop", "sty", "sta", "stx", "sax", "tya", "sta", "txs", "nop", "nop", "sta", "nop", "nop", /* 9 */
 "ldy", "lda", "ldx", "lax", "ldy", "lda", "ldx", "lax", "tay", "lda", "tax", "nop", "ldy", "lda", "ldx", "lax", /* A */
 "bcs", "lda", "nop", "lax", "ldy", "lda", "ldx", "lax", "clv", "lda", "tsx", "lax", "ldy", "lda", "ldx", "lax", /* B */
 "cpy", "cmp", "nop", "dcp", "cpy", "cmp", "dec", "dcp", "iny", "cmp", "dex", "nop", "cpy", "cmp", "dec", "dcp", /* C */
 "bne", "cmp", "nop", "dcp", "nop", "cmp", "dec", "dcp", "cld", "cmp", "nop", "dcp", "nop", "cmp", "dec", "dcp", /* D */
 "cpx", "sbc", "nop", "isb", "cpx", "sbc", "inc", "isb", "inx", "sbc", "nop", "sbc", "cpx", "sbc", "inc", "isb", /* E */
 "beq", "sbc", "nop", "isb", "nop", "sbc", "inc", "isb", "sed", "sbc", "nop", "isb", "nop", "sbc", "inc", "-" }; /* F */


static const int disassemblyVpos = 6;

#define OUTPUT_HEX_WITH_LABEL 0



int debuggerOutputAddress8(uint16_t *pc, int x, int i, uint16_t* value)
{
  uint8_t addr = mem_read_dbg((*pc)++);

  *value = addr;

  int len = 0;
  int oldFgColor = fgColor;

  if (labelMap[addr])
  {
    int oldFgColor = fgColor;
    if (i != 0 && fgColor != red) fgColor = blue;
    debuggerOutput(labelMap[addr], x, i + disassemblyVpos);
    len += (int)SDL_strlen(labelMap[addr]);
#if OUTPUT_HEX_WITH_LABEL
    if (i != 0) fgColor = dkgreen;
    debuggerOutput(" [", x + len, i + disassemblyVpos);
    len += 2;
  }
#else
  } else {
#endif

    debuggerOutput("$", x + len, i + disassemblyVpos);
    debuggerOutputHex(addr, x + len + 1, i + disassemblyVpos);
    len += 3;
#if OUTPUT_HEX_WITH_LABEL
    if (len > 3)
    {
      debuggerOutput("]", x + len, i + disassemblyVpos); ++len;
      fgColor = oldFgColor;
#endif
    }

  return len;
}

int debuggerOutputAddress16(uint16_t *pc, int x, int i, int rel, uint16_t *value)
{
  uint16_t addr = mem_read_dbg((*pc)++);

  if (rel) 
  {
    addr += *pc;
  }
  else
  {
    addr |= mem_read_dbg((*pc)++) << 8;
  }

  *value = addr;

  int len = 0;
  int oldFgColor = fgColor;

  if (labelMap[addr])
  {
    if (i != 0 && fgColor != red) fgColor = blue;
    debuggerOutput(labelMap[addr], x, i + disassemblyVpos);
    len += (int)SDL_strlen(labelMap[addr]);
#if OUTPUT_HEX_WITH_LABEL
    if (i != 0) fgColor = dkgreen;
    debuggerOutput(" [", x + len, i + disassemblyVpos);
    len += 2;
  }
#else
}
  else {
#endif

    debuggerOutput("$", x + len, i + disassemblyVpos);
    debuggerOutputHex16(addr, x + len + 1, i + disassemblyVpos);
    len += 5;
#if OUTPUT_HEX_WITH_LABEL
    if (len > 5)
    {
      debuggerOutput("]", x + len, i + disassemblyVpos); ++len;
#endif

  }

  return len;
}


void debuggerUpdate(SDL_Texture* tex, int mouseX, int mouseY)
{
  char buffer[10];

  int mouseCharX = mouseX / DEBUGGER_CHAR_W;
  int mouseCharY = mouseY / DEBUGGER_CHAR_H;

  memset(debuggerFrameBuffer, 0, sizeof(debuggerFrameBuffer));

  static CPU6502Regs prevRegs;
  static CPU6502Regs lastRegs;
  static uint16_t lastPc;

  static uint16_t highlightAddr = 0;

  fgColor = green;
  if (lastRegs.a != cpuStatus->a) fgColor = red;
  debuggerOutput("A:  $", 0, 1);
  debuggerOutputHex(cpuStatus->a,5,1);
  debuggerOutput(SDL_itoa(cpuStatus->a,buffer,10),10,1);

  fgColor = green;
  if (lastRegs.x != cpuStatus->x) fgColor = red;
  debuggerOutput("X:  $", 0, 2);
  debuggerOutputHex(cpuStatus->x,5,2);
  debuggerOutput(SDL_itoa(cpuStatus->x,buffer,10),10,2);

  fgColor = green;
  if (lastRegs.y != cpuStatus->y) fgColor = red;
  debuggerOutput("Y:  $", 0, 3);
  debuggerOutputHex(cpuStatus->y,5,3);
  debuggerOutput(SDL_itoa(cpuStatus->y,buffer,10),10,3);

  debuggerOutput("PC: $", 20, 1);
  debuggerOutputHex16(cpuStatus->pc, 25, 1);
  debuggerOutput(SDL_itoa(cpuStatus->pc, buffer, 10), 30, 1);

  fgColor = green;
  if (lastRegs.s != cpuStatus->s) fgColor = red;
  debuggerOutput("SP: $1", 20, 2);
  debuggerOutputHex(cpuStatus->s, 26, 2);
  debuggerOutput(SDL_itoa(cpuStatus->s, buffer, 10), 30, 2);

  fgColor = green;
  debuggerOutput("F:", 20, 3);

  fgColor = cpuStatus->p.n ? (lastRegs.p.n == cpuStatus->p.n ? green : red) : dkgreen;
  debuggerOutputChar(cpuStatus->p.n ? 'N' : 'n', 24, 3);
  fgColor = cpuStatus->p.v ? (lastRegs.p.v == cpuStatus->p.v ? green : red) : dkgreen;
  debuggerOutputChar(cpuStatus->p.v ? 'V' : 'v', 25, 3);
  fgColor = cpuStatus->p.d ? (lastRegs.p.d == cpuStatus->p.d ? green : red) : dkgreen;
  debuggerOutputChar(cpuStatus->p.d ? 'D' : 'd', 26, 3);
  fgColor = cpuStatus->p.i ? (lastRegs.p.i == cpuStatus->p.i ? green : red) : dkgreen;
  debuggerOutputChar(cpuStatus->p.i ? 'I' : 'i', 27, 3);
  fgColor = cpuStatus->p.z ? (lastRegs.p.z == cpuStatus->p.z ? green : red) : dkgreen;
  debuggerOutputChar(cpuStatus->p.z ? 'Z' : 'z', 28, 3);
  fgColor = cpuStatus->p.c ? (lastRegs.p.c == cpuStatus->p.c ? green : red) : dkgreen;
  debuggerOutputChar(cpuStatus->p.c ? 'C' : 'c', 29, 3);


  fgColor = green;

  if (lastPc != cpuStatus->pc)
  {
    lastPc = cpuStatus->pc;
    lastRegs = prevRegs;
    prevRegs = *cpuStatus;
  }

  uint16_t pc = cpuStatus->pc;
  fgColor = white;

  debuggerOutput("Disassembly", 0, disassemblyVpos - 1);

  fgColor = red;

  for (int i = 0; i < 30; ++i)
  {
    if (pc < 0x200)
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

    uint8_t opcode = mem_read_dbg(pc);
    debuggerOutput("$", xPos, i + disassemblyVpos); xPos += 1;
    debuggerOutputHex16(pc, xPos, i + disassemblyVpos); xPos += 5;
    debuggerOutput(opcodes[opcode], xPos, i + disassemblyVpos);
    xPos += (int)SDL_strlen(opcodes[opcode]) + 1;

    ++pc;
    uint16_t refAddr = 0;
    int skipValue = 0;
    switch (addrtable[opcode])
    {
      case imp:
        skipValue = 1;
        break;
      case indx:
        debuggerOutput("(", xPos, i + disassemblyVpos); xPos += 1;
        xPos += debuggerOutputAddress8(&pc, xPos, i, &refAddr);
        debuggerOutput(",X)", xPos, i + disassemblyVpos); xPos += 3;
        break;
      case zp:
        xPos += debuggerOutputAddress8(&pc, xPos, i, &refAddr);
        break;
      case acc:
        skipValue = 1;
        break;
      case abso:
        xPos += debuggerOutputAddress16(&pc, xPos, i, 0, &refAddr);
        break;
      case absx:
        xPos += debuggerOutputAddress16(&pc, xPos, i, 0, &refAddr);
        debuggerOutput(",X", xPos, i + disassemblyVpos); xPos += 2;
        break;
      case rel:
        xPos += debuggerOutputAddress16(&pc, xPos, i, 1, &refAddr);
        break;
      case indy:
        debuggerOutput("(", xPos, i + disassemblyVpos); xPos += 1;
        xPos += debuggerOutputAddress8(&pc, xPos, i, &refAddr);
        debuggerOutput("),Y", xPos, i + disassemblyVpos); xPos += 3;
        break;
      case imm:
        debuggerOutput("#$", xPos, i + disassemblyVpos); xPos += 2;
        debuggerOutputHex(mem_read_dbg(pc++), xPos, i + disassemblyVpos); xPos += 2;
        skipValue = 1;
        break;
      case zpx:
        xPos += debuggerOutputAddress8(&pc, xPos, i, &refAddr);
        debuggerOutput(",X", xPos, i + disassemblyVpos); xPos += 2;
        break;
      case zpy:
        xPos += debuggerOutputAddress8(&pc, xPos, i, &refAddr);
        debuggerOutput(",Y", xPos, i + disassemblyVpos); xPos += 2;
        break;
      case absy:
        xPos += debuggerOutputAddress16(&pc, xPos, i, 0, &refAddr);
        debuggerOutput(",Y", 17, i + disassemblyVpos); xPos += 2;
        break;
      case ind:
        debuggerOutput("(", xPos, i + disassemblyVpos); xPos += 1;
        xPos += debuggerOutputAddress16(&pc, xPos, i, 0, &refAddr);
        debuggerOutput(")", xPos, i + disassemblyVpos); xPos += 1;
        break;
    }

    if (!skipValue && (mouseCharY == (i + disassemblyVpos)))
    {
      if (mouseCharX >= 10 && mouseCharX <= xPos)
      {
        int yPos = mouseCharY - 2;
        bgColor = 0xffffff00;
        fgColor = 0x00000000;
        uint8_t value = mem_read_dbg(refAddr);

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
  uint8_t sp = cpuStatus->s + 1;
  int y = 0;
  while (sp != 0)
  {
    uint8_t d = mem_read_dbg(0x100 + sp);
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
      uint8_t d = mem_read_dbg(addr);

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