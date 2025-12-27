// ================================================================================ //
// The NEORV32 RISC-V Processor - https://github.com/stnolting/neorv32              //
// Copyright (c) NEORV32 contributors.                                              //
// Copyright (c) 2020 - 2025 Stephan Nolting. All rights reserved.                  //
// Licensed under the BSD-3-Clause license, see LICENSE for details.                //
// SPDX-License-Identifier: BSD-3-Clause                                            //
// ================================================================================ //

/**********************************************************************
 * @file key.c
 * @brief Key driver implementation
 **************************************************************************/
#include "key.h"

/**********************************************************************
 * @brief Initialize key driver
 **************************************************************************/
void key_init(void)
{
    // Check if GPIO unit is implemented
    if (neorv32_gpio_available() == 0)
    {
        return;
    }

    // GPIO input pins [31:27] are inputs by default
    // No additional configuration needed
}

/**********************************************************************
 * @brief Get current key states
 *
 * @return Key states (bit 0-4 for key0-key4, 1=released, 0=pressed)
 **************************************************************************/
uint32_t key_get_state(void)
{
    // Read GPIO port and extract upper 5 bits [31:27]
    uint32_t gpio_input = neorv32_gpio_port_get();
    return (gpio_input >> KEY_GPIO_BASE) & 0x1F;
}

/**********************************************************************
 * @brief Check if a specific key is pressed
 *
 * @param key_idx Key index (0-4)
 * @return 1 if pressed, 0 if released
 **************************************************************************/
int key_is_pressed(uint8_t key_idx)
{
    if (key_idx >= KEY_NUM)
    {
        return 0;
    }

    uint32_t keys = key_get_state();
    // Active-low: 0 = pressed, 1 = released
    return ((keys & (1U << key_idx)) == 0) ? 1 : 0;
}

/**********************************************************************
 * @brief Detect key press edge (falling edge)
 *
 * @param current Current key states
 * @param last Last key states
 * @param key_idx Key index (0-4)
 * @return 1 if key just pressed, 0 otherwise
 **************************************************************************/
int key_detect_press(uint32_t current, uint32_t last, uint8_t key_idx)
{
    if (key_idx >= KEY_NUM)
    {
        return 0;
    }

    uint32_t mask = 1U << key_idx;

    // Detect falling edge: last was 1 (released), current is 0 (pressed)
    if ((last & mask) && !(current & mask))
    {
        return 1;
    }

    return 0;
}
