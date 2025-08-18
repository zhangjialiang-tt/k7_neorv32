#include "hal.h"
int main(void)
{                                                // Initialize the HAL layer
    hal_init();                                  // Print a message via UART
    hal_uart0_print("Hello from custom HAL!\\"); // Set LED_PIN as output (implicitly done by writing to it)
    hal_gpio_clear_pin(LED_PIN);                 // Start with LED off    // Main application loop
    while (1)
    {                                    // Toggle the LED
        hal_gpio_toggle_pin(LED_PIN);    // Print a message
        hal_uart0_print("LED Toggled."); // Delay for 500 milliseconds
        hal_delay_ms(1000);
    } // The program should never reach here
    return 0;
}