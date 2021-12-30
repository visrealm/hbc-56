/*
 * Troy's HBC-56 Emulator - AY-3-8910 device
 *
 * Copyright (c) 2021 Troy Schrapel
 *
 * This code is licensed under the MIT license
 *
 * https://github.com/visrealm/hbc-56/emulator
 *
 */

#define USE_CPU_DEVICE 1
#if USE_CPU_DEVICE

#include "6502_device.h"

#include "cpu6502.h"

#include <stdlib.h>
#include <string.h>

static void reset6502CpuDevice(HBC56Device*);
static void destroy6502CpuDevice(HBC56Device*);
static void tick6502CpuDevice(HBC56Device*,uint32_t,double);

#define CPU_6502_MAX_CALL_STACK   128
#define CPU_6502_JSR              0x20
#define CPU_6502_RTS              0x60

struct CPU6502Device
{
  HBC56CpuState        currentState;
  HBC56InterruptSignal intSignal;
  HBC56InterruptSignal nmiSignal;
  uint16_t             callStack[CPU_6502_MAX_CALL_STACK];
  size_t               callStackPtr;
  uint8_t              breakMode;  /* 0 for match, 1 for not match */
  uint16_t             breakAddr;
};
typedef struct CPU6502Device CPU6502Device;

 /* Function:  create6502CpuDevice
  * --------------------
 * create an AY-3-8910 PSG device
  */
HBC56Device create6502CpuDevice()
{
  HBC56Device device = createDevice("6502 CPU");
  CPU6502Device* cpuDevice = (CPU6502Device*)malloc(sizeof(CPU6502Device));
  if (cpuDevice)
  {
    cpuDevice->currentState = CPU_RUNNING;
    cpuDevice->intSignal = INTERRUPT_RELEASE;
    cpuDevice->nmiSignal = INTERRUPT_RELEASE;
    cpuDevice->callStackPtr = 0;
    cpuDevice->breakMode = 0;
    cpuDevice->breakAddr = 0;
    device.data = cpuDevice;

    device.resetFn = &reset6502CpuDevice;
    device.destroyFn = &destroy6502CpuDevice;
    device.tickFn = &tick6502CpuDevice;
  }
  else
  {
    destroyDevice(&device);
  }

  return device;
}


/* Function:  get6502CpuDevice
 * --------------------
 * helper funtion to get private structure
 */
inline static CPU6502Device* get6502CpuDevice(HBC56Device* device)
{
  if (!device) return NULL;
  return (CPU6502Device*)device->data;
}

static void reset6502CpuDevice(HBC56Device* device)
{
  cpu6502_rst();
}

static void destroy6502CpuDevice(HBC56Device *device)
{
  CPU6502Device * cpuDevice = get6502CpuDevice(device);
  if (cpuDevice)
  {
  }
  free(cpuDevice);
  device->data = NULL;
}

static inline void checkInterrupt(HBC56InterruptSignal *status, void (*intCallback)(void))
{
  if (*status == INTERRUPT_RAISE || *status == INTERRUPT_TRIGGER)
  {
    intCallback();
    if (*status == INTERRUPT_TRIGGER) *status = INTERRUPT_RELEASE;
  }
}

static void tick6502CpuDevice(HBC56Device* device, uint32_t deltaTicks, double deltaTime)
{
  CPU6502Device* cpuDevice = get6502CpuDevice(device);
  if (cpuDevice)
  {
    while (deltaTicks--)
    {
      /* currently, we disable interrupts while debugging since the tms9918
         will constantly trigger interrupts which don't allow debugging user code. 
         this will become an option */
      if (cpuDevice->currentState == CPU_RUNNING)
      {
        checkInterrupt(&cpuDevice->nmiSignal, &cpu6502_nmi);
        checkInterrupt(&cpuDevice->intSignal, &cpu6502_irq);
      }

      int doTick = 1;

      if (cpuDevice->breakMode != (cpuDevice->breakAddr == cpu6502_get_regs()->pc)) doTick = 0;
      if (cpuDevice->currentState == CPU_BREAK) doTick = 0;

      if (doTick)
      {
        cpu6502_clock_tick();

        if (cpu6502_get_regs()->ts == 0) /* end of the instruction */
        {
          uint8_t opcode = mem_read(cpu6502_get_regs()->pc);
          int isJsr = (opcode == CPU_6502_JSR);
          int isRts = (opcode == CPU_6502_RTS);
          if (isJsr)
          {
            cpuDevice->callStack[cpuDevice->callStackPtr++] = cpu6502_get_regs()->pc;
          }
          else if (isRts && cpuDevice->callStackPtr)
          {
            --cpuDevice->callStackPtr;
          }
        }
      }
    }
  }
} 

void interrupt6502(HBC56Device* device, HBC56InterruptType type, HBC56InterruptSignal signal)
{
  CPU6502Device* cpuDevice = get6502CpuDevice(device);
  if (cpuDevice)
  {
    switch (type)
    {
      case INTERRUPT_INT:
        cpuDevice->intSignal = signal;
        break;

      case INTERRUPT_NMI:
        cpuDevice->nmiSignal = signal;
        break;
    }
  }
}

void debug6502State(HBC56Device* device, HBC56CpuState state)
{
  CPU6502Device* cpuDevice = get6502CpuDevice(device);
  if (cpuDevice)
  {
    uint8_t opcode = mem_read(cpu6502_get_regs()->pc);
    int isJsr = (opcode == CPU_6502_JSR);

    switch (state)
    {
      case CPU_STEP_OUT:
      {
        if (cpuDevice->currentState == CPU_RUNNING) { state = cpuDevice->currentState; break; }
        if (cpuDevice->callStackPtr > 1)
        {
          cpuDevice->breakMode = 0;
          cpuDevice->breakAddr = cpuDevice->callStack[cpuDevice->callStackPtr - 1] + 3;
          break;
        }
      }

      case CPU_STEP_OVER:
      {
        if (cpuDevice->currentState == CPU_RUNNING) { state = cpuDevice->currentState; break; }
        if (isJsr)
        {
          cpuDevice->breakMode = 0;
          cpuDevice->breakAddr = cpu6502_get_regs()->pc + 3;
          break;
        }
      }

      case CPU_STEP_INTO:
      {
        if (cpuDevice->currentState == CPU_RUNNING) { state = cpuDevice->currentState; break; }
        cpuDevice->breakMode = 1;
        cpuDevice->breakAddr = cpu6502_get_regs()->pc;
        break;
      }

      case CPU_RUNNING:
      {
        cpuDevice->breakMode = 0;
        cpuDevice->breakAddr = 0;
        break;
      }

      case CPU_BREAK:
        break;
    }
    cpuDevice->currentState = state;
  }
}

HBC56CpuState getDebug6502State(HBC56Device* device)
{
  CPU6502Device* cpuDevice = get6502CpuDevice(device);
  if (cpuDevice)
  {
    return cpuDevice->currentState;
  }
  return CPU_BREAK;
}


#endif