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

#include <stdlib.h>
#include <string.h>
#include <windows.h>

static void destroyUartDevice(HBC56Device*);
static void tickUartDevice(HBC56Device*, uint32_t, double);
static uint8_t readUartDevice(HBC56Device*, uint16_t, uint8_t*, uint8_t);
static uint8_t writeUartDevice(HBC56Device*, uint16_t, uint8_t);

/* memory device data */
struct UartDevice
{
  uint32_t addr;
  HANDLE   handle;

  uint8_t readBufferBytes;
  uint8_t readBufferBytesRead;

  uint8_t readBuffer[255];

  uint8_t statusRequested;

  double timeSinceIO;
  
};
typedef struct UartDevice UartDevice;

/* Function:  createUartDevice
 * --------------------
 * create a uart device for the given address
 */
HBC56Device createUartDevice(
  uint32_t addr,
  const char* port,
  int baudrate)
{
  HBC56Device device = createDevice("UART");
  UartDevice* uartDevice = (UartDevice*)malloc(sizeof(UartDevice));
  if (uartDevice)
  {
    uartDevice->addr = addr;
    uartDevice->readBufferBytes = 0;
    uartDevice->readBufferBytesRead = 0;
    uartDevice->statusRequested = 0;
    uartDevice->handle = CreateFileA(port,
                                     GENERIC_READ | GENERIC_WRITE,
                                     0,
                                     NULL,
                                     OPEN_EXISTING,
                                     0,
                                     NULL);

    DCB dcb;
    SecureZeroMemory(&dcb, sizeof(DCB));
    dcb.DCBlength = sizeof(DCB);

    GetCommState(uartDevice->handle, &dcb);
    dcb.BaudRate = baudrate;
    dcb.ByteSize = 8;
    dcb.Parity = NOPARITY;
    dcb.StopBits = ONESTOPBIT;

    SetCommState(uartDevice->handle, &dcb);

    device.data = uartDevice;
    device.destroyFn = destroyUartDevice;
    device.tickFn = tickUartDevice;
    device.readFn = readUartDevice;
    device.writeFn = writeUartDevice;

    COMMTIMEOUTS timeouts = { 0 };

    //Setting Timeouts
    timeouts.ReadIntervalTimeout = 0;
    timeouts.ReadTotalTimeoutConstant = 1;
    timeouts.ReadTotalTimeoutMultiplier = 0;
    timeouts.WriteTotalTimeoutConstant = 1;
    timeouts.WriteTotalTimeoutMultiplier = 0;
    SetCommTimeouts(uartDevice->handle, &timeouts);
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

/* Function:  destroyUartDevice
 * --------------------
 * destroy/clean up the uart data structure
 */
static void destroyUartDevice(HBC56Device *device)
{
  UartDevice *uartDevice = getUartDevice(device);
  if (uartDevice)
  {
    if (uartDevice->handle)
    {
      CloseHandle(uartDevice->handle);
    }
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
  if (uartDevice)
  {
    uartDevice->timeSinceIO += deltaTime;

    if (uartDevice->readBufferBytes == uartDevice->readBufferBytesRead &&
        uartDevice->timeSinceIO > 0.01 && uartDevice->statusRequested)
    {
      DWORD bytesRead = 0;
      if (ReadFile(uartDevice->handle, uartDevice->readBuffer, sizeof(uartDevice->readBuffer), &bytesRead, NULL) && bytesRead)
      {
        uartDevice->readBufferBytes = bytesRead & 0xff;
        uartDevice->readBufferBytesRead = 0;
      }

      uartDevice->timeSinceIO = 0;
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
      *val = 0;

      uartDevice->statusRequested = 1;

      if (uartDevice->readBufferBytes > uartDevice->readBufferBytesRead)
      {
        *val |= 0x01;
      }

      *val |= 0x02; // tx reg empty
      
      return 1;
    }
    else if (addr == (uartDevice->addr | 0x01)) // data
    {
      if (uartDevice->readBufferBytes > uartDevice->readBufferBytesRead)
      {
        *val = uartDevice->readBuffer[uartDevice->readBufferBytesRead++];
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
      return 1;
    }
    else if (addr == (uartDevice->addr | 0x01))
    {
      DWORD bytesWritten = 0;
      if (!WriteFile(uartDevice->handle, &val, 1, &bytesWritten, NULL))
      {
        /* shrug */
      }
      return 1;
    }
  }
  return 0;
}

#endif