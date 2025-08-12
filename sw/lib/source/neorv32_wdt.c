// ================================================================================ //
// The NEORV32 RISC-V Processor - https://github.com/stnolting/neorv32              //
// Copyright (c) NEORV32 contributors.                                              //
// Copyright (c) 2020 - 2025 Stephan Nolting. All rights reserved.                  //
// Licensed under the BSD-3-Clause license, see LICENSE for details.                //
// SPDX-License-Identifier: BSD-3-Clause                                            //
// ================================================================================ //

/**
 * @file neorv32_wdt.c
 * @brief Watchdog Timer (WDT) HW driver source file.
 */

#include <neorv32.h>


/**********************************************************************//**
 * Check if WDT unit was synthesized.
 *
 * @return 0 if WDT was not synthesized, non-zero if WDT is available.
 **************************************************************************/
int neorv32_wdt_available(void) {

  return (int)(NEORV32_SYSINFO->SOC & (1 << SYSINFO_SOC_IO_WDT));
}


/**********************************************************************//**
 * Configure and enable watchdog timer.
 *
 * @warning Once the lock bit is set it can only be removed by a hardware reset.
 *
 * @param[in] timeout 24-bit timeout value
 * @param[in] lock Control register will be locked when 1 (until next HW reset).
 **************************************************************************/
void neorv32_wdt_setup(uint32_t timeout, int lock) {

  NEORV32_WDT->CTRL = 0; // reset and disable

  // set configuration
  uint32_t ctrl = 0;
  ctrl |= ((uint32_t)(1))                    << WDT_CTRL_EN;
  ctrl |= ((uint32_t)(timeout & 0x00ffffff)) << WDT_CTRL_TIMEOUT_LSB;
  NEORV32_WDT->CTRL = ctrl;

  // lock configuration?
  if (lock) {
    NEORV32_WDT->CTRL |= (uint32_t)(1 << WDT_CTRL_LOCK);
  }
}


/**********************************************************************//**
 * Disable watchdog timer.
 *
 * @return Returns 0 if WDT is really deactivated, -1 otherwise.
 **************************************************************************/
int neorv32_wdt_disable(void) {

  const uint32_t en_mask_c = (uint32_t)(1 << WDT_CTRL_EN);

  NEORV32_WDT->CTRL &= en_mask_c; // try to disable

  // check if WDT is really off
  if (NEORV32_WDT->CTRL & en_mask_c) {
    return -1; // still active
  }
  else {
    return 0; // WDT is disabled
  }
}


/**********************************************************************//**
 * Feed watchdog (reset timeout counter).
 *
 * @param[in] password Password for WDT reset.
 **************************************************************************/
void neorv32_wdt_feed(uint32_t password) {

  NEORV32_WDT->RESET = password;
}


/**********************************************************************//**
 * Force a hardware reset triggered by the watchdog.
 **************************************************************************/
void neorv32_wdt_force_hwreset(void) {

  // make sure the WDT is enabled
  NEORV32_WDT->CTRL |= (uint32_t)(1 << WDT_CTRL_EN);

  // lock the WDT configuration
  // if it is already locked this will trigger a hardware reset
  NEORV32_WDT->CTRL |= (uint32_t)(1 << WDT_CTRL_LOCK);

  // try to reset the WDT using an incorrect password;
  // this will finally trigger a hardware reset
  NEORV32_WDT->RESET = 0;
}


/**********************************************************************//**
 * Get cause of last system reset.
 *
 * @return Cause of last reset (#NEORV32_WDT_RCAUSE_enum).
 **************************************************************************/
int neorv32_wdt_get_cause(void) {

  return (NEORV32_WDT->CTRL >> WDT_CTRL_RCAUSE_LO) & 0x3;
}
