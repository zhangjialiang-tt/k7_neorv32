// ================================================================================ //
// The NEORV32 RISC-V Processor - https://github.com/stnolting/neorv32              //
// Copyright (c) NEORV32 contributors.                                              //
// Copyright (c) 2020 - 2025 Stephan Nolting. All rights reserved.                  //
// Licensed under the BSD-3-Clause license, see LICENSE for details.                //
// SPDX-License-Identifier: BSD-3-Clause                                            //
// ================================================================================ //

/**********************************************************************//**
 * @file demo_spi_flash/main.c
 * @brief SPI Flash Read ID test program.
 * @author NEORV32 User
 **************************************************************************/

#include <neorv32.h>

/**********************************************************************//**
 * @name User configuration
 **************************************************************************/
/**@{*/
/** UART BAUD rate */
#define BAUD_RATE 19200
/**@}*/

/**********************************************************************//**
 * @brief SPI Flash Read ID test program.
 *
 * @note This program requires the UART and the SPI to be synthesized.
 *
 * @return Irrelevant.
 **************************************************************************/
int main() {

  uint8_t id_manufacturer, id_memory_type, id_capacity;

  // capture all exceptions and give debug info via UART
  // this is not required, but keeps us safe
  neorv32_rte_setup();

  // setup UART at default baud rate, no interrupts
  neorv32_uart0_setup(BAUD_RATE, 0);

  // check if UART0 unit is implemented at all
  if (neorv32_uart0_available() == 0) {
    return 1;
  }

  // intro
  neorv32_uart0_printf("\n<<< SPI Flash Read ID Test >>>\n\n");

  // check if SPI unit is implemented at all
  if (neorv32_spi_available() == 0) {
    neorv32_uart0_printf("ERROR! No SPI unit implemented.");
    return 1;
  }

  // disable global interrupts
  neorv32_cpu_csr_clr(CSR_MIE, -1);

  // setup SPI module: 64 prescaler, no clock divider, mode 0
  neorv32_spi_setup(3, 0, 0, 0);  // 64 prescaler (CLK_PRSC_64 = 3)

  // enable SPI module
  neorv32_spi_enable();

  // enable chip select (CS low)
  neorv32_spi_cs_en(0);

  // send Read ID command (0x9F)
  neorv32_spi_transfer(0x9F);

  // read manufacturer ID
  id_manufacturer = neorv32_spi_transfer(0x00);

  // read memory type
  id_memory_type = neorv32_spi_transfer(0x00);

  // read capacity
  id_capacity = neorv32_spi_transfer(0x00);

  // disable chip select (CS high)
  neorv32_spi_cs_dis();

  // print the read IDs
  neorv32_uart0_printf("ID: %d %d %d\n", 
                       id_manufacturer, id_memory_type, id_capacity);

  // infinite loop
  while(1) {
    asm volatile ("nop");
  }

  return 0;
}