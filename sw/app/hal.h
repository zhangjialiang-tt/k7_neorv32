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
 * Checks for TWI availability and configures it for 100kHz operation.
 * @return 0 on success, -1 if TWI is not available.
 */
int hal_twi_init(void);

/**
 * @brief Scan TWI bus for devices and print results via UART.
 */
void hal_twi_bus_scan(void);

/**
 * @brief Write a single byte to an EEPROM.
 * @param address The EEPROM memory address to write to (0-0x01FF for AT24C04).
 * @param data The data byte to write.
 * @return 0 on success, -1 on failure (NACK received).
 */
int hal_twi_eeprom_write_byte(uint16_t address, uint8_t data);

/**
 * @brief Read a single byte from an EEPROM.
 * @param address The EEPROM memory address to read from (0-0x01FF for AT24C04).
 * @param data Pointer to store the read data byte.
 * @return 0 on success, -1 on failure (NACK received).
 */
int hal_twi_eeprom_read_byte(uint16_t address, uint8_t *data);

#endif // APP_HAL_H