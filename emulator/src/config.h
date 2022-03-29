/*
 * Troy's HBC-56 Emulator
 *
 * Copyright (c) 2021 Troy Schrapel
 *
 * This code is licensed under the MIT license
 *
 * https://github.com/visrealm/hbc-56/emulator
 *
 */


#ifndef _HBC56_CONFIG_H_
#define _HBC56_CONFIG_H_


/* emulator configuration values 
  -------------------------------------------------------------------------- */
#define HBC56_HAVE_THREADS      0

#define HBC56_CLOCK_FREQ        3686400   /* half of 7.3728*/
#define HBC56_AUDIO_FREQ        48000
#define HBC56_MAX_DEVICES       16

/* memory map configuration values 
  -------------------------------------------------------------------------- */
#define HBC56_RAM_START         0x0000
#define HBC56_RAM_SIZE          0x7f00

#define HBC56_ROM_START         0x8000
#define HBC56_ROM_SIZE          0x8000

#define HBC56_IO_START          0x7f00
#define HBC56_IO_SIZE           0x0100

/* device configuration values 
  -------------------------------------------------------------------------- */
#define HBC56_HAVE_TMS9918      1
#define HBC56_TMS9918_PORT      0x10
#define HBC56_TMS9918_DAT_PORT  HBC56_TMS9918_PORT
#define HBC56_TMS9918_REG_PORT (HBC56_TMS9918_PORT | 0x01)
#define HBC56_TMS9918_IRQ      1

#define HBC56_HAVE_LCD          1
#define HBC56_LCD_PORT          0x02
#define HBC56_LCD_CMD_PORT      HBC56_LCD_PORT
#define HBC56_LCD_DAT_PORT     (HBC56_LCD_PORT | 0x01)

#define HBC56_HAVE_NES          1
#define HBC56_NES_PORT          0x82

#define HBC56_HAVE_KB           1
#define HBC56_KB_PORT           0x80
#define HBC56_KB_IRQ            2

#define HBC56_HAVE_AY_3_8910    1
#define HBC56_AY_3_8910_COUNT   2
#define HBC56_AY38910_A_PORT    0x40
#define HBC56_AY38910_B_PORT    0x44
#define HBC56_AY38910_CLOCK     1000000

#ifdef _WINDOWS
#define HBC56_HAVE_UART         1
#define HBC56_UART_PORT         0x20
#define HBC56_UART_PORTNAME     "COM7"
#define HBC56_UART_CLOCK_FREQ   HBC56_CLOCK_FREQ
#define HBC56_UART_IRQ          3
#endif

/* computed configuration values (shouldn't need to touch these) 
  -------------------------------------------------------------------------- */
#define HBC56_RAM_END           (HBC56_RAM_START + HBC56_RAM_SIZE) /* one past end */
#define HBC56_ROM_END           (HBC56_ROM_START + HBC56_ROM_SIZE) /* one past end */
#define HBC56_RAM_MASK          ~HBC56_RAM_START
#define HBC56_ROM_MASK          ~HBC56_ROM_START
#define HBC56_IO_PORT_MASK      (HBC56_IO_SIZE - 1)

#define HBC56_IO_ADDRESS(p)     (HBC56_IO_START | p)


#endif