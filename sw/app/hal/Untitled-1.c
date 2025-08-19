#include "hal/hal_gpio.h"
#include "hal/hal_uart.h"
#include "hal/hal_interrupt.h"
#include "../lib/include/neorv32.h"
#include <stdio.h>

// 全局计数器变量
static volatile uint32_t gpio_interrupt_counter = 0;

// GPIO 中断回调函数
void gpio_irq_callback(hal_gpio_pin_t pin)
{
    // 增加中断计数器
    gpio_interrupt_counter++;

    // 每50次中断打印一次
    if (gpio_interrupt_counter % 50 == 0)
    {
        hal_uart_printf(HAL_UART_PORT_0, "GPIO%d interrupt count: %d\r\n", pin, gpio_interrupt_counter);
    }
}

int main(void)
{
    // 初始化中断管理系统
    if (hal_interrupt_init() != HAL_INTERRUPT_OK)
    {
        return -1;
    }

    // 初始化 UART 用于调试输出
    hal_uart_config_t uart_config = {
        .baudrate = 19200,
        .data_bits = HAL_UART_DATA_BITS_8,
        .stop_bits = HAL_UART_STOP_BITS_1,
        .parity = HAL_UART_PARITY_NONE,
        .hw_flow_control = false};

    if (hal_uart_init(HAL_UART_PORT_0, &uart_config) != HAL_UART_OK)
    {
        return -1;
    }

    hal_uart_transmit_string(HAL_UART_PORT_0, "NEORV32 GPIO External Interrupt Demo\r\n");

    // 检查 GPIO 是否可用
    if (!hal_gpio_is_available())
    {
        hal_uart_transmit_string(HAL_UART_PORT_0, "GPIO not available!\r\n");
        return -1;
    }

    // 注册 GPIO 中断回调函数
    if (hal_gpio_register_irq_callback(gpio_irq_callback) != HAL_GPIO_OK)
    {
        hal_uart_transmit_string(HAL_UART_PORT_0, "Failed to register GPIO callback!\r\n");
        return -1;
    }

    // 注册 GPIO 中断处理函数
    if (hal_interrupt_register_handler(HAL_INTERRUPT_GPIO, hal_gpio_irq_handler) != HAL_INTERRUPT_OK)
    {
        hal_uart_transmit_string(HAL_UART_PORT_0, "Failed to register GPIO interrupt handler!\r\n");
        return -1;
    }

    // 配置 GPIO0 为输入并启用上升沿中断
    if (hal_gpio_config_irq(0, HAL_GPIO_TRIG_EDGE_RISING) != HAL_GPIO_OK)
    {
        hal_uart_transmit_string(HAL_UART_PORT_0, "Failed to config GPIO0 interrupt!\r\n");
        return -1;
    }

    if (hal_gpio_enable_irq(1U << 0) != HAL_GPIO_OK)
    { // 使能 GPIO0 中断
        hal_uart_transmit_string(HAL_UART_PORT_0, "Failed to enable GPIO0 interrupt!\r\n");
        return -1;
    }

    // 启用 GPIO 中断和全局中断
    if (hal_interrupt_enable(HAL_INTERRUPT_GPIO) != HAL_INTERRUPT_OK)
    {
        hal_uart_transmit_string(HAL_UART_PORT_0, "Failed to enable GPIO interrupt!\r\n");
        return -1;
    }

    if (hal_interrupt_enable_global() != HAL_INTERRUPT_OK)
    {
        hal_uart_transmit_string(HAL_UART_PORT_0, "Failed to enable global interrupts!\r\n");
        return -1;
    }

    hal_uart_transmit_string(HAL_UART_PORT_0, "GPIO demo started. GPIO0 configured for external interrupt\r\n");
    hal_uart_transmit_string(HAL_UART_PORT_0, "Connect external signal to GPIO0 or simulate with software\r\n");

    // 主循环 - 打印计数器状态
    uint32_t last_print_time = 0;
    while (1)
    {
        // 使用睡眠模式等待中断，节省功耗
        hal_interrupt_sleep();

        // 每1000次循环打印一次当前计数
        if (last_print_time != gpio_interrupt_counter)
        {
            if (gpio_interrupt_counter % 1000 == 0)
            {
                hal_uart_printf(HAL_UART_PORT_0, "Main loop: interrupt count = %d\r\n", gpio_interrupt_counter);
            }
            last_print_time = gpio_interrupt_counter;
        }
    }

    return 0;
}
