// ================================================================================ //
// The NEORV32 RISC-V Processor - https://github.com/stnolting/neorv32              //
// Copyright (c) NEORV32 contributors.                                              //
// Copyright (c) 2020 - 2025 Stephan Nolting. All rights reserved.                  //
// Licensed under the BSD-3-Clause license, see LICENSE for details.                //
// SPDX-License-Identifier: BSD-3-Clause                                            //
// ================================================================================ //

/**********************************************************************
 * @file key.h
 * @brief Key driver header file
 **************************************************************************/

#ifndef KEY_H
#define KEY_H

#include <neorv32.h>

/**********************************************************************
 * @name Key configuration
 **************************************************************************/
/**@{*/
/** Number of keys */
#define KEY_NUM 5
/** Key input GPIO bit position (gpio_i[31:27]) */
#define KEY_GPIO_BASE 27
/**@}*/

/**********************************************************************
 * @name Key functions
 **************************************************************************/
/**@{*/
/**
 * @brief Initialize key driver
 */
void key_init(void);

/**
 * @brief Get current key states
 * @return Key states (bit 0-4 for key0-key4, 1=released, 0=pressed)
 */
uint32_t key_get_state(void);

/**
 * @brief Check if a specific key is pressed
 * @param key_idx Key index (0-4)
 * @return 1 if pressed, 0 if released
 */
int key_is_pressed(uint8_t key_idx);

/**
 * @brief Detect key press edge (falling edge)
 * @param current Current key states
 * @param last Last key states
 * @param key_idx Key index (0-4)
 * @return 1 if key just pressed, 0 otherwise
 */
int key_detect_press(uint32_t current, uint32_t last, uint8_t key_idx);

/**@}*/

#endif // KEY_H
