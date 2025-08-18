#include "hal.h"
// #include <stdio.h> // Removed to save space

/**
 * @brief Simple helper function to print a byte in hexadecimal format
 * @param data The byte to print
 */
static void print_hex_byte(uint8_t data) {
    static const char hex_symbols[] = "0123456789ABCDEF";
    hal_uart0_putc(hex_symbols[(data >> 4) & 0xF]);
    hal_uart0_putc(hex_symbols[(data >> 0) & 0xF]);
}

/**
 * @brief Write a single byte to an EEPROM (e.g., AT24C04).
 * @param address The EEPROM memory address (0-0x01FF for AT24C04).
 * @param data The data byte to write.
 * @return 0 on success, -1 on failure.
 */
int app_eeprom_write_byte(uint16_t address, uint8_t data)
{
    // For AT24C04: Device addr incorporates A9-A8 in bits 2-1
    uint8_t slave_addr = HAL_TWI_EEPROM_DEVICE_ADDR | ((address >> 8) & 0x03);

    // Prepare buffer: memory address (low 8 bits) + data
    uint8_t buf[2];
    buf[0] = (uint8_t)(address & 0xFF);
    buf[1] = data;

    // Use generic write
    int ret = hal_twi_write(slave_addr, buf, 2);

    // Wait for write cycle
    if (ret == 0)
    {
        hal_delay_ms(5);
    }

    return ret;
}

/**
 * @brief Read a single byte from an EEPROM (e.g., AT24C04).
 * @param address The EEPROM memory address (0-0x01FF for AT24C04).
 * @param data Pointer to store the read data byte.
 * @return 0 on success, -1 on failure.
 */
int app_eeprom_read_byte(uint16_t address, uint8_t *data)
{
    // For AT24C04: Device addr incorporates A9-A8 in bits 2-1
    uint8_t slave_addr = HAL_TWI_EEPROM_DEVICE_ADDR | ((address >> 8) & 0x03);

    // Write buffer: memory address (low 8 bits)
    uint8_t wr_buf[1];
    wr_buf[0] = (uint8_t)(address & 0xFF);

    // Use combined write-read
    return hal_twi_write_read(slave_addr, wr_buf, 1, data, 1);
}

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
    print_hex_byte(tx_data);
    hal_uart0_print(" to EEPROM address 0x");
    print_hex_byte((test_addr >> 8) & 0xFF);
    print_hex_byte((test_addr >> 0) & 0xFF);
    hal_uart0_print("...");

    if (app_eeprom_write_byte(test_addr, tx_data) == 0) {
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
    print_hex_byte((test_addr >> 8) & 0xFF);
    print_hex_byte((test_addr >> 0) & 0xFF);
    hal_uart0_print("...");

    if (app_eeprom_read_byte(test_addr, &rx_data) == 0) {
        hal_uart0_print(" OK\n");
    }
    else {
        hal_uart0_print(" FAILED!\n");
        hal_uart0_print("Test halted.\n");
        // In a real application, you might want to handle this error differently
    }

    // Verify
    hal_uart0_print("\nTX data: 0x");
    print_hex_byte(tx_data);
    hal_uart0_print(", RX data: 0x");
    print_hex_byte(rx_data);
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