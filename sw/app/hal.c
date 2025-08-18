#include "hal.h"

// --- GPIO Implementation ---

void hal_init(void)
{
    neorv32_rte_setup();
    // Initialize GPIO
    // By default, all pins are inputs after reset.
    // Configure output pins here if needed.
    // For example, set LED_PIN as output:
    // NEORV32_GPIO->PORT_OUT = 0; // Clear outputs
    // NEORV32_GPIO->IRQ_TYPE = 0; // Set all triggers to "level"
    // NEORV32_GPIO->IRQ_POLARITY = 0; // Set all polarities to "low/rising"
    // If there were GPIO direction control registers (which standard GPIO doesn't have),
    // you would set them here. Standard GPIO assumes fixed direction per pin or
    // uses the output register to drive pins low (if capable) or tri-state/high-Z (for inputs).

    // Initialize UART0
    hal_uart0_init();

    // NOTE: MTIMER is always available in the NEORV32, no specific init needed here.
    // Its clock is the main processor clock divided by CLINT::MTIME_CYCLES_PER_TICK (usually 100).
    // The `hal_time_ms` function will use it directly.
}

void hal_gpio_set_pin(uint8_t pin)
{
    if (pin < 32)
    {
        NEORV32_GPIO->PORT_OUT |= (1U << pin);
    }
}

void hal_gpio_clear_pin(uint8_t pin)
{
    if (pin < 32)
    {
        NEORV32_GPIO->PORT_OUT &= ~(1U << pin);
    }
}

void hal_gpio_toggle_pin(uint8_t pin)
{
    if (pin < 32)
    {
        NEORV32_GPIO->PORT_OUT ^= (1U << pin);
    }
}

int hal_gpio_get_pin(uint8_t pin)
{
    if (pin < 32)
    {
        return (NEORV32_GPIO->PORT_IN >> pin) & 1U;
    }
    return 0; // Default return for invalid pin
}

void hal_gpio_set_port(uint32_t value)
{
    NEORV32_GPIO->PORT_OUT = value;
}

uint32_t hal_gpio_get_port(void)
{
    return NEORV32_GPIO->PORT_IN;
}

// --- UART Implementation ---

void hal_uart0_init(void)
{
    // Reset UART0
    // neorv32_uart0_reset();
    // setup UART0 at default baud rate, no interrupts
    if (neorv32_uart0_available() == 0)
    { // UART0 available?
        return;
    }

    // Configure UART0
    // The default clock is the processor's main clock (f_main)
    // Baud rate calculation: baud = f_main / (PRSC * (BAUD_REG + 1))
    // We'll use the library function for simplicity which handles the calculation
    // based on the current f_main clock speed.
    neorv32_uart0_setup(HAL_UART_BAUD_DEFAULT, 0); // 0 = no parity, 1 stop bit, 8 data bits
}

void hal_uart0_print(const char *s)
{
    neorv32_uart0_printf(s);
}

void hal_uart0_putc(char c)
{
    neorv32_uart0_putc(c);
}

char hal_uart0_getc(void)
{
    return neorv32_uart0_getc();
}


void hal_delay_ms(uint32_t ms)
{
    neorv32_aux_delay_ms(neorv32_sysinfo_get_clk(), ms);
}