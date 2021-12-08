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

#include <stdlib.h>

#define DEBUGGER_STRIDE (DEBUGGER_WIDTH_PX * DEBUGGER_BPP)

static char debuggerFrameBuffer[DEBUGGER_STRIDE * DEBUGGER_HEIGHT_PX];

static int green = 0x80ff8000;
static int dkgreen = 0x807f8000;
static int blue =  0x8080ff00;
static int red = 0xff808000;
static int white = 0xffffff00;
static int yellow = 0xffff0000;

static int fgColor = 0;
static int bgColor = 0;

extern char console_font_6x8[];
uint16_t debugMemoryAddr = 0;
uint16_t debugTmsMemoryAddr = 0;

CPU6502Regs *cpuStatus = NULL;

static const char *labelMap[0x10000] = {0};
static VrEmuTms9918a* tms9918 = NULL;

void debuggerInit(CPU6502Regs* regs, const char* labelMapFilename, VrEmuTms9918a* tms)
{
  tms9918 = tms;
  cpuStatus = regs;
  fgColor = green;
  bgColor = 0x00000000;

  FILE* ptr = NULL;
  fopen_s(&ptr, labelMapFilename, "r");
  if (ptr)
  {
    char lineBuffer[FILENAME_MAX];

    while (fgets(lineBuffer, sizeof(lineBuffer), ptr))
    {
      if (SDL_strstr(lineBuffer, "; unused"))
        continue;

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

      //if (!labelMap[addr])
      {
        char* label = malloc((labelEnd - labelStart) + 1);
        SDL_strlcpy(label, lineBuffer + labelStart, labelEnd - labelStart + 1);
        labelMap[addr] = label;
      }
    }

    fclose(ptr);
  }


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
  /*        |  0  |  1  |  2  |  3  |  4  |  5  |  6  |  7  |  8  |  9  |  A  |  B  |  C  |  D  |  E  |  F  |     */
  /* 0 */     imp, indx,  imp, indx,   zp,   zp,   zp,   zp,  imp,  imm,  acc,  imm, abso, abso, abso, abso, /* 0 */
  /* 1 */     rel, indy,  imp, indy,  zpx,  zpx,  zpx,  zpx,  imp, absy,  imp, absy, absx, absx, absx, absx, /* 1 */
  /* 2 */    abso, indx,  imp, indx,   zp,   zp,   zp,   zp,  imp,  imm,  acc,  imm, abso, abso, abso, abso, /* 2 */
  /* 3 */     rel, indy,  imp, indy,  zpx,  zpx,  zpx,  zpx,  imp, absy,  imp, absy, absx, absx, absx, absx, /* 3 */
  /* 4 */     imp, indx,  imp, indx,   zp,   zp,   zp,   zp,  imp,  imm,  acc,  imm, abso, abso, abso, abso, /* 4 */
  /* 5 */     rel, indy,  imp, indy,  zpx,  zpx,  zpx,  zpx,  imp, absy,  imp, absy, absx, absx, absx, absx, /* 5 */
  /* 6 */     imp, indx,  imp, indx,   zp,   zp,   zp,   zp,  imp,  imm,  acc,  imm,  ind, abso, abso, abso, /* 6 */
  /* 7 */     rel, indy,  imp, indy,  zpx,  zpx,  zpx,  zpx,  imp, absy,  imp, absy, absx, absx, absx, absx, /* 7 */
  /* 8 */     imm, indx,  imm, indx,   zp,   zp,   zp,   zp,  imp,  imm,  imp,  imm, abso, abso, abso, abso, /* 8 */
  /* 9 */     rel, indy,  imp, indy,  zpx,  zpx,  zpy,  zpy,  imp, absy,  imp, absy, absx, absx, absy, absy, /* 9 */
  /* A */     imm, indx,  imm, indx,   zp,   zp,   zp,   zp,  imp,  imm,  imp,  imm, abso, abso, abso, abso, /* A */
  /* B */     rel, indy,  imp, indy,  zpx,  zpx,  zpy,  zpy,  imp, absy,  imp, absy, absx, absx, absy, absy, /* B */
  /* C */     imm, indx,  imm, indx,   zp,   zp,   zp,   zp,  imp,  imm,  imp,  imm, abso, abso, abso, abso, /* C */
  /* D */     rel, indy,  imp, indy,  zpx,  zpx,  zpx,  zpx,  imp, absy,  imp, absy, absx, absx, absx, absx, /* D */
  /* E */     imm, indx,  imm, indx,   zp,   zp,   zp,   zp,  imp,  imm,  imp,  imm, abso, abso, abso, abso, /* E */
  /* F */     rel, indy,  imp, indy,  zpx,  zpx,  zpx,  zpx,  imp, absy,  imp, absy, absx, absx, absx, absx  /* F */ };

static char *opcodes[256] = {
  /*           |  0  |  1   |  2   |  3   |  4   |  5   |  6   |  7   |  8   |  9   |  A   |  B   |  C   |  D   |  E   |  F  |      */
  /* 0 */      "brk", "ora", "nop", "slo", "nop", "ora", "asl", "slo", "php", "ora", "asl", "nop", "nop", "ora", "asl", "slo", /* 0 */
  /* 1 */      "bpl", "ora", "nop", "slo", "nop", "ora", "asl", "slo", "clc", "ora", "nop", "slo", "nop", "ora", "asl", "slo", /* 1 */
  /* 2 */      "jsr", "and", "nop", "rla", "bit", "and", "rol", "rla", "plp", "and", "rol", "nop", "bit", "and", "rol", "rla", /* 2 */
  /* 3 */      "bmi", "and", "nop", "rla", "nop", "and", "rol", "rla", "sec", "and", "nop", "rla", "nop", "and", "rol", "rla", /* 3 */
  /* 4 */      "rti", "eor", "nop", "sre", "nop", "eor", "lsr", "sre", "pha", "eor", "lsr", "nop", "jmp", "eor", "lsr", "sre", /* 4 */
  /* 5 */      "bvc", "eor", "nop", "sre", "nop", "eor", "lsr", "sre", "cli", "eor", "nop", "sre", "nop", "eor", "lsr", "sre", /* 5 */
  /* 6 */      "rts", "adc", "nop", "rra", "nop", "adc", "ror", "rra", "pla", "adc", "ror", "nop", "jmp", "adc", "ror", "rra", /* 6 */
  /* 7 */      "bvs", "adc", "nop", "rra", "nop", "adc", "ror", "rra", "sei", "adc", "nop", "rra", "nop", "adc", "ror", "rra", /* 7 */
  /* 8 */      "nop", "sta", "nop", "sax", "sty", "sta", "stx", "sax", "dey", "nop", "txa", "nop", "sty", "sta", "stx", "sax", /* 8 */
  /* 9 */      "bcc", "sta", "nop", "nop", "sty", "sta", "stx", "sax", "tya", "sta", "txs", "nop", "nop", "sta", "nop", "nop", /* 9 */
  /* A */      "ldy", "lda", "ldx", "lax", "ldy", "lda", "ldx", "lax", "tay", "lda", "tax", "nop", "ldy", "lda", "ldx", "lax", /* A */
  /* B */      "bcs", "lda", "nop", "lax", "ldy", "lda", "ldx", "lax", "clv", "lda", "tsx", "lax", "ldy", "lda", "ldx", "lax", /* B */
  /* C */      "cpy", "cmp", "nop", "dcp", "cpy", "cmp", "dec", "dcp", "iny", "cmp", "dex", "nop", "cpy", "cmp", "dec", "dcp", /* C */
  /* D */      "bne", "cmp", "nop", "dcp", "nop", "cmp", "dec", "dcp", "cld", "cmp", "nop", "dcp", "nop", "cmp", "dec", "dcp", /* D */
  /* E */      "cpx", "sbc", "nop", "isb", "cpx", "sbc", "inc", "isb", "inx", "sbc", "nop", "sbc", "cpx", "sbc", "inc", "isb", /* E */
  /* F */      "beq", "sbc", "nop", "isb", "nop", "sbc", "inc", "isb", "sed", "sbc", "nop", "isb", "nop", "sbc", "inc", "isb"  /* F */ };

void debuggerUpdate(SDL_Texture* tex)
{
  char buffer[10];

  memset(debuggerFrameBuffer, 0, sizeof(debuggerFrameBuffer));

  static uint8_t lastA = 0;
  static uint8_t lastX = 0;
  static uint8_t lastY = 0;
  static uint8_t lastS = 0;
  static uint8_t lastF = 0;

  static int aChanged = 0;
  static int xChanged = 0;
  static int yChanged = 0;
  static int sChanged = 0;
  static int fChanged = 0;

  static uint16_t lastPC = 0;

  fgColor = green;
  if (aChanged) fgColor = red;
  debuggerOutput("A:  $", 0, 1);
  debuggerOutputHex(cpuStatus->a,5,1);
  debuggerOutput(SDL_itoa(cpuStatus->a,buffer,10),10,1);

  fgColor = green;
  if (xChanged) fgColor = red;
  debuggerOutput("X:  $", 0, 2);
  debuggerOutputHex(cpuStatus->x,5,2);
  debuggerOutput(SDL_itoa(cpuStatus->x,buffer,10),10,2);

  fgColor = green;
  if (yChanged) fgColor = red;
  debuggerOutput("Y:  $", 0, 3);
  debuggerOutputHex(cpuStatus->y,5,3);
  debuggerOutput(SDL_itoa(cpuStatus->y,buffer,10),10,3);

  debuggerOutput("PC: $", 20, 1);
  debuggerOutputHex16(cpuStatus->pc, 25, 1);
  debuggerOutput(SDL_itoa(cpuStatus->pc, buffer, 10), 30, 1);

  fgColor = green;
  if (sChanged) fgColor = red;
  debuggerOutput("SP: $1", 20, 2);
  debuggerOutputHex(cpuStatus->s, 26, 2);
  debuggerOutput(SDL_itoa(cpuStatus->s, buffer, 10), 30, 2);

  debuggerOutput("F:", 20, 3);

  fgColor = cpuStatus->p.n ? green : dkgreen;
  debuggerOutputChar(cpuStatus->p.n ? 'N' : 'n', 24, 3);
  fgColor = cpuStatus->p.v ? green : dkgreen;
  debuggerOutputChar(cpuStatus->p.v ? 'V' : 'v', 25, 3);
  fgColor = cpuStatus->p.d ? green : dkgreen;
  debuggerOutputChar(cpuStatus->p.d ? 'D' : 'd', 26, 3);
  fgColor = cpuStatus->p.i ? green : dkgreen;
  debuggerOutputChar(cpuStatus->p.i ? 'I' : 'i', 27, 3);
  fgColor = cpuStatus->p.z ? green : dkgreen;
  debuggerOutputChar(cpuStatus->p.z ? 'Z' : 'z', 28, 3);
  fgColor = cpuStatus->p.c ? green : dkgreen;
  debuggerOutputChar(cpuStatus->p.c ? 'C' : 'c', 29, 3);


  fgColor = green;

  if (lastPC != cpuStatus->pc)
  {
    aChanged = (lastA != cpuStatus->a);
    xChanged = (lastX != cpuStatus->x);
    yChanged = (lastY != cpuStatus->y);
    sChanged = (lastS != cpuStatus->s);
    fChanged = (lastF != cpuStatus->p_);

    lastA = cpuStatus->a;
    lastX = cpuStatus->x;
    lastY = cpuStatus->y;
    lastS = cpuStatus->s;
    lastF = cpuStatus->p_;
    lastPC = cpuStatus->pc;
  }

  int offset = 6;
  uint16_t pc = cpuStatus->pc;
  fgColor = white;

  debuggerOutput("Disassembly", 0, offset - 1);

  fgColor = red;

  for (int i = 0; i < 30; ++i)
  {
    if (labelMap[pc])
    {
      int oldFgColor = fgColor;
      if (i != 0) fgColor = blue;
      debuggerOutput(labelMap[pc], 0, i + offset);
      fgColor = oldFgColor;
      ++i;
    }

    uint8_t opcode = mem_read(pc);
    debuggerOutput("$", 2, i + offset);
    debuggerOutputHex16(pc, 3, i + offset);
    debuggerOutput(opcodes[opcode], 8, i + offset);
    //debuggerOutputHex(opcode, 16, i + offset);

    ++pc;

    switch (addrtable[opcode])
    {
      case imp:
        break;
      case indx:
        debuggerOutput("($", 12, i + offset);
        debuggerOutputHex(mem_read(pc++), 14, i + offset);
        debuggerOutput(",X)", 18, i + offset);
        break;
      case zp:
        debuggerOutput("$", 12, i + offset);
        debuggerOutputHex(mem_read(pc++), 13, i + offset);
        break;
      case acc:
        break;
      case abso:
        {
          uint16_t addr = mem_read(pc++);
          addr |= mem_read(pc++) << 8;
          if (labelMap[addr])
          {
            int oldFgColor = fgColor;
            if (i != 0) fgColor = blue;
            debuggerOutput(labelMap[addr], 12, i + offset);
            fgColor = oldFgColor;
          }
          else
          {
            debuggerOutput("$", 12, i + offset);
            debuggerOutputHex16(addr, 13, i + offset);
          }
        }
        break;
      case absx:
        debuggerOutput("$", 12,i + offset);
        debuggerOutputHex(mem_read(pc++), 15, i + offset);
        debuggerOutputHex(mem_read(pc++), 13, i + offset);
        debuggerOutput(",X", 17, i + offset);
        break;
      case rel:
        {
          int8_t rel = (int8_t)mem_read(pc++);
          uint16_t addr = pc + rel;
          if (labelMap[addr])
          {
            int oldFgColor = fgColor;
            if (i != 0) fgColor = blue;
            debuggerOutput(labelMap[addr], 12, i + offset);
            fgColor = oldFgColor;
          }
          else
          {
            debuggerOutput("$", 12, i + offset);
            debuggerOutputHex16(addr, 13, i + offset);
          }
        }
        break;
      case indy:
        debuggerOutput("($", 12, i + offset);
        debuggerOutputHex(mem_read(pc++), 14, i + offset);
        debuggerOutput("),Y", 16, i + offset);
        break;
      case imm:
        debuggerOutput("#$", 12, i + offset);
        debuggerOutputHex(mem_read(pc++), 14, i + offset);
        break;
      case zpx:
        debuggerOutput("$", 12, i + offset);
        debuggerOutputHex(mem_read(pc++), 13, i + offset);
        debuggerOutput(",X", 15, i + offset);
        break;
      case zpy:
        debuggerOutput("$", 12, i + offset);
        debuggerOutputHex(mem_read(pc++), 13, i + offset);
        debuggerOutput(",Y", 15, i + offset);
        break;
      case absy:
        debuggerOutput("$", 12, i + offset);
        debuggerOutputHex(mem_read(pc++), 15, i + offset);
        debuggerOutputHex(mem_read(pc++), 13, i + offset);
        debuggerOutput(",Y", 17, i + offset);
        break;
      case ind:
        debuggerOutput("($", 12, i + offset);
        debuggerOutputHex(mem_read(pc++), 16, i + offset);
        debuggerOutputHex(mem_read(pc++), 14, i + offset);
        debuggerOutput(")", 16, i + offset);
        break;
    }

    fgColor = green;

  }

  /* stack */
  fgColor = white;
  debuggerOutput("Stack", 40, offset - 1);
  fgColor = green;
  uint8_t sp = cpuStatus->s + 1;
  int y = 0;
  while (sp != 0)
  {
    uint8_t d = mem_read(0x100 + sp);
    debuggerOutput("$1   $", 40, y + offset);
    debuggerOutputHex(sp, 42, y + offset);
    debuggerOutputHex(d, 46, y + offset);
    debuggerOutput(SDL_itoa(d, buffer, 10), 49, y + offset);
    ++sp;
    ++y;
  }

  offset += 33;
  fgColor = white;
  debuggerOutput("Memory", 0, offset - 1);
  fgColor = green;

  uint16_t addr = debugMemoryAddr;
  for (uint8_t y = 0; y < 32; ++y)
  {
    debuggerOutput("$", 0, y + offset);
    debuggerOutputHex16(addr, 1, y + offset);

    for (uint8_t x = 0; x< 8; ++x)
    {
      uint8_t d = mem_read(addr);
      debuggerOutputHex(d, 7 + x * 3, y + offset);
      debuggerOutputChar(d, 32 + x, y + offset);
      ++addr;
    } 
  }

  if (tms9918)
  {
    offset += 34;
    fgColor = white;
    debuggerOutput("TMS9918 VRAM", 0, offset - 1);
    debuggerOutput("Reg", 42, offset - 1);
    fgColor = green;
    addr = debugTmsMemoryAddr & 0x3fff;
    for (uint8_t y = 0; y < 16; ++y)
    {
      debuggerOutput("$", 0, y + offset);
      debuggerOutputHex16(addr, 1, y + offset);

      for (uint8_t x = 0; x < 8; ++x)
      {
        uint8_t d = vrEmuTms9918aVramValue(tms9918, addr);
        debuggerOutputHex(d, 7 + x * 3, y + offset);
        debuggerOutputChar(d, 32 + x, y + offset);
        ++addr;
      }
    }

    for (uint8_t y = 0; y < 8; ++y)
    {
      debuggerOutput("R  $", 42, y + offset);
      debuggerOutput(SDL_itoa(y, buffer, 10), 43, y + offset);
      debuggerOutputHex(vrEmuTms9918aRegValue(tms9918, y), 46, y + offset);
      debuggerOutput(SDL_itoa(vrEmuTms9918aRegValue(tms9918, y), buffer, 10), 49, y + offset);
    }

  }
  SDL_UpdateTexture(tex,NULL,debuggerFrameBuffer,DEBUGGER_STRIDE);
}