#include "hal/hal_i2c.h"
#include "hal/hal_uart.h"
#include <stdio.h>
#define HAL_TWI_EEPROM_DEVICE_ADDR 0b1010000 // 0x50
int main(void)
{
    // 初始化 UART 用于调试
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

    hal_uart_transmit_string(HAL_UART_PORT_0, "I2C EEPROM Test Started\r\n");

    // 检查 I2C 是否可用
    if (!hal_i2c_is_available())
    {
        hal_uart_transmit_string(HAL_UART_PORT_0, "I2C not available!\r\n");
        return -1;
    }

    // 初始化 I2C (使用标准速度)
    hal_i2c_config_t i2c_config = {
        .speed = HAL_I2C_SPEED_STANDARD,
        .addr_mode = HAL_I2C_ADDR_7BIT,
        .clock_stretch = false,
        .slave_addr = 0x00};

    if (hal_i2c_init(&i2c_config) != HAL_I2C_OK)
    {
        hal_uart_transmit_string(HAL_UART_PORT_0, "Failed to initialize I2C!\r\n");
        return -1;
    }

    if (hal_i2c_enable() != HAL_I2C_OK)
    {
        hal_uart_transmit_string(HAL_UART_PORT_0, "Failed to enable I2C!\r\n");
        return -1;
    }

    hal_uart_transmit_string(HAL_UART_PORT_0, "I2C initialized successfully\r\n");

    // 扫描 I2C 总线上的设备
    hal_uart_transmit_string(HAL_UART_PORT_0, "Scanning I2C bus...\r\n");

    uint8_t found_devices[32] = {0};
    int device_count = hal_i2c_bus_scan(found_devices, 32);

    hal_uart_printf(HAL_UART_PORT_0, "Found %d device(s) on I2C bus\r\n", device_count);

    // 显示找到的设备
    for (int i = 0; i < device_count && i < 32; i++)
    {
        hal_uart_printf(HAL_UART_PORT_0, " + Device found at address 0x%02X\r\n", found_devices[i]);
    }

    // 测试EEPROM操作
    bool eeprom_found = true;
    uint8_t eeprom_base_addr = 0x50;

    // 查找EEPROM设备
    // for (int i = 0; i < device_count; i++)
    // {
    //     if (found_devices[i] >= 0x50 && found_devices[i] <= 0x57)
    //     {
    //         eeprom_base_addr = found_devices[i];
    //         eeprom_found = true;
    //         hal_uart_printf(HAL_UART_PORT_0, "EEPROM device detected at base address 0x%02X\r\n", eeprom_base_addr);
    //         break;
    //     }
    // }

    if (eeprom_found)
    {
        hal_uart_transmit_string(HAL_UART_PORT_0, "Testing EEPROM read/write operations...\r\n");

        // 测试地址
        uint16_t test_addr = 0x0000;
        uint8_t test_data = 0xAB;
        uint8_t read_data = 0x00;

        // 写入数据
        hal_uart_printf(HAL_UART_PORT_0, "Writing 0x%02X to EEPROM address 0x%04X\r\n", test_data, test_addr);

        hal_i2c_status_t write_result = hal_i2c_eeprom_write_byte(eeprom_base_addr, test_addr, test_data);

        if (write_result == HAL_I2C_OK)
        {
            hal_uart_transmit_string(HAL_UART_PORT_0, "Data written successfully\r\n");

            // 等待写入完成
            hal_i2c_delay_ms(20);

            // 读取数据
            hal_uart_printf(HAL_UART_PORT_0, "Reading from EEPROM address 0x%04X\r\n", test_addr);

            hal_i2c_status_t read_result = hal_i2c_eeprom_read_byte(eeprom_base_addr, test_addr, &read_data);

            if (read_result == HAL_I2C_OK)
            {
                hal_uart_printf(HAL_UART_PORT_0, "Data read successfully: 0x%02X\r\n", read_data);
                if (read_data == test_data)
                {
                    hal_uart_transmit_string(HAL_UART_PORT_0, "EEPROM read/write test PASSED\r\n");
                }
                else
                {
                    hal_uart_transmit_string(HAL_UART_PORT_0, "EEPROM read/write test FAILED - data mismatch\r\n");
                    hal_uart_printf(HAL_UART_PORT_0, "Expected: 0x%02X, Got: 0x%02X\r\n", test_data, read_data);
                }
            }
            else
            {
                hal_uart_transmit_string(HAL_UART_PORT_0, "Failed to read from EEPROM\r\n");
                hal_uart_printf(HAL_UART_PORT_0, "Read error code: %d\r\n", read_result);
            }
        }
        else
        {
            hal_uart_transmit_string(HAL_UART_PORT_0, "Failed to write to EEPROM\r\n");
            hal_uart_printf(HAL_UART_PORT_0, "Write error code: %d\r\n", write_result);
        }
    }
    else
    {
        hal_uart_transmit_string(HAL_UART_PORT_0, "No EEPROM device found\r\n");
    }

    hal_uart_transmit_string(HAL_UART_PORT_0, "I2C EEPROM test completed\r\n");

    while (1)
    {
        // 主循环
        hal_i2c_delay_ms(1000); // 1秒延时
    }

    return 0;
}
