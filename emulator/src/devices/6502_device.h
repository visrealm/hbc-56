/*
 * Troy's HBC-56 Emulator - 6502 CPU device
 *
 * Copyright (c) 2021 Troy Schrapel
 *
 * This code is licensed under the MIT license
 *
 * https://github.com/visrealm/hbc-56/emulator
 *
 */

#ifndef _HBC56_6502_DEVICE_H_
#define _HBC56_6502_DEVICE_H_

#include "device.h"

#ifdef __cplusplus
extern "C" {
#endif

struct vrEmu6502_s;
typedef struct vrEmu6502_s VrEmu6502;

typedef uint8_t (*IsBreakpointFn)(uint16_t);

typedef enum
{
  CPU_RUNNING,
  CPU_BREAK,
  CPU_STEP_INTO,
  CPU_STEP_OVER,
  CPU_STEP_OUT,
  CPU_BREAK_ON_INTERRUPT
} HBC56CpuState;


/* Function:  create6502CpuDevice
 * --------------------
 * create a 6502 CPU device
 */
HBC56Device create6502CpuDevice(IsBreakpointFn brkCb);

void interrupt6502(HBC56Device* device, HBC56InterruptType type, HBC56InterruptSignal signal);

void debug6502State(HBC56Device* device, HBC56CpuState state);

HBC56CpuState getDebug6502State(HBC56Device* device);

VrEmu6502* getCpuDevice(HBC56Device* device);

float getCpuUtilization(HBC56Device* device);

#ifdef __cplusplus
}
#endif

#endif