#include "hal.h"
// #include <stdio.h> // Removed to save space

int main(void)
{
    // Initialize the HAL layer
    hal_init();

    // Print a message via UART
    hal_uart0_print("Hello from custom HAL with GPIO Interrupt Counter!\n");

    // Set LED_PIN as output (implicitly done by writing to it)
    hal_gpio_clear_pin(LED_PIN); // Start with LED off

    // Main application loop
    int cnt = 0;
    while (1)
    {
        // Toggle the LED
        hal_gpio_toggle_pin(LED_PIN);

        // Print a message
        hal_uart0_print("LED Toggled.\n");

        // Delay for 1000 milliseconds
        hal_delay_ms(1000);

        // Increment counter and mask for lowest 8 bit
        hal_gpio_set_port(cnt++ & 0xFF);

        // The external interrupt counting is handled in the interrupt handler
        // No need to check gpio_irq_fired here anymore
    }

    // The program should never reach here
    return 0;
}