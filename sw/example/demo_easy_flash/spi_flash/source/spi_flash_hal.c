// ================================================================================ //
// The NEORV32 RISC-V Processor - https://github.com/stnolting/neorv32              //
// Copyright (c) NEORV32 contributors.                                              //
// Copyright (c) 2020 - 2025 Stephan Nolting. All rights reserved.                  //
// Licensed under the BSD-3-Clause license, see LICENSE for details.                //
// SPDX-License-Identifier: BSD-3-Clause                                            //
// ================================================================================ //

/**
 * @file spi_flash_hal.c
 * @brief SPI Flash HAL (Hardware Abstraction Layer) driver implementation.
 */

#include "spi_flash_hal.h"
#include <neorv32.h>

/**********************************************************************//**
 * @name Helper Functions
 **************************************************************************/
/**@{*/

/**
 * @brief Send single command to SPI flash.
 * 
 * @param cmd Command byte.
 * @return 0 on success, non-zero error code on failure
 */
static int spi_flash_hal_send_cmd(uint8_t cmd) {
    if (!neorv32_spi_available()) {
        return -1;
    }
    
    neorv32_spi_cs_en(SPI_FLASH_HAL_CS);
    neorv32_spi_transfer(cmd);
    neorv32_spi_cs_dis();
    
    return 0;
}

/**
 * @brief Send address to flash.
 * 
 * @param address Flash address
 */
static void spi_flash_hal_send_addr(uint32_t address) {
    subwords32_t addr;
    addr.uint32 = address;

#if (SPI_FLASH_HAL_ADDR_BYTES == 1)
    neorv32_spi_transfer(addr.uint8[0]);
#elif (SPI_FLASH_HAL_ADDR_BYTES == 2)
    neorv32_spi_transfer(addr.uint8[1]);
    neorv32_spi_transfer(addr.uint8[0]);
#elif (SPI_FLASH_HAL_ADDR_BYTES == 3)
    neorv32_spi_transfer(addr.uint8[2]);
    neorv32_spi_transfer(addr.uint8[1]);
    neorv32_spi_transfer(addr.uint8[0]);
#elif (SPI_FLASH_HAL_ADDR_BYTES == 4)
    // neorv32_spi_transfer((address >> 24) & 0xFF);
    // neorv32_spi_transfer((address >> 16) & 0xFF);
    // neorv32_spi_transfer((address >> 8) & 0xFF);
    // neorv32_spi_transfer(address & 0xFF);
    neorv32_spi_transfer(addr.uint8[3]);
    neorv32_spi_transfer(addr.uint8[2]);
    neorv32_spi_transfer(addr.uint8[1]);
    neorv32_spi_transfer(addr.uint8[0]);
#else
    #error "Invalid SPI_FLASH_HAL_ADDR_BYTES configuration!"
#endif
}
// spi_flash_hal.c -> 在 spi_flash_hal_read_status_reg 后面添加

/**
 * @brief Read flash bank address register.
 * 
 * @return SPI flash bank address register value
 */
// static uint8_t spi_flash_hal_read_bank_addr_reg(void) {
//     if (!neorv32_spi_available()) {
//         return 0xFF; // 返回错误值
//     }
    
//     neorv32_spi_cs_en(SPI_FLASH_HAL_CS);
//     neorv32_spi_transfer(0x16); // Bank Register Read (BRRD) command
//     uint8_t res = neorv32_spi_transfer(0);
//     neorv32_spi_cs_dis();
    
//     return res;
// }
/**
 * @brief Read flash status register.
 * 
 * @return SPI flash status register value
 */
static uint8_t spi_flash_hal_read_status_reg(void) {
    if (!neorv32_spi_available()) {
        return 0xFF;
    }
    
    neorv32_spi_cs_en(SPI_FLASH_HAL_CS);
    neorv32_spi_transfer(SPI_FLASH_CMD_READ_STATUS);
    uint8_t res = neorv32_spi_transfer(0);
    // uint8_t res2 = neorv32_spi_transfer(0);
    neorv32_spi_cs_dis();


    
    return res;
}

/**
 * @brief Calculate timeout based on system clock.
 * 
 * @param timeout_ms Timeout in milliseconds
 * @return Timeout counter value
 */
static uint32_t spi_flash_hal_calculate_timeout(uint32_t timeout_ms) {
    // Approximate timeout based on system clock frequency
    // This is a rough calculation and may need adjustment
    uint32_t sys_freq = neorv32_sysinfo_get_clk();
    return (sys_freq / 1000) * timeout_ms;
}

/**@}*/

/**********************************************************************//**
 * @name HAL Interface Functions
 **************************************************************************/
/**@{*/

/**********************************************************************//**
 * @brief Initialize SPI Flash HAL layer
 **************************************************************************/
int spi_flash_hal_init(void) {
    // Check if SPI module is available
    if (!neorv32_spi_available()) {
        return -1;
    }
    
    // Setup SPI, clock mode 0
    neorv32_spi_setup(SPI_FLASH_HAL_CLK_PRSC, SPI_FLASH_HAL_CLK_DIV, 0, 0);
    
    // enable SPI module
    neorv32_spi_enable();
    // Wake up the flash device in case it's in power down mode
    spi_flash_hal_wake_up();

    // ==================== 完整的4字节地址模式切换代码 ====================
    // 步骤 1: 发送写使能 (WREN)，为修改配置寄存器做准备

    
    if (spi_flash_hal_write_enable() != 0) {
        return -3;
    }
    // 等待一小段时间，确保命令被处理
    for (volatile int i = 0; i < 100; i++);

    // 步骤 2: 发送写银行地址寄存器 (WRAR, 0x17) 命令，
    //          并通过发送数据 0x80 来设置 EXTADD 位。
    neorv32_spi_cs_en(SPI_FLASH_HAL_CS);
    neorv32_spi_transfer(0x17); // WRAR command
    neorv32_spi_transfer(0x80); // Data to set EXTADD=1
    neorv32_spi_cs_dis();
    
    spi_flash_hal_wait_ready(100);
    // neorv32_uart0_printf("[HAL_INIT] Waiting for register write to complete...\n");
    // if (spi_flash_hal_wait_ready(100) != 0) { // 100ms timeout for register write
        // neorv32_uart0_printf("[HAL_INIT] Timeout waiting for WIP to clear after BRWR!\n");
        // 即使超时也继续，看看寄存器的值
    // }

    // 步骤 3: 读回银行地址寄存器进行验证
    // neorv32_uart0_printf("[HAL_INIT] Reading back Bank Address Register...\n");
    // uint8_t bank_reg_after = spi_flash_hal_read_bank_addr_reg();
    // neorv32_uart0_printf("[HAL_INIT] BAR value after write: 0x%x\n", bank_reg_after);

    // 检查EXTADD位是否真的被设置了
    // if ((bank_reg_after & 0x80) == 0) {
    //     neorv32_uart0_printf("[HAL_INIT] CRITICAL ERROR: Failed to set EXTADD bit! 4-byte mode is NOT active.\n");
    //     // 暂时不返回错误，让测试继续失败，以收集更多信息
    // } else {
    //     neorv32_uart0_printf("[HAL_INIT] SUCCESS: EXTADD bit is set. 4-byte mode should be active.\n");
    // }



    // Test basic communication by reading JEDEC ID
    spi_flash_info_t info;
    if (spi_flash_hal_read_info(&info) != 0) {
        return -2;
    }
    
    return 0;
}

/**********************************************************************//**
 * @brief Deinitialize SPI Flash HAL layer
 **************************************************************************/
int spi_flash_hal_deinit(void) {
    // Put flash into power down mode
    spi_flash_hal_power_down();
    
    return 0;
}

/**********************************************************************//**
 * @brief Read SPI Flash device information
 **************************************************************************/
int spi_flash_hal_read_info(spi_flash_info_t* info) {
    if (!info) {
        return -1;
    }
    
    if (!neorv32_spi_available()) {
        return -2;
    }
    
    neorv32_spi_cs_en(SPI_FLASH_HAL_CS);
    
    // Send Read ID command
    neorv32_spi_transfer(SPI_FLASH_CMD_READ_ID);
    
    // Read manufacturer ID
    info->manufacturer_id = neorv32_spi_transfer(0);
    
    // Read memory type
    info->memory_type = neorv32_spi_transfer(0);
    
    // Read capacity
    info->capacity = neorv32_spi_transfer(0);
    
    neorv32_spi_cs_dis();
    
    // Calculate total size based on capacity code
    // Common capacity codes (may vary by manufacturer)
    if (info->capacity <= 0x31) {
        info->total_size = 1UL << info->capacity;
    } else {
        // Default to 4MB if unknown capacity
        info->total_size = 4UL * 1024UL * 1024UL;
    }
    
    // Set standard sector and page sizes
    info->sector_size = SPI_FLASH_HAL_SECTOR_SIZE;
    info->page_size = SPI_FLASH_HAL_PAGE_SIZE;
    
    return 0;
}

/**********************************************************************//**
 * @brief Read SPI Flash status
 **************************************************************************/
int spi_flash_hal_read_status(spi_flash_status_t* status) {
    if (!status) {
        return -1;
    }
    
    status->status_reg = spi_flash_hal_read_status_reg();
    status->busy = (status->status_reg & SPI_FLASH_SREG_BUSY) ? 1 : 0;
    status->write_enabled = (status->status_reg & SPI_FLASH_SREG_WEL) ? 1 : 0;
    status->block_protect = (status->status_reg >> 2) & 0x07;
    
    return 0;
}

/**********************************************************************//**
 * @brief Wait until SPI Flash is ready
 **************************************************************************/
int spi_flash_hal_wait_ready(uint32_t timeout_ms) {
    uint32_t timeout_counter = spi_flash_hal_calculate_timeout(timeout_ms);
    
    while (timeout_counter--) {
        if ((spi_flash_hal_read_status_reg() & SPI_FLASH_SREG_BUSY) == 0) {
            return 0;
        }
    }
    
    return -1; // Timeout
}

/**********************************************************************//**
 * @brief Enable write operations
 **************************************************************************/
int spi_flash_hal_write_enable(void) {
    if (spi_flash_hal_send_cmd(SPI_FLASH_CMD_WRITE_ENABLE) != 0) {
        return -1;
    }
    
    // Verify that write is enabled
    if ((spi_flash_hal_read_status_reg() & SPI_FLASH_SREG_WEL) == 0) {
        return -2;
    }
    
    return 0;
}

/**********************************************************************//**
 * @brief Disable write operations
 **************************************************************************/
int spi_flash_hal_write_disable(void) {
    if (spi_flash_hal_send_cmd(SPI_FLASH_CMD_WRITE_DISABLE) != 0) {
        return -1;
    }
    
    // Verify that write is disabled
    if ((spi_flash_hal_read_status_reg() & SPI_FLASH_SREG_WEL) != 0) {
        return -2;
    }
    
    return 0;
}

/**********************************************************************//**
 * @brief Read data from SPI Flash
 **************************************************************************/
int spi_flash_hal_read(uint32_t address, uint8_t* buffer, uint32_t length) {
    if (!buffer || length == 0) {
        return -1;
    }
    
    if (!neorv32_spi_available()) {
        return -2;
    }
    
    neorv32_spi_cs_en(SPI_FLASH_HAL_CS);
    
    // Send Read Data command
    neorv32_spi_transfer(SPI_FLASH_CMD_READ_DATA);
    
    // Send address
    spi_flash_hal_send_addr(address);
    
    // Read data
    for (uint32_t i = 0; i < length; i++) {
        buffer[i] = neorv32_spi_transfer(0);
    }
    
    neorv32_spi_cs_dis();
    
    return 0;
}

/**********************************************************************//**
 * @brief Program data to SPI Flash
 **************************************************************************/
int spi_flash_hal_program(uint32_t address, const uint8_t* buffer, uint32_t length) {
    if (!buffer || length == 0) {
        return -1;
    }
    
    if (!neorv32_spi_available()) {
        return -2;
    }
    
    uint32_t bytes_written = 0;
    
    while (bytes_written < length) {
        // Calculate remaining bytes in current page
        uint32_t page_offset = address % SPI_FLASH_HAL_PAGE_SIZE;
        uint32_t page_space = SPI_FLASH_HAL_PAGE_SIZE - page_offset;
        uint32_t chunk_size = (length - bytes_written < page_space) ? 
                             (length - bytes_written) : page_space;
        
        // Enable write
        if (spi_flash_hal_write_enable() != 0) {
            return -3;
        }
        
        neorv32_spi_cs_en(SPI_FLASH_HAL_CS);
        
        // Send Page Program command
        neorv32_spi_transfer(SPI_FLASH_CMD_PAGE_PROGRAM);
        
        // Send address
        spi_flash_hal_send_addr(address);
        
        // Send data
        for (uint32_t i = 0; i < chunk_size; i++) {
            neorv32_spi_transfer(buffer[bytes_written + i]);
        }
        
        neorv32_spi_cs_dis();
        
        // Wait for programming to complete
        if (spi_flash_hal_wait_ready(1000) != 0) {
            return -4; // Timeout
        }
        
        // Update counters
        address += chunk_size;
        bytes_written += chunk_size;
    }
    
    return 0;
}

/**********************************************************************//**
 * @brief Erase sector in SPI Flash
 **************************************************************************/
int spi_flash_hal_erase_sector(uint32_t address) {
    if (!neorv32_spi_available()) {
        return -1;
    }
    
    // Enable write
    if (spi_flash_hal_write_enable() != 0) {
        return -2;
    }
    
    neorv32_spi_cs_en(SPI_FLASH_HAL_CS);
    
    // Send Sector Erase command
    neorv32_spi_transfer(SPI_FLASH_CMD_SECTOR_ERASE);
    
    // Send address
    spi_flash_hal_send_addr(address);
    
    neorv32_spi_cs_dis();
    
    // Wait for erase to complete
    if (spi_flash_hal_wait_ready(10000) != 0) {
        return -3; // Timeout
    }
    
    return 0;
}

/**********************************************************************//**
 * @brief Erase block in SPI Flash
 **************************************************************************/
int spi_flash_hal_erase_block(uint32_t address, uint32_t size) {
    if (!neorv32_spi_available()) {
        return -1;
    }
    
    uint8_t cmd;
    if (size == 32768) {
        cmd = SPI_FLASH_CMD_BLOCK_ERASE_32K;
    } else if (size == 65536) {
        cmd = SPI_FLASH_CMD_BLOCK_ERASE_64K;
    } else {
        return -2; // Invalid block size
    }
    
    // Enable write
    if (spi_flash_hal_write_enable() != 0) {
        return -3;
    }
    
    neorv32_spi_cs_en(SPI_FLASH_HAL_CS);
    
    // Send Block Erase command
    neorv32_spi_transfer(cmd);
    
    // Send address
    spi_flash_hal_send_addr(address);
    
    neorv32_spi_cs_dis();
    
    // Wait for erase to complete
    if (spi_flash_hal_wait_ready(10000) != 0) {
        return -4; // Timeout
    }
    
    return 0;
}

/**********************************************************************//**
 * @brief Erase entire SPI Flash chip
 **************************************************************************/
int spi_flash_hal_erase_chip(void) {
    if (!neorv32_spi_available()) {
        return -1;
    }
    
    // Enable write
    if (spi_flash_hal_write_enable() != 0) {
        return -2;
    }
    
    // Send Chip Erase command
    if (spi_flash_hal_send_cmd(SPI_FLASH_CMD_CHIP_ERASE) != 0) {
        return -3;
    }
    
    // Wait for erase to complete (this can take a long time)
    if (spi_flash_hal_wait_ready(60000) != 0) {
        return -4; // Timeout
    }
    
    return 0;
}

/**********************************************************************//**
 * @brief Put SPI Flash into power down mode
 **************************************************************************/
int spi_flash_hal_power_down(void) {
    return spi_flash_hal_send_cmd(SPI_FLASH_CMD_POWER_DOWN);
}

/**********************************************************************//**
 * @brief Wake SPI Flash from power down mode
 **************************************************************************/
int spi_flash_hal_wake_up(void) {
    return spi_flash_hal_send_cmd(SPI_FLASH_CMD_WAKE);
}

/**********************************************************************//**
 * @brief Reset SPI Flash device
 **************************************************************************/
int spi_flash_hal_reset(void) {
    if (!neorv32_spi_available()) {
        return -1;
    }
    
    // Enable reset
    if (spi_flash_hal_send_cmd(SPI_FLASH_CMD_ENABLE_RESET) != 0) {
        return -2;
    }
    
    // Send reset command
    if (spi_flash_hal_send_cmd(SPI_FLASH_CMD_RESET) != 0) {
        return -3;
    }
    
    // Wait for reset to complete
    if (spi_flash_hal_wait_ready(1000) != 0) {
        return -4; // Timeout
    }
    
    return 0;
}

/**@}*/