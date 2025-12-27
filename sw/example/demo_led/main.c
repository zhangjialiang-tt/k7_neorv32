// ================================================================================ //
// The NEORV32 RISC-V Processor - https://github.com/stnolting/neorv32              //
// Copyright (c) NEORV32 contributors.                                              //
// Copyright (c) 2020 - 2025 Stephan Nolting. All rights reserved.                  //
// Licensed under the BSD-3-Clause license, see LICENSE for details.                //
// SPDX-License-Identifier: BSD-3-Clause                                            //
// ================================================================================ //


/**********************************************************************//**
 * @file demo_blink_led/main.c
 * @author Stephan Nolting
 * @brief Minimal blinking LED demo program using GPIO output.
 **************************************************************************/
#include <neorv32.h>
#include "led.h"


/**********************************************************************//**
 * Simple bus-wait helper.
 *
 * @param[in] time_ms Time in ms to wait (unsigned 32-bit).
 **************************************************************************/
void delay_ms(uint32_t time_ms) {
  neorv32_aux_delay_ms(neorv32_sysinfo_get_clk(), time_ms);
}


/**********************************************************************//**
 * Main function; shows an incrementing 8-bit counter on LEDs.
 *
 * @note This program requires the GPIO controller to be synthesized.
 *
 * @return Will never return.
 **************************************************************************/
int main() {

  // Check if GPIO unit is implemented
  if (neorv32_gpio_available() == 0) {
    return 1;
  }

  // Initialize LEDs (clears them)
  led_init();

  int cnt = 0;

  while (1) {
    led_set_byte(cnt++ & 0xFF); // Display counter on LEDs
    delay_ms(250); // wait 250ms
  }

  // this should never be reached
  return 0;
}