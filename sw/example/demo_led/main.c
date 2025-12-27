// ================================================================================ //
// The NEORV32 RISC-V Processor - https://github.com/stnolting/neorv32              //
// Copyright (c) NEORV32 contributors.                                              //
// Copyright (c) 2020 - 2025 Stephan Nolting. All rights reserved.                  //
// Licensed under the BSD-3-Clause license, see LICENSE for details.                //
// SPDX-License-Identifier: BSD-3-Clause                                            //
// ================================================================================ //

/**********************************************************************
 * @file demo_blink_led/main.c
 * @author Stephan Nolting
 * @brief Key-controlled LED toggle demo program.
 **************************************************************************/
#include <neorv32.h>
#include "led.h"
#include "key.h"

/**********************************************************************
 * @name User configuration
 **************************************************************************/
/**@{*/
/** UART BAUD rate */
#define BAUD_RATE 115200
/**@}*/

/**********************************************************************
 * Simple bus-wait helper.
 *
 * @param[in] time_ms Time in ms to wait (unsigned 32-bit).
 **************************************************************************/
void delay_ms(uint32_t time_ms)
{
    neorv32_aux_delay_ms(neorv32_sysinfo_get_clk(), time_ms);
}

/**********************************************************************
 * Main function; key-controlled LED toggle.
 *
 * @note This program requires the GPIO controller to be synthesized.
 *
 * @return Will never return.
 **************************************************************************/
int main()
{

    // capture all exceptions and give debug info via UART
    // this is not required, but keeps us safe
    neorv32_rte_setup();

    // setup UART at default baud rate, no interrupts
    neorv32_uart0_setup(BAUD_RATE, 0);

    // print project logo via UART
    neorv32_aux_print_logo();

    // Check if GPIO unit is implemented
    if (neorv32_gpio_available() == 0)
    {
        return 1;
    }

    // Initialize LEDs (clears them)
    led_init();

    // Initialize keys
    key_init();

    uint32_t keys;
    uint8_t led_state = 0;
    uint32_t last_keys = 0x1F; // Initialize to all released (active-low: 1=released)

    neorv32_uart0_puts("\n");
    neorv32_uart0_puts("LED Toggle Control Demo\n");
    neorv32_uart0_puts("----------------------\n");
    neorv32_uart0_puts("Press keys to toggle corresponding LEDs\n");
    neorv32_uart0_puts("Key0 -> LED0, Key1 -> LED1, ...\n\n");

    while (1)
    {
        // Read key states
        keys = key_get_state();

        // Detect key press for each key
        for (int i = 0; i < KEY_NUM; i++)
        {
            if (key_detect_press(keys, last_keys, i))
            {
                // Toggle corresponding LED
                led_state ^= (1U << i);
                led_set_byte(led_state);

                // Print debug message
                neorv32_uart0_puts("Key");
                neorv32_uart0_putc('0' + i);
                neorv32_uart0_puts(" pressed - LED");
                neorv32_uart0_putc('0' + i);
                neorv32_uart0_puts(" now ");
                neorv32_uart0_puts((led_state & (1U << i)) ? "ON\n" : "OFF\n");
            }
        }

        // Store current key state for next iteration
        last_keys = keys;

        // Small delay for debouncing
        delay_ms(20);
    }

    // this should never be reached
    return 0;
}