// ================================================================================ //
// The NEORV32 RISC-V Processor - https://github.com/stnolting/neorv32              //
// Copyright (c) NEORV32 contributors.                                              //
// Copyright (c) 2020 - 2025 Stephan Nolting. All rights reserved.                  //
// Licensed under the BSD-3-Clause license, see LICENSE for details.                //
// SPDX-License-Identifier: BSD-3-Clause                                            //
// ================================================================================ //

/**
 * @file spi_flash_hal.h
 * @brief SPI Flash HAL (Hardware Abstraction Layer) driver.
 *
 * This module provides a complete hardware abstraction layer for SPI Flash
 * memory devices, including initialization, read, write, erase operations
 * and status monitoring.
 */

#ifndef SPI_FLASH_HAL_H
#define SPI_FLASH_HAL_H

#include <stdint.h>
#include <neorv32.h>

/**************************************************************************
 * @name Configuration Options
 **************************************************************************/
/**@{*/

/** SPI Flash chip select pin (0..7) */
#ifndef SPI_FLASH_HAL_CS
#define SPI_FLASH_HAL_CS 0
#endif

/** SPI Flash clock prescaler */
// fSPI = fmain[Hz] / (2 * clock_prescaler * (1 + SPI_CTRL_CDIVx))
// |**`SPI_CTRL_PRSC[2:0]`**|`0b000`|`0b001`|`0b010`|`0b011`|`0b100`|`0b101`|`0b110`|`0b111`|
// |Resulting `clock_prescaler`|2|4|8|64|128|1024|2048|4096|
#ifndef SPI_FLASH_HAL_CLK_PRSC
#define SPI_FLASH_HAL_CLK_PRSC 2 // CLK_PRSC_8
#endif

/** SPI Flash clock divider (0..15) */
#ifndef SPI_FLASH_HAL_CLK_DIV
#define SPI_FLASH_HAL_CLK_DIV 0
#endif

/** SPI Flash base address */
#ifndef SPI_FLASH_HAL_BASE_ADDR
#define SPI_FLASH_HAL_BASE_ADDR 0x00010000 // 0x00500000
#endif

/** SPI Flash address bytes (1..4) */
#ifndef SPI_FLASH_HAL_ADDR_BYTES
#define SPI_FLASH_HAL_ADDR_BYTES 4
#endif

/** SPI Flash sector size in bytes */
#ifndef SPI_FLASH_HAL_SECTOR_SIZE
#define SPI_FLASH_HAL_SECTOR_SIZE (64 * 1024)
#endif

/** SPI Flash page size in bytes */
#ifndef SPI_FLASH_HAL_PAGE_SIZE
#define SPI_FLASH_HAL_PAGE_SIZE 256
#endif

/**@}*/

/**************************************************************************
 * @name SPI Flash Commands
 **************************************************************************/
/**@{*/

#define SPI_FLASH_CMD_PAGE_PROGRAM_4B 0x12    // 4字节地址页编程
#define SPI_FLASH_CMD_READ_DATA_4B 0x13       // 4字节地址读取
#define SPI_FLASH_CMD_READ_DATA 0x03          /**< Read data bytes */
#define SPI_FLASH_CMD_PAGE_PROGRAM 0x02       /**< Program page */
#define SPI_FLASH_CMD_WRITE_ENABLE 0x06       /**< Allow write access */
#define SPI_FLASH_CMD_WRITE_DISABLE 0x04      /**< Disallow write access */
#define SPI_FLASH_CMD_READ_STATUS 0x05        /**< Get status register */
#define SPI_FLASH_CMD_WRITE_STATUS 0x01       /**< Set status register */
#define SPI_FLASH_CMD_FAST_READ 0x0B          /**< Fast read data bytes */
#define SPI_FLASH_CMD_SECTOR_ERASE 0x20       /**< Erase 4KB sector */
#define SPI_FLASH_CMD_SECTOR_ERASE_4B 0x21    /**< Erase 4KB sector */
#define SPI_FLASH_CMD_BLOCK_ERASE_32K 0x52    /**< Erase 32KB block */
#define SPI_FLASH_CMD_BLOCK_ERASE_64K 0xD8    /**< Erase 64KB block */
#define SPI_FLASH_CMD_BLOCK_ERASE_64K_4B 0xDC /**< Erase 64KB block */
#define SPI_FLASH_CMD_CHIP_ERASE 0xC7         /**< Erase entire chip */
#define SPI_FLASH_CMD_READ_ID 0x9F            /**< Read JEDEC ID */
#define SPI_FLASH_CMD_WAKE 0xAB               /**< Wake up from sleep mode */
#define SPI_FLASH_CMD_READ_SFDP 0x5A          /**< Read SFDP parameters */
#define SPI_FLASH_CMD_RESET 0x99              /**< Reset device */

/**@}*/

/**************************************************************************
 * @name SPI Flash Status Register Bits
 **************************************************************************/
/**@{*/

#define SPI_FLASH_SREG_WIP (1u << 0) /**< WIP：忙（11.5/11.6） */
#define SPI_FLASH_SREG_WEL (1u << 1) /**< WEL：写使能（11.5/11.6） */
#define SPI_FLASH_SREG_BP0 (1u << 2) /**< 保护位 */
#define SPI_FLASH_SREG_BP1 (1u << 3)
#define SPI_FLASH_SREG_BP2 (1u << 4)
#define SPI_FLASH_SREG_E_ERR (1u << 5) /**< 擦除错误（11.6） */
#define SPI_FLASH_SREG_P_ERR (1u << 6) /**< 编程错误（11.5） */
#define SPI_FLASH_SREG_SRP0 (1u << 7)  /**< 状态寄存器保护 */

/**@}*/

/**************************************************************************
 * @name Data Structures
 **************************************************************************/
/**@{*/

/**
 * @brief SPI Flash device information structure
 */
typedef struct
{
    uint8_t manufacturer_id; /**< Manufacturer ID */
    uint8_t memory_type;     /**< Memory type */
    uint8_t capacity;        /**< Device capacity */
    uint32_t total_size;     /**< Total size in bytes */
    uint32_t sector_size;    /**< Sector size in bytes */
    uint32_t page_size;      /**< Page size in bytes */
} spi_flash_info_t;

/**
 * @brief SPI Flash status structure
 */
typedef struct
{
    uint8_t status_reg;    /**< Status register value */
    uint8_t busy;          /**< Busy flag (1 if busy) */
    uint8_t write_enabled; /**< Write enable flag (1 if enabled) */
    uint8_t block_protect; /**< Block protect level */
} spi_flash_status_t;

// 时序参数常量（依据规格最大值，章节：11.5/11.6）
#ifndef SPI_FLASH_HAL_PAGE_PROG_TIMEOUT_MS
#define SPI_FLASH_HAL_PAGE_PROG_TIMEOUT_MS 10
#endif
#ifndef SPI_FLASH_HAL_P4E_TIMEOUT_MS
#define SPI_FLASH_HAL_P4E_TIMEOUT_MS 300
#endif
#ifndef SPI_FLASH_HAL_SE_TIMEOUT_MS
#define SPI_FLASH_HAL_SE_TIMEOUT_MS 1100
#endif
#ifndef SPI_FLASH_HAL_CHIP_ERASE_TIMEOUT_MS
#define SPI_FLASH_HAL_CHIP_ERASE_TIMEOUT_MS 120000
#endif

/**@}*/

/**************************************************************************
 * @name Function Prototypes
 **************************************************************************/
/**@{*/

/**
 * @brief Initialize SPI Flash HAL layer
 *
 * This function initializes the SPI interface and performs basic
 * communication tests with the SPI Flash device.
 *
 * @return 0 on success, non-zero error code on failure
 */
int spi_flash_hal_init(void);

/**
 * @brief Read SPI Flash device information
 *
 * This function reads the JEDEC ID and determines device capabilities.
 *
 * @param[out] info Pointer to device information structure
 * @return 0 on success, non-zero error code on failure
 */
int spi_flash_hal_read_info(spi_flash_info_t *info);

/**
 * @brief Read SPI Flash status
 *
 * This function reads the status register and parses it into a structured format.
 *
 * @param[out] status Pointer to status structure
 * @return 0 on success, non-zero error code on failure
 */
int spi_flash_hal_read_status(spi_flash_status_t *status);

/**
 * @brief Wait until SPI Flash is ready
 *
 * This function polls the status register until the busy bit is cleared.
 *
 * @param timeout_ms Maximum timeout in milliseconds
 * @return 0 on success, non-zero error code on timeout
 */
int spi_flash_hal_wait_ready(uint32_t timeout_ms);

/**
 * @brief Enable write operations
 *
 * This function sends the Write Enable command to the flash device.
 *
 * @return 0 on success, non-zero error code on failure
 */
int spi_flash_hal_write_enable(void);

/**
 * @brief Disable write operations
 *
 * This function sends the Write Disable command to the flash device.
 *
 * @return 0 on success, non-zero error code on failure
 */
int spi_flash_hal_write_disable(void);

/**
 * @brief Read data from SPI Flash
 *
 * This function reads data from the specified address in the flash device.
 *
 * @param address Flash address to read from
 * @param buffer Pointer to data buffer
 * @param length Number of bytes to read
 * @return 0 on success, non-zero error code on failure
 */
int spi_flash_hal_read(uint32_t address, uint8_t *buffer, uint32_t length);

/**
 * @brief Program data to SPI Flash
 *
 * This function programs data to the specified address in the flash device.
 * Note that flash can only change bits from 1 to 0, so erase may be required.
 *
 * @param address Flash address to program to
 * @param buffer Pointer to data buffer
 * @param length Number of bytes to program
 * @return 0 on success, non-zero error code on failure
 */
int spi_flash_hal_program(uint32_t address, const uint8_t *buffer, uint32_t length);

/**
 * @brief Erase sector in SPI Flash
 *
 * This function erases a sector (typically 4KB) at the specified address.
 *
 * @param address Flash address of sector to erase
 * @return 0 on success, non-zero error code on failure
 */
int spi_flash_hal_erase_sector(uint32_t address);

/**
 * @brief Erase block in SPI Flash
 *
 * This function erases a block (32KB or 64KB) at the specified address.
 *
 * @param address Flash address of block to erase
 * @param size Block size (32768 for 32KB, 65536 for 64KB)
 * @return 0 on success, non-zero error code on failure
 */
int spi_flash_hal_erase_block(uint32_t address, uint32_t size);

/**
 * @brief Erase entire SPI Flash chip
 *
 * This function erases the entire flash chip.
 *
 * @return 0 on success, non-zero error code on failure
 */
int spi_flash_hal_erase_chip(void);

/**
 * @brief Wake SPI Flash from power down mode
 *
 * This function wakes the flash device from low power mode.
 *
 * @return 0 on success, non-zero error code on failure
 */
int spi_flash_hal_wake_up(void);

/**
 * @brief Reset SPI Flash device
 *
 * This function performs a software reset of the flash device.
 *
 * @return 0 on success, non-zero error code on failure
 */
int spi_flash_hal_reset(void);

/**@}*/

#endif // SPI_FLASH_HAL_H