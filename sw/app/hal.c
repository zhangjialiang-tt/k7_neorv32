#include "hal.h"
#include <string.h>

// Globals for GPIO interrupt
volatile uint32_t ext_irq_count = 0;

// --- GPIO Implementation ---

void hal_init(void)
{
    // Capture all exceptions and give debug info via UART
    neorv32_rte_setup();

    // Clear GPIO output (set all bits to 0)
    neorv32_gpio_port_set(0);

    // Initialize UART0
    hal_uart0_init();

    // Initialize GPIO interrupt
    hal_gpio_irq_init();

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
    // Check if UART0 is available
    if (neorv32_uart0_available() == 0)
    {
        // If UART0 is not available, we can't do anything here.
        // In a real application, you might want to handle this error differently.
        // For now, we'll just return without initializing.
        return;
    }

    // Reset UART0
    // neorv32_uart0_reset();

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

// --- Timer Abstraction ---
void hal_delay_ms(uint32_t ms)
{
    neorv32_aux_delay_ms(neorv32_sysinfo_get_clk(), ms);
}

// --- GPIO Interrupt Abstraction ---

void hal_gpio_irq_init(void)
{
    // Check if GPIO unit is implemented
    if (neorv32_gpio_available() == 0)
    {
        hal_uart0_print("ERROR! GPIO controller not available!\n");
        return;
    }

    // Install our GPIO interrupt handler
    neorv32_rte_handler_install(GPIO_TRAP_CODE, hal_gpio_interrupt_handler);

    // Enable GPIO FIRQ channel in CPU
    neorv32_cpu_csr_set(CSR_MIE, 1 << GPIO_FIRQ_ENABLE);

    // Enable global interrupts
    neorv32_cpu_csr_set(CSR_MSTATUS, 1 << CSR_MSTATUS_MIE);

    // Configure interrupt for falling edge on our specific pin (matching demo_ti35)
    // Or rising edge, depending on your signal
    neorv32_gpio_irq_setup(GPIO_IRQ_PIN, GPIO_TRIG_EDGE_FALLING);
    // neorv32_gpio_irq_setup(GPIO_IRQ_PIN, GPIO_TRIG_EDGE_RISING);

    // Enable interrupt for the specific GPIO pin
    neorv32_gpio_irq_enable(1 << GPIO_IRQ_PIN);

    hal_uart0_print("GPIO interrupt configured.\n");
}

void hal_gpio_interrupt_handler(void)
{
    // Clear the specific pin's IRQ flag
    neorv32_gpio_irq_clr(1 << GPIO_IRQ_PIN);

    // Increment the external interrupt count
    ext_irq_count++;

    // Check if count has reached 50
    if (ext_irq_count >= 50)
    {
        ext_irq_count = 0; // Reset the counter
        hal_uart0_print("1 second has passed (50 interrupts counted).\n");
    }
}