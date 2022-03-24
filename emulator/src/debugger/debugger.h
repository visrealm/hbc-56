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

#ifndef _HBC56_DEBUGGER_H_
#define _HBC56_DEBUGGER_H_

#include "../devices/device.h"
#include "SDL.h"

struct vrEmu6502_s;
typedef struct vrEmu6502_s VrEmu6502;

void debuggerInit(VrEmu6502 *cpu6502);

void debuggerInitTms(HBC56Device *tms9918);

void debuggerLoadLabels(const char* labelFileContents);
void debuggerLoadSource(const char* rptFileContents);

void debuggerRegistersView(bool* show);
void debuggerStackView(bool* show);
void debuggerDisassemblyView(bool* show);
void debuggerSourceView(bool* show);
void debuggerMemoryView(bool *show);
void debuggerVramMemoryView(bool* show);
void debuggerTmsRegistersView(bool* show);

extern uint16_t debugMemoryAddr;
extern uint16_t debugTmsMemoryAddr;

#endif