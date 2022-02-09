/*
 * Troy's HBC-56 Emulator - UART device
 *
 * Copyright (c) 2021 Troy Schrapel
 *
 * This code is licensed under the MIT license
 *
 * https://github.com/visrealm/hbc-56/emulator
 *
 */

#include "uart_device.h"

#ifdef _WINDOWS

#include "../hbc56emu.h"

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <windows.h>

static void resetUartDevice(HBC56Device*);
static void destroyUartDevice(HBC56Device*);
static void tickUartDevice(HBC56Device*, uint32_t, double);
static uint8_t readUartDevice(HBC56Device*, uint16_t, uint8_t*, uint8_t);
static uint8_t writeUartDevice(HBC56Device*, uint16_t, uint8_t);

/* memory device data */
struct UartDevice
{
  uint32_t addr;
  HANDLE   handle;

  char     comPortDevice[100];
  int      clockFreq;

  uint8_t readBufferBytes;
  uint8_t readBufferBytesRead;

  uint8_t readBuffer[4];

  uint8_t statusRequested;

  uint8_t controlReg;
  uint8_t statusReg;
  uint8_t irq;

  double timeSinceIO;
  
};
typedef struct UartDevice UartDevice;

#define UART_CTL_MASTER_RESET         0b00000011
#define UART_CTL_CLOCK_DIV_16         0b00000001
#define UART_CTL_CLOCK_DIV_64         0b00000010
#define UART_CTL_WORD_7BIT_EPB_2SB    0b00000000
#define UART_CTL_WORD_7BIT_OPB_2SB    0b00000100
#define UART_CTL_WORD_7BIT_EPB_1SB    0b00001000
#define UART_CTL_WORD_7BIT_OPB_1SB    0b00001100
#define UART_CTL_WORD_8BIT_2SB        0b00010000
#define UART_CTL_WORD_8BIT_1SB        0b00010100
#define UART_CTL_WORD_8BIT_EPAR_1SB   0b00011000
#define UART_CTL_WORD_8BIT_OPAR_1SB   0b00011100
#define UART_CTL_RX_INT_ENABLE        0b10000000

#define UART_STATUS_RX_REG_FULL       0b00000001
#define UART_STATUS_TX_REG_EMPTY      0b00000010
#define UART_STATUS_CARRIER_DETECT    0b00000100
#define UART_STATUS_CLEAR_TO_SEND     0b00001000
#define UART_STATUS_FRAMING_ERROR     0b00010000
#define UART_STATUS_RCVR_OVERRUN      0b00100000
#define UART_STATUS_PARITY_ERROR      0b01000000
#define UART_STATUS_IRQ               0b10000000


/* Function:  createUartDevice
 * --------------------
 * create a uart device for the given address
 */
HBC56Device createUartDevice(
  uint32_t addr,
  const char* port,
  int clockRate,
  uint8_t irq)
{
  HBC56Device device = createDevice("UART");
  UartDevice* uartDevice = (UartDevice*)malloc(sizeof(UartDevice));
  if (uartDevice)
  {
    uartDevice->addr = addr;
    uartDevice->clockFreq = clockRate;
    uartDevice->readBufferBytes = 0;
    uartDevice->readBufferBytesRead = 0;
    uartDevice->statusRequested = 0;
    uartDevice->controlReg = 0;
    uartDevice->irq = irq;
    uartDevice->statusReg = UART_STATUS_TX_REG_EMPTY;
    uartDevice->handle = 0;

    snprintf(uartDevice->comPortDevice, sizeof(uartDevice->comPortDevice), "\\\\.\\%s", port);

    device.data = uartDevice;
    device.destroyFn = destroyUartDevice;
    device.resetFn = resetUartDevice;
    device.tickFn = tickUartDevice;
    device.readFn = readUartDevice;
    device.writeFn = writeUartDevice;
  }
  else
  {
    destroyDevice(&device);
  }

  return device;
}

/* Function:  getUartDevice
 * --------------------
 * helper funtion to get private structure
 */
inline static UartDevice* getUartDevice(HBC56Device* device)
{
  if (!device) return NULL;
  return (UartDevice*)device->data;
}

/* Function:  resetUartDevice
 * --------------------
 * destroy/clean up the uart data structure
 */
static void resetUartDevice(HBC56Device* device)
{
  UartDevice* uartDevice = getUartDevice(device);
  if (uartDevice)
  {
    if (uartDevice->handle)
    {
      CloseHandle(uartDevice->handle);
    }
    uartDevice->handle = 0;
    uartDevice->readBufferBytes = 0;
    uartDevice->readBufferBytesRead = 0;
    uartDevice->statusRequested = 0;
    uartDevice->statusReg = UART_STATUS_TX_REG_EMPTY;
  }
}

/* Function:  destroyUartDevice
 * --------------------
 * destroy/clean up the uart data structure
 */
static void destroyUartDevice(HBC56Device *device)
{
  UartDevice *uartDevice = getUartDevice(device);
  if (uartDevice)
  {
    resetDevice(device);
  }
  free(uartDevice);
  device->data = NULL;
}

/* Function:  tickUartDevice
 * --------------------
 * tick the uart device
 */
static void tickUartDevice(HBC56Device* device, uint32_t deltaTicks, double deltaTime)
{
  UartDevice* uartDevice = getUartDevice(device);
  if (uartDevice && uartDevice->handle)
  {
    uartDevice->timeSinceIO += deltaTime;

    if (uartDevice->readBufferBytes == uartDevice->readBufferBytesRead &&
        uartDevice->timeSinceIO > 0.002 && uartDevice->statusRequested)
    {
      DWORD bytesRead = 0;
      if (ReadFile(uartDevice->handle, uartDevice->readBuffer, sizeof(uartDevice->readBuffer), &bytesRead, NULL) && bytesRead)
      {
        uartDevice->readBufferBytes = bytesRead & 0xff;
        uartDevice->readBufferBytesRead = 0;

        uartDevice->statusReg |= UART_STATUS_RX_REG_FULL;
      }

      uartDevice->timeSinceIO = 0;
    }

    if (uartDevice->readBufferBytes > uartDevice->readBufferBytesRead)
    {
      if (uartDevice->controlReg & UART_CTL_RX_INT_ENABLE)
      {
        hbc56Interrupt(uartDevice->irq, INTERRUPT_RAISE);
      }
    }
  }
}


/* Function:  readUartDevice
 * --------------------
 * read from the uart device
 */
static uint8_t readUartDevice(HBC56Device* device, uint16_t addr, uint8_t *val, uint8_t dbg)
{
  UartDevice* uartDevice = getUartDevice(device);
  if (uartDevice && val)
  {
    if (addr == uartDevice->addr)   // status register
    {
      uartDevice->statusRequested = 1;
      *val = uartDevice->statusReg;
      
      return 1;
    }
    else if (addr == (uartDevice->addr | 0x01)) // data
    {
      if (uartDevice->readBufferBytes > uartDevice->readBufferBytesRead)
      {
        *val = uartDevice->readBuffer[uartDevice->readBufferBytesRead++];

        if (uartDevice->readBufferBytes == uartDevice->readBufferBytesRead)
        {
          uartDevice->statusReg &= ~(UART_STATUS_RX_REG_FULL);

          hbc56Interrupt(uartDevice->irq, INTERRUPT_RELEASE);
        }
      }
      return 1;
    }
  }
  return 0;
}

/* Function:  writeMemoryDevice
 * --------------------
 * write to the memory device
 */
static uint8_t writeUartDevice(HBC56Device* device, uint16_t addr, uint8_t val)
{
  UartDevice* uartDevice = getUartDevice(device);
  if (uartDevice)
  {
    if (addr == uartDevice->addr)
    {
      uartDevice->controlReg = val;

      if ((uartDevice->controlReg & UART_CTL_MASTER_RESET) == UART_CTL_MASTER_RESET)
      {
        if (uartDevice->handle)
        {
          CloseHandle(uartDevice->handle);
          uartDevice->handle = NULL;
        }

        uartDevice->handle = CreateFileA(uartDevice->comPortDevice,
                                     GENERIC_READ | GENERIC_WRITE,
                                     0,
                                     NULL,
                                     OPEN_EXISTING,
                                     0,
                                     NULL);

        COMMTIMEOUTS timeouts = { 0 };

        //Setting Timeouts
        timeouts.ReadIntervalTimeout = 0;
        timeouts.ReadTotalTimeoutConstant = 1;
        timeouts.ReadTotalTimeoutMultiplier = 0;
        timeouts.WriteTotalTimeoutConstant = 1;
        timeouts.WriteTotalTimeoutMultiplier = 0;
        SetCommTimeouts(uartDevice->handle, &timeouts);
      }
      else if (uartDevice->handle)
      {
        DCB dcb;
        SecureZeroMemory(&dcb, sizeof(DCB));
        dcb.DCBlength = sizeof(DCB);

        GetCommState(uartDevice->handle, &dcb);

        switch (uartDevice->controlReg & 0x03)
        {
          case 0:
            dcb.BaudRate = uartDevice->clockFreq;
            break;

          case UART_CTL_MASTER_RESET:  // reset
            uartDevice->readBufferBytes = 0;
            uartDevice->readBufferBytesRead = 0;
            uartDevice->statusRequested = 0;
            uartDevice->statusReg = UART_STATUS_TX_REG_EMPTY;
            break;

          case UART_CTL_CLOCK_DIV_16:
            dcb.BaudRate = uartDevice->clockFreq / 16;
            break;

          case UART_CTL_CLOCK_DIV_64:
          default:
            dcb.BaudRate = uartDevice->clockFreq / 64;
            break;
        }

        switch (uartDevice->controlReg & 0x1c)
        {
          case UART_CTL_WORD_7BIT_EPB_2SB:
            dcb.ByteSize = 7;
            dcb.Parity = EVENPARITY;
            dcb.StopBits = TWOSTOPBITS;
            break;

          case UART_CTL_WORD_7BIT_OPB_2SB:
            dcb.ByteSize = 7;
            dcb.Parity = ODDPARITY;
            dcb.StopBits = TWOSTOPBITS;
            break;

          case UART_CTL_WORD_7BIT_EPB_1SB:
            dcb.ByteSize = 7;
            dcb.Parity = EVENPARITY;
            dcb.StopBits = ONESTOPBIT;
            break;

          case UART_CTL_WORD_7BIT_OPB_1SB:
            dcb.ByteSize = 7;
            dcb.Parity = ODDPARITY;
            dcb.StopBits = ONESTOPBIT;
            break;

          case UART_CTL_WORD_8BIT_2SB:
            dcb.ByteSize = 8;
            dcb.Parity = NOPARITY;
            dcb.StopBits = TWOSTOPBITS;
            break;

          case UART_CTL_WORD_8BIT_1SB:
            dcb.ByteSize = 8;
            dcb.Parity = NOPARITY;
            dcb.StopBits = ONESTOPBIT;
            break;

          case UART_CTL_WORD_8BIT_EPAR_1SB:
            dcb.ByteSize = 8;
            dcb.Parity = EVENPARITY;
            dcb.StopBits = ONESTOPBIT;
            break;

          case UART_CTL_WORD_8BIT_OPAR_1SB:
            dcb.ByteSize = 8;
            dcb.Parity = ODDPARITY;
            dcb.StopBits = ONESTOPBIT;
            break;
        }
        SetCommState(uartDevice->handle, &dcb);

        DWORD bytesRead = 0;
        while (ReadFile(uartDevice->handle, uartDevice->readBuffer, sizeof(uartDevice->readBuffer), &bytesRead, NULL) && bytesRead)
        {
          // empty buffer
        }

        hbc56Interrupt(uartDevice->irq, INTERRUPT_RELEASE);
      }

      return 1;
    }
    else if (addr == (uartDevice->addr | 0x01))
    {
      if (uartDevice->handle)
      {
        DWORD bytesWritten = 0;
        if (!WriteFile(uartDevice->handle, &val, 1, &bytesWritten, NULL))
        {
          /* shrug */
        }
      }
      return 1;
    }
  }
  return 0;
}

#endif