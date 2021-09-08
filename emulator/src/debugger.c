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
#include "cpu6502.h"

#include <stdlib.h>

#define DEBUGGER_STRIDE (DEBUGGER_WIDTH_PX * DEBUGGER_BPP)

static char debuggerFrameBuffer[DEBUGGER_STRIDE * DEBUGGER_HEIGHT_PX];

static int green = 0x80ff8000;
static int blue =  0x8080ff00;
static int red =   0xff808000;

static int fgColor = 0;
static int bgColor = 0;

extern char console_font_6x8[];

CPU6502Regs *cpuStatus = NULL;

static const char *labelMap[0xffff] = {0};

void debuggerInit(CPU6502Regs* regs, const char* labelMapFilename)
{
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
  debuggerOutput(_itoa(cpuStatus->a,buffer,10),10,1);

  fgColor = green;
  if (xChanged) fgColor = red;
  debuggerOutput("X:  $", 0, 2);
  debuggerOutputHex(cpuStatus->x,5,2);
  debuggerOutput(_itoa(cpuStatus->x,buffer,10),10,2);

  fgColor = green;
  if (yChanged) fgColor = red;
  debuggerOutput("Y:  $", 0, 3);
  debuggerOutputHex(cpuStatus->y,5,3);
  debuggerOutput(_itoa(cpuStatus->y,buffer,10),10,3);

  debuggerOutput("PC: $", 0, 5);
  debuggerOutputHex16(cpuStatus->pc, 5, 5);
  debuggerOutput(_itoa(cpuStatus->pc, buffer, 10), 10, 5);

  fgColor = green;
  if (sChanged) fgColor = red;
  debuggerOutput("SP: $", 0, 6);
  debuggerOutputHex16(cpuStatus->s, 5, 6);
  debuggerOutput(_itoa(cpuStatus->s, buffer, 10), 10, 6);

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
  /*
  regs.p.n ? 'N' : 'N',
    regs.p.v ? 'V' : 'v',
    regs.p.d ? 'D' : 'd',
    regs.p.i ? 'I' : 'i',
    regs.p.z ? 'Z' : 'z',
    regs.p.c ? 'C' : 'c');*/


  int offset = 8;
  uint16_t pc = cpuStatus->pc;

  fgColor = red;

  for (int i = 0; i < 60; ++i)
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
          uint16_t rel = pc + (int8_t)mem_read(pc++) + 1;
          if (labelMap[rel])
          {
            int oldFgColor = fgColor;
            if (i != 0) fgColor = blue;
            debuggerOutput(labelMap[rel], 12, i + offset);
            fgColor = oldFgColor;
          }
          else
          {
            debuggerOutput("$", 12, i + offset);
            debuggerOutputHex16(rel, 13, i + offset);
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

  SDL_UpdateTexture(tex,NULL,debuggerFrameBuffer,DEBUGGER_STRIDE);
}