#ifndef APP_HAL_H
#define APP_HAL_H

#include <neorv32.h>

// --- GPIO Abstraction ---
// Example abstraction for GPIO pins
// Define your specific pin usages here
#define LED_PIN        0  // Example: LED on GPIO pin 0
#define BUTTON_PIN     1  // Example: Button on GPIO pin 1

// --- GPIO Interrupt Abstraction ---
/** GPIO pin for external interrupt */
#define GPIO_IRQ_PIN 0
// Globals for GPIO interrupt
extern volatile uint32_t ext_irq_count;

// --- TWI Abstraction ---
/** I2C device address of the AT24C04 EEPROM.
 * This assumes the address pins A1 and A2 are grounded. */
#define HAL_TWI_EEPROM_DEVICE_ADDR 0b1010000

/**
 * @brief Initialize the HAL layer.
 * This function initializes the underlying NEORV32 peripherals.
 */
void hal_init(void);

/**
 * @brief Set a specific GPIO pin high.
 * @param pin The pin number (0-31).
 */
void hal_gpio_set_pin(uint8_t pin);

/**
 * @brief Clear a specific GPIO pin (set low).
 * @param pin The pin number (0-31).
 */
void hal_gpio_clear_pin(uint8_t pin);

/**
 * @brief Toggle a specific GPIO pin.
 * @param pin The pin number (0-31).
 */
void hal_gpio_toggle_pin(uint8_t pin);

/**
 * @brief Read the state of a specific GPIO pin.
 * @param pin The pin number (0-31).
 * @return 1 if the pin is high, 0 if the pin is low.
 */
int hal_gpio_get_pin(uint8_t pin);

/**
 * @brief Set the state of the entire GPIO output port.
 * @param value The 32-bit value to write to the output port.
 */
void hal_gpio_set_port(uint32_t value);

/**
 * @brief Get the state of the entire GPIO input port.
 * @return The 32-bit value read from the input port.
 */
uint32_t hal_gpio_get_port(void);

// --- UART Abstraction ---
// Example abstraction for UART0
#define HAL_UART_BAUD_DEFAULT 19200

/**
 * @brief Initialize UART0 with a default baud rate.
 */
void hal_uart0_init(void);

/**
 * @brief Print a string via UART0.
 * @param s Pointer to the string.
 */
void hal_uart0_print(const char *s);

/**
 * @brief Print a single character via UART0.
 * @param c The character to print.
 */
void hal_uart0_putc(char c);

/**
 * @brief Get a single character from UART0.
 * @return The received character.
 */
char hal_uart0_getc(void);

/**
 * @brief Busy-wait for a specified number of milliseconds.
 * @param ms Number of milliseconds to wait.
 */
void hal_delay_ms(uint32_t ms);

// --- GPIO Interrupt Abstraction ---
/**
 * @brief Initialize GPIO interrupt.
 */
void hal_gpio_irq_init(void);

/**
 * @brief GPIO interrupt handler.
 */
void hal_gpio_interrupt_handler(void);

// --- TWI Abstraction ---
/**
 * @brief Initialize TWI (I2C) interface.
 * Checks for TWI availability and configures it with the specified clock prescaler and divider.
 * @param clk_prsc Clock prescaler value (e.g., CLK_PRSC_128 for 100kHz).
 * @param clk_div Clock divider value.
 * @param stretch Enable clock stretching (1) or disable (0).
 * @return 0 on success, -1 if TWI is not available.
 */
int hal_twi_init(uint32_t clk_prsc, uint32_t clk_div, uint32_t stretch);

/**
 * @brief Scan TWI bus for devices and print results via UART.
 */
void hal_twi_bus_scan(void);

/**
 * @brief Perform a TWI (I2C) write transaction to a slave device.
 * This function handles the START, address transmission, data write, and STOP.
 * @param slave_addr 7-bit slave address.
 * @param data Pointer to the data buffer to write.
 * @param len Length of the data buffer.
 * @return 0 on success, -1 on failure (NACK or other error).
 */
int hal_twi_write(uint8_t slave_addr, const uint8_t *data, uint32_t len);

/**
 * @brief Perform a TWI (I2C) read transaction from a slave device.
 * This function handles the START, address transmission, data read, and STOP.
 * @param slave_addr 7-bit slave address.
 * @param data Pointer to the buffer to store read data.
 * @param len Length of the data to read.
 * @return 0 on success, -1 on failure (NACK or other error).
 */
int hal_twi_read(uint8_t slave_addr, uint8_t *data, uint32_t len);

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
int hal_twi_write_read(uint8_t slave_addr, const uint8_t *wr_data, uint32_t wr_len, uint8_t *rd_data, uint32_t rd_len);

#endif // APP_HAL_H