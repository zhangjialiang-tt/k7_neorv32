#include "hal.h"
#include <string.h>

// Global variable to count external interrupts
// Marked as volatile because it's modified in the interrupt handler
// and accessed in the main loop (though in this specific implementation,
// it's only modified and checked in the ISR, so volatile might be optional
// but it's good practice for shared variables between ISR and main context).
volatile uint32_t ext_irq_count = 0;

// -----------------------------------------------------------------------------
// GPIO Implementation
// -----------------------------------------------------------------------------

/**
 * @brief Initialize the HAL layer.
 * This function initializes the underlying NEORV32 peripherals.
 * It sets up the RTE (Runtime Environment), clears the GPIO port,
 * initializes UART0, and configures GPIO interrupt for external signal counting.
 */
void hal_init(void)
{
    // Capture all exceptions and give debug info via UART
    // This is useful for debugging if something goes wrong during initialization
    neorv32_rte_setup();

    // Clear GPIO output (set all bits to 0)
    // Ensures a known state for all GPIO pins at startup
    neorv32_gpio_port_set(0);

    // Initialize UART0 for debug output
    hal_uart0_init();

    // Initialize GPIO interrupt for external signal counting
    hal_gpio_irq_init();
    
    // Initialize TWI (I2C) interface
    if (hal_twi_init() != 0) {
        hal_uart0_print("ERROR! Failed to initialize TWI.\n");
    }

    // Note on MTIMER: The MTIMER is always available in the NEORV32.
    // No specific initialization is needed here.
    // Its clock is the main processor clock divided by CLINT::MTIME_CYCLES_PER_TICK (usually 100).
    // The `hal_delay_ms` function uses it for busy-wait delays.
}

/**
 * @brief Set a specific GPIO pin high.
 * @param pin The pin number (0-31).
 */
void hal_gpio_set_pin(uint8_t pin)
{
    // Check for valid pin number
    if (pin < 32)
    {
        // Set the bit corresponding to the pin
        NEORV32_GPIO->PORT_OUT |= (1U << pin);
    }
    // If pin is invalid, do nothing. In a more robust system, you might want to return an error.
}

/**
 * @brief Clear a specific GPIO pin (set low).
 * @param pin The pin number (0-31).
 */
void hal_gpio_clear_pin(uint8_t pin)
{
    // Check for valid pin number
    if (pin < 32)
    {
        // Clear the bit corresponding to the pin
        NEORV32_GPIO->PORT_OUT &= ~(1U << pin);
    }
    // If pin is invalid, do nothing.
}

/**
 * @brief Toggle a specific GPIO pin.
 * @param pin The pin number (0-31).
 */
void hal_gpio_toggle_pin(uint8_t pin)
{
    // Check for valid pin number
    if (pin < 32)
    {
        // Toggle the bit corresponding to the pin
        NEORV32_GPIO->PORT_OUT ^= (1U << pin);
    }
    // If pin is invalid, do nothing.
}

/**
 * @brief Read the state of a specific GPIO pin.
 * @param pin The pin number (0-31).
 * @return 1 if the pin is high, 0 if the pin is low, 0 for invalid pin.
 */
int hal_gpio_get_pin(uint8_t pin)
{
    // Check for valid pin number
    if (pin < 32)
    {
        // Read the bit corresponding to the pin
        return (NEORV32_GPIO->PORT_IN >> pin) & 1U;
    }
    // Return 0 for invalid pin
    return 0;
}

/**
 * @brief Set the state of the entire GPIO output port.
 * @param value The 32-bit value to write to the output port.
 */
void hal_gpio_set_port(uint32_t value)
{
    // Write the value to the entire GPIO output port
    NEORV32_GPIO->PORT_OUT = value;
}

/**
 * @brief Get the state of the entire GPIO input port.
 * @return The 32-bit value read from the input port.
 */
uint32_t hal_gpio_get_port(void)
{
    // Read the value from the entire GPIO input port
    return NEORV32_GPIO->PORT_IN;
}

// -----------------------------------------------------------------------------
// UART Implementation
// -----------------------------------------------------------------------------

/**
 * @brief Initialize UART0 with a default baud rate.
 * Checks if UART0 is available before initializing.
 */
void hal_uart0_init(void)
{
    // Check if UART0 is available in the hardware configuration
    if (neorv32_uart0_available() == 0)
    {
        // If UART0 is not available, we can't do anything here.
        // In a real application, you might want to handle this error differently,
        // e.g., by using a different UART or disabling UART output.
        // For now, we'll just return without initializing.
        return;
    }

    // Reset UART0 (optional, but good practice)
    // neorv32_uart0_reset();

    // Configure UART0 with default baud rate and standard settings (8N1)
    // The library function handles the baud rate calculation based on the current
    // processor clock speed (f_main).
    neorv32_uart0_setup(HAL_UART_BAUD_DEFAULT, 0); // 0 = no parity, 1 stop bit, 8 data bits
}

/**
 * @brief Print a string via UART0.
 * @param s Pointer to the null-terminated string.
 */
void hal_uart0_print(const char *s)
{
    // Use the library function to print the string
    neorv32_uart0_printf(s);
}

/**
 * @brief Print a single character via UART0.
 * @param c The character to print.
 */
void hal_uart0_putc(char c)
{
    // Use the library function to print the character
    neorv32_uart0_putc(c);
}

/**
 * @brief Get a single character from UART0.
 * This function will block until a character is received.
 * @return The received character.
 */
char hal_uart0_getc(void)
{
    // Use the library function to get a character
    // This will block if no character is available
    return neorv32_uart0_getc();
}

// -----------------------------------------------------------------------------
// Timer Abstraction
// -----------------------------------------------------------------------------

/**
 * @brief Busy-wait for a specified number of milliseconds.
 * @param ms Number of milliseconds to wait.
 * 
 * @note This function uses the auxiliary delay function which in turn uses
 * the system timer (MTIMER). It is a busy-wait implementation and will block
 * the CPU for the duration of the delay.
 */
void hal_delay_ms(uint32_t ms)
{
    // Use the library's auxiliary delay function
    // It takes the processor's clock speed and the desired delay in milliseconds
    neorv32_aux_delay_ms(neorv32_sysinfo_get_clk(), ms);
}

// -----------------------------------------------------------------------------
// GPIO Interrupt Abstraction
// -----------------------------------------------------------------------------

/**
 * @brief Initialize GPIO interrupt for external signal counting.
 * Configures GPIO pin 1 (GPIO_IRQ_PIN) to generate an interrupt on a falling edge.
 * Installs the interrupt handler and enables the interrupt in the CPU.
 */
void hal_gpio_irq_init(void)
{
    // Check if GPIO unit is implemented in the hardware configuration
    if (neorv32_gpio_available() == 0)
    {
        // If GPIO is not available, print an error message and return
        hal_uart0_print("ERROR! GPIO controller not available!\n");
        return;
    }

    // Install our custom GPIO interrupt handler
    // GPIO_TRAP_CODE is the standard trap code for GPIO interrupts in NEORV32
    neorv32_rte_handler_install(GPIO_TRAP_CODE, hal_gpio_interrupt_handler);

    // Enable the GPIO Fast Interrupt Request (FIRQ) channel in the CPU's MIE CSR
    // GPIO_FIRQ_ENABLE is a bit mask defined by the NEORV32 library
    neorv32_cpu_csr_set(CSR_MIE, 1 << GPIO_FIRQ_ENABLE);

    // Enable global interrupts by setting the MIE bit in the MSTATUS CSR
    neorv32_cpu_csr_set(CSR_MSTATUS, 1 << CSR_MSTATUS_MIE);

    // Configure the specific GPIO pin (GPIO_IRQ_PIN) to trigger an interrupt
    // on a falling edge. This is suitable for a signal that goes from high to low.
    // If your signal goes from low to high, use GPIO_TRIG_EDGE_RISING instead.
    neorv32_gpio_irq_setup(GPIO_IRQ_PIN, GPIO_TRIG_EDGE_FALLING);
    // neorv32_gpio_irq_setup(GPIO_IRQ_PIN, GPIO_TRIG_EDGE_RISING); // Alternative

    // Enable the interrupt for the specific GPIO pin
    // This allows the pin to actually generate interrupts
    neorv32_gpio_irq_enable(1 << GPIO_IRQ_PIN);

    // Print a confirmation message
    hal_uart0_print("GPIO interrupt configured.\n");
}

/**
 * @brief GPIO interrupt handler for external signal counting.
 * This function is called whenever a falling edge is detected on GPIO pin 1.
 * It increments a counter and prints a message every 50 interrupts (1 second).
 * 
 * @note This function runs in an interrupt context. It should be as short
 * and fast as possible. Avoid complex operations or blocking calls.
 * The `ext_irq_count` variable is declared as volatile to ensure
 * the compiler doesn't optimize accesses to it.
 */
void hal_gpio_interrupt_handler(void)
{
    // Clear the interrupt flag for the specific GPIO pin
    // This is essential to prevent the interrupt from firing continuously
    neorv32_gpio_irq_clr(1 << GPIO_IRQ_PIN);

    // Increment the external interrupt counter
    ext_irq_count++;

    // Check if 50 interrupts have been counted (equivalent to 1 second)
    // This assumes the external signal triggers an interrupt every 20ms.
    if (ext_irq_count >= 50)
    {
        // Reset the counter for the next cycle
        ext_irq_count = 0;

        // Print a message indicating 1 second has passed
        // This is a relatively slow operation for an ISR, but acceptable
        // for this example. In a time-critical application, you might
        // want to set a flag here and print the message in the main loop.
        hal_uart0_print("1 second has passed (50 interrupts counted).\n");
    }
}

// -----------------------------------------------------------------------------
// TWI (I2C) Implementation
// -----------------------------------------------------------------------------

/**
 * @brief Initialize TWI (I2C) interface.
 * Checks for TWI availability and configures it for 100kHz operation.
 * @return 0 on success, -1 if TWI is not available.
 */
int hal_twi_init(void)
{
    // Check if TWI unit is implemented in the hardware configuration
    if (neorv32_twi_available() == 0)
    {
        return -1; // TWI not available
    }

    // Configure TWI for 100kHz operation
    // CLK_PRSC_128: Clock prescaler
    // 1: SCL clock divider (CLDIV register)
    // 0: No clock stretching
    neorv32_twi_setup(CLK_PRSC_128, 1, 0);
    
    hal_uart0_print("TWI initialized.\n");
    return 0; // Success
}

/**
 * @brief Scan TWI bus for devices and print results via UART.
 * This function iterates through all possible 7-bit I2C addresses (0-127)
 * and attempts to communicate with each device. If an ACK is received,
 * the device is considered present.
 */
void hal_twi_bus_scan(void)
{
    uint8_t i;
    int num_devices = 0;

    hal_uart0_print("--- Starting I2C Bus Scan ---\n");

    // Iterate through all possible 7-bit addresses
    for (i = 0; i < 128; i++)
    {
        // Generate a START condition
        neorv32_twi_generate_start();
        
        // Prepare the device address for writing (LSB = 0)
        uint8_t addr_rw = (i << 1) | 0;
        
        // Attempt to transfer the address and check for ACK
        // The second parameter '0' indicates we are sending data
        int ack = neorv32_twi_transfer(&addr_rw, 0);
        
        // Generate a STOP condition to complete the transaction
        neorv32_twi_generate_stop();

        // If ACK was received (ack == 0), a device is present at this address
        if (ack == 0)
        {
            // Print the address of the found device
            hal_uart0_print(" + Device found at address 0x");
            // Simple hex print (could be a helper function)
            static const char hex_symbols[] = "0123456789ABCDEF";
            hal_uart0_putc(hex_symbols[(i >> 4) & 0xF]);
            hal_uart0_putc(hex_symbols[(i >> 0) & 0xF]);
            hal_uart0_print(" (write addr 0x");
            hal_uart0_putc(hex_symbols[(addr_rw >> 4) & 0xF]);
            hal_uart0_putc(hex_symbols[(addr_rw >> 0) & 0xF]);
            hal_uart0_print(")\n");
            
            num_devices++;
        }
    }

    // Print summary
    if (num_devices == 0)
    {
        hal_uart0_print("No devices found. Check wiring, pull-ups and power!\n");
    }
    else
    {
        hal_uart0_print("Total devices found: ");
        // Convert num_devices to string manually
        // Handle hundreds place
        if (num_devices >= 100) {
            hal_uart0_putc('0' + (num_devices / 100));
            num_devices %= 100;
        }
        // Handle tens place (or units if < 100)
        if (num_devices >= 10 || (num_devices < 100 && num_devices >= 10)) {
            hal_uart0_putc('0' + (num_devices / 10));
            num_devices %= 10;
        }
        // Handle units place
        hal_uart0_putc('0' + (num_devices % 10));
        hal_uart0_print("\n");
    }
    
    hal_uart0_print("--- Scan Complete ---\n\n");
}

/**
 * @brief Write a single byte to an EEPROM.
 * This function writes a single byte to a specified address in an AT24C04 EEPROM.
 * It handles the device addressing, memory addressing, and data transmission.
 * 
 * @param address The EEPROM memory address to write to (0-0x01FF for AT24C04).
 *                The AT24C04 uses the lower 8 bits of the address directly
 *                and bits 8-9 are used in the device address byte.
 * @param data The data byte to write.
 * @return 0 on success, -1 on failure (NACK received during transfer).
 */
int hal_twi_eeprom_write_byte(uint16_t address, uint8_t data)
{
    // Calculate the device address byte
    // The base device address is shifted left by 1 bit.
    // Bits 8 and 9 of the memory address (A9, A8) are used in the device address.
    // For AT24C04, A1 and A0 pins are grounded, so the base address is 0b1010000.
    // The LSB is 0 for a write operation.
    uint8_t device_addr_byte = (HAL_TWI_EEPROM_DEVICE_ADDR << 1) | ((address >> 7) & 0x06) | 0;
    
    // The word (memory) address byte is the lower 8 bits of the address
    uint8_t word_addr_byte = (uint8_t)(address & 0xFF);

    // Generate a START condition on the TWI bus
    neorv32_twi_generate_start();

    // Send the device address byte
    // If this or any subsequent transfer fails (returns non-zero), we have an error
    if (neorv32_twi_transfer(&device_addr_byte, 0)) // 0 = send data
    {
        // If NACK received, generate STOP and return error
        neorv32_twi_generate_stop();
        return -1;
    }

    // Send the memory address byte
    if (neorv32_twi_transfer(&word_addr_byte, 0)) // 0 = send data
    {
        neorv32_twi_generate_stop();
        return -1;
    }

    // Send the data byte
    if (neorv32_twi_transfer(&data, 0)) // 0 = send data
    {
        neorv32_twi_generate_stop();
        return -1;
    }

    // Generate a STOP condition to complete the write transaction
    neorv32_twi_generate_stop();
    
    // The EEPROM needs time to complete the write cycle internally.
    // A small delay (e.g., 5ms) is usually sufficient for AT24Cxx series.
    hal_delay_ms(5);
    
    // Return success
    return 0;
}

/**
 * @brief Read a single byte from an EEPROM.
 * This function reads a single byte from a specified address in an AT24C04 EEPROM.
 * It involves a "write" transaction to set the address, followed by a "read" transaction.
 * 
 * @param address The EEPROM memory address to read from (0-0x01FF for AT24C04).
 *                The addressing scheme is the same as for writing.
 * @param data Pointer to store the read data byte.
 * @return 0 on success, -1 on failure (NACK received during transfer).
 */
int hal_twi_eeprom_read_byte(uint16_t address, uint8_t *data)
{
    // Calculate the device address bytes for write and read phases
    // Write phase: Send address, LSB = 0
    uint8_t device_addr_byte_write = (HAL_TWI_EEPROM_DEVICE_ADDR << 1) | ((address >> 7) & 0x06) | 0;
    // Read phase: Read data, LSB = 1
    uint8_t device_addr_byte_read = (HAL_TWI_EEPROM_DEVICE_ADDR << 1) | ((address >> 7) & 0x06) | 1;
    
    // The word (memory) address byte is the lower 8 bits of the address
    uint8_t word_addr_byte = (uint8_t)(address & 0xFF);
    
    // Buffer to receive the data byte
    uint8_t rx_buffer = 0xFF; // Initialize with a default value

    // --- Write Phase: Set the memory address ---
    // Generate a START condition
    neorv32_twi_generate_start();
    
    // Send the device address byte (for writing)
    if (neorv32_twi_transfer(&device_addr_byte_write, 0)) // 0 = send data
    {
        neorv32_twi_generate_stop();
        return -1;
    }
    
    // Send the memory address byte
    if (neorv32_twi_transfer(&word_addr_byte, 0)) // 0 = send data
    {
        neorv32_twi_generate_stop();
        return -1;
    }

    // --- Read Phase: Read the data ---
    // Generate a repeated START condition
    neorv32_twi_generate_start();
    
    // Send the device address byte (for reading)
    if (neorv32_twi_transfer(&device_addr_byte_read, 0)) // 0 = send data
    {
        neorv32_twi_generate_stop();
        return -1;
    }
    
    // Receive the data byte from the EEPROM
    // The second parameter '1' indicates we are receiving data and will send a NACK
    // after receiving this byte (since it's the last byte we want to read).
    neorv32_twi_transfer(&rx_buffer, 1); // 1 = receive data and send NACK
    
    // Generate a STOP condition to complete the read transaction
    neorv32_twi_generate_stop();

    // Store the received data in the user-provided variable
    *data = rx_buffer;
    
    // Return success
    return 0;
}