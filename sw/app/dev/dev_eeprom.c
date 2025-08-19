/**
 * @file dev_eeprom.c
 * @brief EEPROM device driver implementation
 */

#include "../hal/hal_i2c.h"
#include "dev_eeprom.h"
#include "../app/app_uart.h"
#include "../../lib/include/neorv32_uart.h" // 引入底层 BSP 接口
#include "../../lib/include/neorv32.h" 
#include <string.h>
#include <stdlib.h>
/* ========================================== */
/*              私有函数声明                  */
/* ========================================== */

static uint8_t dev_eeprom_get_device_address(const dev_eeprom_config_t *config, uint16_t mem_address);
static void dev_eeprom_delay_ms(uint32_t ms);
static hal_i2c_status_t dev_eeprom_i2c_init_once(void);

/* ========================================== */
/*              私有数据结构                  */
/* ========================================== */

// EEPROM设备规格表
static const struct
{
    uint16_t page_size;
    uint16_t total_size;
    uint8_t addr_bits;
} eeprom_specs[] = {
    [DEV_EEPROM_TYPE_24C01] = {8, 128, 7},
    [DEV_EEPROM_TYPE_24C02] = {8, 256, 8},
    [DEV_EEPROM_TYPE_24C04] = {16, 512, 9},
    [DEV_EEPROM_TYPE_24C08] = {16, 1024, 10},
    [DEV_EEPROM_TYPE_24C16] = {16, 2048, 11},
    [DEV_EEPROM_TYPE_24C32] = {32, 4096, 12},
    [DEV_EEPROM_TYPE_24C64] = {32, 8192, 13},
    [DEV_EEPROM_TYPE_24C128] = {64, 16384, 14},
    [DEV_EEPROM_TYPE_24C256] = {64, 32768, 15}};

// I2C 初始化标志
static bool is_i2c_initialized = false;

/* ========================================== */
/*                 API 实现                   */
/* ========================================== */

hal_i2c_status_t dev_eeprom_write_byte(const dev_eeprom_config_t *config, uint16_t address, uint8_t data)
{
    neorv32_uart0_printf("ENTERED dev_eeprom_write_byte function\r\n");
    if (config == NULL)
    {
        return HAL_I2C_ERROR;
    }

    // 自动初始化 I2C（只执行一次）
    hal_i2c_status_t init_result = dev_eeprom_i2c_init_once();
    if (init_result != HAL_I2C_OK)
    {
        return init_result;
    }

    // 检查地址范围
    if (address >= eeprom_specs[config->type].total_size)
    {
        return HAL_I2C_ERROR;
    }

    uint8_t device_addr = dev_eeprom_get_device_address(config, address);

    // 构造发送数据：地址 + 数据
    uint8_t write_buffer[3];
    uint8_t addr_len = (eeprom_specs[config->type].total_size > 256) ? 2 : 1;

    if (addr_len == 2)
    {
        write_buffer[0] = (address >> 8) & 0xFF;
        write_buffer[1] = address & 0xFF;
    }
    else
    {
        write_buffer[0] = address & 0xFF;
    }
    write_buffer[addr_len] = data;

    hal_i2c_status_t result = hal_i2c_master_write(device_addr, write_buffer, addr_len + 1, 100);

    if (result == HAL_I2C_OK)
    {
        dev_eeprom_delay_ms(5); // 等待写入完成
    }

    return result;
}

hal_i2c_status_t dev_eeprom_read_byte(const dev_eeprom_config_t *config, uint16_t address, uint8_t *data)
{
    if (config == NULL || data == NULL)
    {
        return HAL_I2C_ERROR;
    }

    // 自动初始化 I2C（只执行一次）
    hal_i2c_status_t init_result = dev_eeprom_i2c_init_once();
    if (init_result != HAL_I2C_OK)
    {
        return init_result;
    }

    // 检查地址范围
    if (address >= eeprom_specs[config->type].total_size)
    {
        return HAL_I2C_ERROR;
    }

    uint8_t device_addr = dev_eeprom_get_device_address(config, address);
    uint8_t mem_addr_bytes[2];
    uint8_t addr_len = (eeprom_specs[config->type].total_size > 256) ? 2 : 1;

    if (addr_len == 2)
    {
        mem_addr_bytes[0] = (address >> 8) & 0xFF;
        mem_addr_bytes[1] = address & 0xFF;
    }
    else
    {
        mem_addr_bytes[0] = address & 0xFF;
    }

    // 使用I2C写读操作
    return hal_i2c_master_write_read(device_addr,
                                     mem_addr_bytes, addr_len,
                                     data, 1, 100);
}

hal_i2c_status_t dev_eeprom_write_buffer(const dev_eeprom_config_t *config, uint16_t address,
                                         const uint8_t *data, uint16_t length)
{
    if (config == NULL || data == NULL)
    {
        return HAL_I2C_ERROR;
    }

    // 自动初始化 I2C（只执行一次）
    hal_i2c_status_t init_result = dev_eeprom_i2c_init_once();
    if (init_result != HAL_I2C_OK)
    {
        return init_result;
    }

    // 检查地址范围
    if (address >= eeprom_specs[config->type].total_size ||
        (address + length) > eeprom_specs[config->type].total_size)
    {
        return HAL_I2C_ERROR;
    }

    uint8_t device_addr = dev_eeprom_get_device_address(config, address);

    // 构造发送数据：地址 + 数据
    uint8_t *buffer = (uint8_t *)malloc(length + 2); // +2 for max address bytes
    if (buffer == NULL)
    {
        return HAL_I2C_ERROR;
    }

    uint8_t addr_len = (eeprom_specs[config->type].total_size > 256) ? 2 : 1;

    if (addr_len == 2)
    {
        buffer[0] = (address >> 8) & 0xFF;
        buffer[1] = address & 0xFF;
    }
    else
    {
        buffer[0] = address & 0xFF;
    }

    memcpy(buffer + addr_len, data, length);

    hal_i2c_status_t result = hal_i2c_master_write(device_addr, buffer, addr_len + length, 1000);

    free(buffer);

    if (result == HAL_I2C_OK)
    {
        dev_eeprom_delay_ms(5); // 等待写入完成
    }

    return result;
}

hal_i2c_status_t dev_eeprom_read_buffer(const dev_eeprom_config_t *config, uint16_t address,
                                        uint8_t *data, uint16_t length)
{
    if (config == NULL || data == NULL)
    {
        return HAL_I2C_ERROR;
    }

    // 自动初始化 I2C（只执行一次）
    hal_i2c_status_t init_result = dev_eeprom_i2c_init_once();
    if (init_result != HAL_I2C_OK)
    {
        return init_result;
    }

    // 检查地址范围
    if (address >= eeprom_specs[config->type].total_size ||
        (address + length) > eeprom_specs[config->type].total_size)
    {
        return HAL_I2C_ERROR;
    }

    uint8_t device_addr = dev_eeprom_get_device_address(config, address);
    uint8_t mem_addr_bytes[2];
    uint8_t addr_len = (eeprom_specs[config->type].total_size > 256) ? 2 : 1;

    if (addr_len == 2)
    {
        mem_addr_bytes[0] = (address >> 8) & 0xFF;
        mem_addr_bytes[1] = address & 0xFF;
    }
    else
    {
        mem_addr_bytes[0] = address & 0xFF;
    }

    return hal_i2c_master_write_read(device_addr,
                                     mem_addr_bytes, addr_len,
                                     data, length, 1000);
}

/* ========================================== */
/*              私有函数实现                  */
/* ========================================== */

static uint8_t dev_eeprom_get_device_address(const dev_eeprom_config_t *config, uint16_t mem_address)
{
    uint8_t base_addr = config->base_address;

    // 根据不同EEPROM类型计算设备地址
    switch (config->type)
    {
    case DEV_EEPROM_TYPE_24C04:
        // AT24C04特殊寻址：A9,A8位移到设备地址的A2,A1位
        return base_addr | ((mem_address >> 7) & 0x06);

    case DEV_EEPROM_TYPE_24C08:
    case DEV_EEPROM_TYPE_24C16:
        // A10,A9,A8位移到设备地址
        return base_addr | ((mem_address >> 8) & 0x07);

    default:
        // 其他类型使用固定地址
        neorv32_uart0_printf("Unsupported EEPROM type: %x\r\n",base_addr);
        return base_addr;
    }
}

static void dev_eeprom_delay_ms(uint32_t ms)
{
    hal_i2c_delay_ms(ms);
}

/**
 * @brief EEPROM模块内部初始化 I2C，只执行一次
 */
static hal_i2c_status_t dev_eeprom_i2c_init_once(void)
{
    if (is_i2c_initialized)
    {
        return HAL_I2C_OK;
    }

    // 检查 I2C 是否可用
    neorv32_uart0_printf("Checking TWI availability...\r\n");
    if (!hal_i2c_is_available())
    {
        neorv32_uart0_printf("function dev_eeprom_i2c_init_once : I2C unavailable\r\n");
        return HAL_I2C_NOT_AVAIL;
    }
    neorv32_uart0_printf("TWI is available\r\n");

    // 初始化 I2C
    hal_i2c_config_t i2c_config = {
        .speed = HAL_I2C_SPEED_STANDARD,
        .addr_mode = HAL_I2C_ADDR_7BIT,
        .clock_stretch = false,
        .slave_addr = 0x00};

    hal_i2c_status_t result = hal_i2c_init(&i2c_config);
    if (result != HAL_I2C_OK)
    {
        neorv32_uart0_printf("I2C init failed: %d\r\n", result);
        return result;
    }

    result = hal_i2c_enable();
    if (result != HAL_I2C_OK)
    {
        neorv32_uart0_printf("I2C enable failed: %d\r\n", result);
        return result;
    }

    is_i2c_initialized = true;
    neorv32_uart0_printf("function dev_eeprom_i2c_init_once : I2C available %d\r\n", is_i2c_initialized);
    return HAL_I2C_OK;
}
