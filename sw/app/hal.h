#ifndef APP_HAL_H
#define APP_HAL_H

#include <neorv32.h>

// --- GPIO Abstraction ---
// Example abstraction for GPIO pins
// Define your specific pin usages here
#define LED_PIN        0  // Example: LED on GPIO pin 0
#define BUTTON_PIN     1  // Example: Button on GPIO pin 1

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

// --- Timer Abstraction ---
/**
 * @brief Get the current system time in milliseconds (based on MTIMER).
 * @note This is a simplified example. For more precision, consider using the RISC-V cycle CSR directly or a dedicated timer.
 * @return Current time in milliseconds.
 */
uint64_t hal_time_ms(void);

/**
 * @brief Busy-wait for a specified number of milliseconds.
 * @param ms Number of milliseconds to wait.
 */
void hal_delay_ms(uint32_t ms);


#endif // APP_HAL_H