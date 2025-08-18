#include "hal.h"
// #include <stdio.h> // Removed to save space

int main(void)
{
    // Initialize the HAL layer
    hal_init();

    // Print a message via UART
    hal_uart0_print("Hello from custom HAL with GPIO Interrupt Counter and TWI!\n");

    // Set LED_PIN as output (implicitly done by writing to it)
    hal_gpio_clear_pin(LED_PIN); // Start with LED off

    // --- TWI EEPROM Test ---
    // Diagnostic Step 1: Scan the bus
    hal_uart0_print("--- Starting I2C Bus Scan ---\n");
    hal_twi_bus_scan();
    hal_uart0_print("--- Scan Complete ---\n\n");

    // Test sequence
    uint16_t test_addr = 0x0042; // EEPROM address to write to
    uint8_t tx_data = 0xCA;      // Data to write
    uint8_t rx_data = 0;         // Data to read

    // Write byte
    hal_uart0_print("Writing 0x");
    // Simple hex print
    static const char hex_symbols[] = "0123456789ABCDEF";
    hal_uart0_putc(hex_symbols[(tx_data >> 4) & 0xF]);
    hal_uart0_putc(hex_symbols[(tx_data >> 0) & 0xF]);
    hal_uart0_print(" to EEPROM address 0x");
    hal_uart0_putc(hex_symbols[(test_addr >> 12) & 0xF]);
    hal_uart0_putc(hex_symbols[(test_addr >> 8) & 0xF]);
    hal_uart0_putc(hex_symbols[(test_addr >> 4) & 0xF]);
    hal_uart0_putc(hex_symbols[(test_addr >> 0) & 0xF]);
    hal_uart0_print("...");

    if (hal_twi_eeprom_write_byte(test_addr, tx_data) == 0) {
        hal_uart0_print(" OK\n");
    }
    else {
        hal_uart0_print(" FAILED!\n");
        hal_uart0_print("Test halted.\n");
        // In a real application, you might want to handle this error differently
        // For now, we'll continue with the rest of the program
    }

    // Read byte back
    hal_uart0_print("Reading from EEPROM address 0x");
    hal_uart0_putc(hex_symbols[(test_addr >> 12) & 0xF]);
    hal_uart0_putc(hex_symbols[(test_addr >> 8) & 0xF]);
    hal_uart0_putc(hex_symbols[(test_addr >> 4) & 0xF]);
    hal_uart0_putc(hex_symbols[(test_addr >> 0) & 0xF]);
    hal_uart0_print("...");

    if (hal_twi_eeprom_read_byte(test_addr, &rx_data) == 0) {
        hal_uart0_print(" OK\n");
    }
    else {
        hal_uart0_print(" FAILED!\n");
        hal_uart0_print("Test halted.\n");
        // In a real application, you might want to handle this error differently
    }

    // Verify
    hal_uart0_print("\nTX data: 0x");
    hal_uart0_putc(hex_symbols[(tx_data >> 4) & 0xF]);
    hal_uart0_putc(hex_symbols[(tx_data >> 0) & 0xF]);
    hal_uart0_print(", RX data: 0x");
    hal_uart0_putc(hex_symbols[(rx_data >> 4) & 0xF]);
    hal_uart0_putc(hex_symbols[(rx_data >> 0) & 0xF]);
    hal_uart0_print("\n");

    if (tx_data == rx_data) {
        hal_uart0_print("SUCCESS! Data matches.\n");
    }
    else {
        hal_uart0_print("ERROR! Data mismatch!\n");
    }

    hal_uart0_print("\nI2C test complete. Program will now run GPIO interrupt counter.\n");
    // --- End of TWI EEPROM Test ---

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
        // No need to check ext_irq_count here anymore
    }

    // The program should never reach here
    return 0;
}