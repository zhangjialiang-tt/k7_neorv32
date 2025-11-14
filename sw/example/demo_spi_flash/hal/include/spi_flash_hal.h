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

/**********************************************************************//**
 * @name Configuration Options
 **************************************************************************/
/**@{*/

/** SPI Flash chip select pin (0..7) */
#ifndef SPI_FLASH_HAL_CS
#define SPI_FLASH_HAL_CS 0
#endif

/** SPI Flash clock prescaler */
#ifndef SPI_FLASH_HAL_CLK_PRSC
#define SPI_FLASH_HAL_CLK_PRSC 5  // CLK_PRSC_64
#endif

/** SPI Flash clock divider (0..15) */
#ifndef SPI_FLASH_HAL_CLK_DIV
#define SPI_FLASH_HAL_CLK_DIV 0
#endif

/** SPI Flash base address */
#ifndef SPI_FLASH_HAL_BASE_ADDR
#define SPI_FLASH_HAL_BASE_ADDR 0x00010000//0x00500000
#endif

/** SPI Flash address bytes (1..4) */
#ifndef SPI_FLASH_HAL_ADDR_BYTES
#define SPI_FLASH_HAL_ADDR_BYTES 4
#endif

/** SPI Flash sector size in bytes */
#ifndef SPI_FLASH_HAL_SECTOR_SIZE
#define SPI_FLASH_HAL_SECTOR_SIZE (64*1024)
#endif

/** SPI Flash page size in bytes */
#ifndef SPI_FLASH_HAL_PAGE_SIZE
#define SPI_FLASH_HAL_PAGE_SIZE 256
#endif

/**@}*/

/**********************************************************************//**
 * @name SPI Flash Commands
 **************************************************************************/
/**@{*/

// #define SPI_FLASH_CMD_PAGE_PROGRAM  0x12  // 4字节地址页编程
// #define SPI_FLASH_CMD_READ_DATA     0x13  // 4字节地址读取
#define SPI_FLASH_CMD_READ_DATA             0x03  /**< Read data bytes */
#define SPI_FLASH_CMD_PAGE_PROGRAM          0x02  /**< Program page */
#define SPI_FLASH_CMD_WRITE_ENABLE          0x06  /**< Allow write access */
#define SPI_FLASH_CMD_WRITE_DISABLE         0x04  /**< Disallow write access */
#define SPI_FLASH_CMD_READ_STATUS           0x05  /**< Get status register */
#define SPI_FLASH_CMD_WRITE_STATUS          0x01  /**< Set status register */
#define SPI_FLASH_CMD_FAST_READ             0x0B  /**< Fast read data bytes */
#define SPI_FLASH_CMD_SECTOR_ERASE          0x20  /**< Erase 4KB sector */
#define SPI_FLASH_CMD_BLOCK_ERASE_32K       0x52  /**< Erase 32KB block */
#define SPI_FLASH_CMD_BLOCK_ERASE_64K       0xD8  /**< Erase 64KB block */
#define SPI_FLASH_CMD_CHIP_ERASE            0xC7  /**< Erase entire chip */
#define SPI_FLASH_CMD_READ_ID               0x9F  /**< Read JEDEC ID */
#define SPI_FLASH_CMD_POWER_DOWN            0xB9  /**< Enter power down mode */
#define SPI_FLASH_CMD_WAKE                  0xAB  /**< Wake up from sleep mode */
#define SPI_FLASH_CMD_READ_SFDP             0x5A  /**< Read SFDP parameters */
#define SPI_FLASH_CMD_ENABLE_RESET          0x66  /**< Enable reset */
#define SPI_FLASH_CMD_RESET                 0x99  /**< Reset device */

/**@}*/

/**********************************************************************//**
 * @name SPI Flash Status Register Bits
 **************************************************************************/
/**@{*/

#define SPI_FLASH_SREG_BUSY                 (1 << 0)  /**< Busy, write/erase in progress when set, read-only */
#define SPI_FLASH_SREG_WEL                  (1 << 1)  /**< Write access enabled when set, read-only */
#define SPI_FLASH_SREG_BP0                  (1 << 2)  /**< Block protect bit 0 */
#define SPI_FLASH_SREG_BP1                  (1 << 3)  /**< Block protect bit 1 */
#define SPI_FLASH_SREG_BP2                  (1 << 4)  /**< Block protect bit 2 */
#define SPI_FLASH_SREG_TB                   (1 << 5)  /**< Top/Bottom protect select */
#define SPI_FLASH_SREG_SEC                  (1 << 6)  /**< Sector protect */
#define SPI_FLASH_SREG_SRP0                 (1 << 7)  /**< Status register protect 0 */

/**@}*/

/**********************************************************************//**
 * @name Data Structures
 **************************************************************************/
/**@{*/

/**
 * @brief SPI Flash device information structure
 */
typedef struct {
    uint8_t manufacturer_id;    /**< Manufacturer ID */
    uint8_t memory_type;        /**< Memory type */
    uint8_t capacity;           /**< Device capacity */
    uint32_t total_size;        /**< Total size in bytes */
    uint32_t sector_size;       /**< Sector size in bytes */
    uint32_t page_size;         /**< Page size in bytes */
} spi_flash_info_t;

/**
 * @brief SPI Flash status structure
 */
typedef struct {
    uint8_t status_reg;         /**< Status register value */
    uint8_t busy;               /**< Busy flag (1 if busy) */
    uint8_t write_enabled;      /**< Write enable flag (1 if enabled) */
    uint8_t block_protect;       /**< Block protect level */
} spi_flash_status_t;

/**@}*/

/**********************************************************************//**
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
 * @brief Deinitialize SPI Flash HAL layer
 * 
 * This function disables the SPI interface and puts the flash device
 * into power down mode if supported.
 * 
 * @return 0 on success, non-zero error code on failure
 */
int spi_flash_hal_deinit(void);

/**
 * @brief Read SPI Flash device information
 * 
 * This function reads the JEDEC ID and determines device capabilities.
 * 
 * @param[out] info Pointer to device information structure
 * @return 0 on success, non-zero error code on failure
 */
int spi_flash_hal_read_info(spi_flash_info_t* info);

/**
 * @brief Read SPI Flash status
 * 
 * This function reads the status register and parses it into a structured format.
 * 
 * @param[out] status Pointer to status structure
 * @return 0 on success, non-zero error code on failure
 */
int spi_flash_hal_read_status(spi_flash_status_t* status);

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
int spi_flash_hal_read(uint32_t address, uint8_t* buffer, uint32_t length);

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
int spi_flash_hal_program(uint32_t address, const uint8_t* buffer, uint32_t length);

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
 * @brief Put SPI Flash into power down mode
 * 
 * This function puts the flash device into low power mode.
 * 
 * @return 0 on success, non-zero error code on failure
 */
int spi_flash_hal_power_down(void);

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