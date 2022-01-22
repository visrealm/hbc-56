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
#if 0
#include <stdlib.h>
#include <string.h>
#include <windows.h>

static void destroyUartDevice(HBC56Device*);
static uint8_t readUartDevice(HBC56Device*, uint16_t, uint8_t*, uint8_t);
static uint8_t writeUartDevice(HBC56Device*, uint16_t, uint8_t);

/* memory device data */
struct UartDevice
{
  uint32_t addr;
  HANDLE   handle;
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
    device.destroyFn = &destroyUartDevice;
    device.readFn = &readUartDevice;
    device.writeFn = &writeUartDevice;
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
      return 1;
    }
    else if (addr == (uartDevice->addr | 0x01)) // data
    {
      
      *val = 0;
      return 1;
    }
  }
  return 0;
}

/* Function:  writeMemoryDevice
 * --------------------
 * write to the memory device
 */
static uint8_t writeMemoryDevice(HBC56Device* device, uint16_t addr, uint8_t val)
{
  MemoryDevice* memoryDevice = getMemoryDevice(device);
  if (memoryDevice)
  {
    if (addr >= memoryDevice->startAddr &&
        addr < memoryDevice->endAddr)
    {
      memoryDevice->data[addr - memoryDevice->startAddr] = val;
      return 1;
    }
  }
  return 0;
}

/* Function:  setMemoryDeviceContents
 * --------------------
 * update a ram/rom device contents. contents size must be equal to device size
 */
int setMemoryDeviceContents(HBC56Device* device, const uint8_t* contents, uint32_t contentSize)
{
  MemoryDevice* memoryDevice = getMemoryDevice(device);
  if (memoryDevice)
  {
    if (memoryDevice->endAddr - memoryDevice->startAddr != contentSize)
      return 0;

    memcpy(memoryDevice->data, contents, contentSize);
    return 1;
  }
  return 0;
}

#endif