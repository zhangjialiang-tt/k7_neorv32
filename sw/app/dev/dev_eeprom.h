/**
 * @file dev_eeprom.h
 * @brief EEPROM device driver interface
 */

#ifndef DEV_EEPROM_H
#define DEV_EEPROM_H

#ifdef __cplusplus
extern "C"
{
#endif

#include <stdint.h>
#include <stdbool.h>
#include "../hal/hal_i2c.h"

    /* ========================================== */
    /*              类型定义与枚举                */
    /* ========================================== */

    /**
     * @brief EEPROM 类型定义
     */
    typedef enum
    {
        DEV_EEPROM_TYPE_24C01,  /**< 1Kbit */
        DEV_EEPROM_TYPE_24C02,  /**< 2Kbit */
        DEV_EEPROM_TYPE_24C04,  /**< 4Kbit */
        DEV_EEPROM_TYPE_24C08,  /**< 8Kbit */
        DEV_EEPROM_TYPE_24C16,  /**< 16Kbit */
        DEV_EEPROM_TYPE_24C32,  /**< 32Kbit */
        DEV_EEPROM_TYPE_24C64,  /**< 64Kbit */
        DEV_EEPROM_TYPE_24C128, /**< 128Kbit */
        DEV_EEPROM_TYPE_24C256 /**< 256Kbit */
        // DEV_EEPROM_TYPE_24C512  /**< 512Kbit */
    } dev_eeprom_type_t;

    /**
     * @brief EEPROM 配置结构体
     */
    typedef struct
    {
        dev_eeprom_type_t type; /**< EEPROM 类型 */
        uint8_t base_address;   /**< 基础I2C地址 */
    } dev_eeprom_config_t;

    /* ========================================== */
    /*                API 函数声明                */
    /* ========================================== */

    /**
     * @brief 向EEPROM写入单个字节
     * @param config: EEPROM配置
     * @param address: EEPROM内部地址
     * @param data: 要写入的数据
     * @return HAL status
     */
    hal_i2c_status_t dev_eeprom_write_byte(const dev_eeprom_config_t *config, uint16_t address, uint8_t data);

    /**
     * @brief 从EEPROM读取单个字节
     * @param config: EEPROM配置
     * @param address: EEPROM内部地址
     * @param data: 读取数据的指针
     * @return HAL status
     */
    hal_i2c_status_t dev_eeprom_read_byte(const dev_eeprom_config_t *config, uint16_t address, uint8_t *data);

    /**
     * @brief 向EEPROM写入多个字节
     * @param config: EEPROM配置
     * @param address: EEPROM内部地址
     * @param data: 要写入的数据缓冲区
     * @param length: 数据长度
     * @return HAL status
     */
    hal_i2c_status_t dev_eeprom_write_buffer(const dev_eeprom_config_t *config, uint16_t address,
                                             const uint8_t *data, uint16_t length);

    /**
     * @brief 从EEPROM读取多个字节
     * @param config: EEPROM配置
     * @param address: EEPROM内部地址
     * @param data: 读取数据的缓冲区
     * @param length: 数据长度
     * @return HAL status
     */
    hal_i2c_status_t dev_eeprom_read_buffer(const dev_eeprom_config_t *config, uint16_t address,
                                            uint8_t *data, uint16_t length);

#ifdef __cplusplus
}
#endif

#endif /* DEV_EEPROM_H */
