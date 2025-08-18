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
    if (hal_twi_init(CLK_PRSC_128, 1, 0) != 0) // 100kHz operation
    {
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
 * Checks for TWI availability and configures it with the specified clock prescaler and divider.
 * @param clk_prsc Clock prescaler value (e.g., CLK_PRSC_128 for 100kHz).
 * @param clk_div Clock divider value.
 * @param stretch Enable clock stretching (1) or disable (0).
 * @return 0 on success, -1 if TWI is not available.
 */
int hal_twi_init(uint32_t clk_prsc, uint32_t clk_div, uint32_t stretch)
{
    // Check if TWI unit is implemented in the hardware configuration
    if (neorv32_twi_available() == 0)
    {
        return -1; // TWI not available
    }

    // Configure TWI with the provided parameters
    neorv32_twi_setup(clk_prsc, clk_div, stretch);

    hal_uart0_print("TWI initialized.\n");
    return 0; // Success
}

/**
 * @brief Perform a TWI (I2C) write transaction to a slave device.
 * This function handles the START, address transmission, data write, and STOP.
 * @param slave_addr 7-bit slave address (shifted left by 1 internally if needed).
 * @param data Pointer to the data buffer to write.
 * @param len Length of the data buffer.
 * @return 0 on success, -1 on failure (NACK or other error).
 */
int hal_twi_write(uint8_t slave_addr, const uint8_t *data, uint32_t len)
{
    // Generate a START condition
    neorv32_twi_generate_start();

    // Prepare slave address for write (LSB = 0)
    uint8_t addr_rw = (slave_addr << 1) | 0;

    // Send the slave address
    if (neorv32_twi_transfer(&addr_rw, 0)) // 0 = send data
    {
        neorv32_twi_generate_stop();
        return -1; // NACK or error
    }

    // Send the data bytes
    for (uint32_t i = 0; i < len; i++)
    {
        uint8_t byte = data[i];
        if (neorv32_twi_transfer(&byte, 0)) // 0 = send data
        {
            neorv32_twi_generate_stop();
            return -1; // NACK or error
        }
    }

    // Generate a STOP condition
    neorv32_twi_generate_stop();

    return 0; // Success
}

/**
 * @brief Perform a TWI (I2C) read transaction from a slave device.
 * This function handles the START, address transmission, data read, and STOP.
 * @param slave_addr 7-bit slave address (shifted left by 1 internally if needed).
 * @param data Pointer to the buffer to store read data.
 * @param len Length of the data to read.
 * @return 0 on success, -1 on failure (NACK or other error).
 */
int hal_twi_read(uint8_t slave_addr, uint8_t *data, uint32_t len)
{
    // Generate a START condition
    neorv32_twi_generate_start();

    // Prepare slave address for read (LSB = 1)
    uint8_t addr_rw = (slave_addr << 1) | 1;

    // Send the slave address
    if (neorv32_twi_transfer(&addr_rw, 0)) // 0 = send data
    {
        neorv32_twi_generate_stop();
        return -1; // NACK or error
    }

    // Read the data bytes
    for (uint32_t i = 0; i < len; i++)
    {
        // For the last byte, send NACK (1), otherwise ACK (0)
        int nack = (i == len - 1) ? 1 : 0;
        if (neorv32_twi_transfer(&data[i], nack)) // nack = receive with ACK/NACK
        {
            neorv32_twi_generate_stop();
            return -1; // Error
        }
    }

    // Generate a STOP condition
    neorv32_twi_generate_stop();

    return 0; // Success
}

/**
 * @brief Perform a combined TWI (I2C) write-then-read transaction.
 * Useful for reading from a register after writing the register address.
 * @param slave_addr 7-bit slave address.
 * @param wr_data Pointer to the write data buffer (e.g., register address).
 * @param wr_len Length of the write data.
 * @param rd_data Pointer to the read data buffer.
 * @param rd_len Length of the read data.
 * @return 0 on success, -1 on failure (NACK or other error).
 */
int hal_twi_write_read(uint8_t slave_addr, const uint8_t *wr_data, uint32_t wr_len, uint8_t *rd_data, uint32_t rd_len)
{
    // --- Write Phase ---
    // Generate a START condition
    neorv32_twi_generate_start();

    // Prepare slave address for write (LSB = 0)
    uint8_t addr_wr = (slave_addr << 1) | 0;

    // Send the slave address for write
    if (neorv32_twi_transfer(&addr_wr, 0))
    {
        neorv32_twi_generate_stop();
        return -1;
    }

    // Send the write data (e.g., register address)
    for (uint32_t i = 0; i < wr_len; i++)
    {
        uint8_t byte = wr_data[i];
        if (neorv32_twi_transfer(&byte, 0))
        {
            neorv32_twi_generate_stop();
            return -1;
        }
    }

    // --- Read Phase ---
    // Generate a repeated START condition
    neorv32_twi_generate_start();

    // Prepare slave address for read (LSB = 1)
    uint8_t addr_rd = (slave_addr << 1) | 1;

    // Send the slave address for read
    if (neorv32_twi_transfer(&addr_rd, 0))
    {
        neorv32_twi_generate_stop();
        return -1;
    }

    // Read the data bytes
    for (uint32_t i = 0; i < rd_len; i++)
    {
        // For the last byte, send NACK (1), otherwise ACK (0)
        int nack = (i == rd_len - 1) ? 1 : 0;
        if (neorv32_twi_transfer(&rd_data[i], nack))
        {
            neorv32_twi_generate_stop();
            return -1;
        }
    }

    // Generate a STOP condition
    neorv32_twi_generate_stop();

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
        // Use the generic write function to probe (send 0 bytes after address)
        if (hal_twi_write(i, NULL, 0) == 0)
        {
            // Print the address of the found device
            hal_uart0_print(" + Device found at address 0x");
            // Simple hex print
            static const char hex_symbols[] = "0123456789ABCDEF";
            hal_uart0_putc(hex_symbols[(i >> 4) & 0xF]);
            hal_uart0_putc(hex_symbols[(i >> 0) & 0xF]);
            hal_uart0_print("\n");

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
        // Simple integer print (assuming small num_devices)
        char buf[16];
        neorv32_aux_itoa(buf, (uint32_t)num_devices, 10);  // Correct parameter order: buffer, number, base
        hal_uart0_print(buf);
        hal_uart0_print("\n");
    }

    hal_uart0_print("--- Scan Complete ---\n\n");
}
