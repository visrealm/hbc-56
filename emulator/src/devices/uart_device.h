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

#ifndef _HBC56_UART_DEVICE_H_
#define _HBC56_UART_DEVICE_H_

#include "device.h"


/* Function:  createUartDevice
 * --------------------
 * create a uart device for the given address
 */
HBC56Device createUartDevice(uint32_t addr, const char *port, int clockrate, uint8_t irq);


#endif