// ================================================================================ //
// The NEORV32 RISC-V Processor - https://github.com/stnolting/neorv32              //
// Copyright (c) NEORV32 contributors.                                              //
// Copyright (c) 2020 - 2025 Stephan Nolting. All rights reserved.                  //
// Licensed under the BSD-3-Clause license, see LICENSE for details.                //
// SPDX-License-Identifier: BSD-3-Clause                                            //
// ================================================================================ //

/**********************************************************************//**
 * @file spi_flash_hal_test_fixed.c
 * @brief SPI Flash HAL test program with fixes for erase issues.
 * @author NEORV32 User
 **************************************************************************/

#include <neorv32.h>
#include "../hal/include/spi_flash_hal.h"

/**********************************************************************//**
 * @name User configuration
 **************************************************************************/
/**@{*/
/** UART BAUD rate */
#define BAUD_RATE 19200
/** Test data buffer size */
#define TEST_BUFFER_SIZE 256
/** Test flash address - using different address */
#define TEST_FLASH_ADDR 0x00100000  // Changed from 0x00100000
/**@}*/

/**********************************************************************//**
 * @name Test data
 **************************************************************************/
/**@{*/

/** Test pattern for write/read verification */
static const uint8_t test_pattern[TEST_BUFFER_SIZE] = {
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F,
    0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F,
    0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2A, 0x2B, 0x2C, 0x2D, 0x2E, 0x2F,
    0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3A, 0x3B, 0x3C, 0x3D, 0x3E, 0x3F,
    0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x4B, 0x4C, 0x4D, 0x4E, 0x4F,
    0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5A, 0x5B, 0x5C, 0x5D, 0x5E, 0x5F,
    0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6A, 0x6B, 0x6C, 0x6D, 0x6E, 0x6F,
    0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7A, 0x7B, 0x7C, 0x7D, 0x7E, 0x7F,
    0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89, 0x8A, 0x8B, 0x8C, 0x8D, 0x8E, 0x8F,
    0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9A, 0x9B, 0x9C, 0x9D, 0x9E, 0x9F,
    0xA0, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5, 0xA6, 0xA7, 0xA8, 0xA9, 0xAA, 0xAB, 0xAC, 0xAD, 0xAE, 0xAF,
    0xB0, 0xB1, 0xB2, 0xB3, 0xB4, 0xB5, 0xB6, 0xB7, 0xB8, 0xB9, 0xBA, 0xBB, 0xBC, 0xBD, 0xBE, 0xBF,
    0xC0, 0xC1, 0xC2, 0xC3, 0xC4, 0xC5, 0xC6, 0xC7, 0xC8, 0xC9, 0xCA, 0xCB, 0xCC, 0xCD, 0xCE, 0xCF,
    0xD0, 0xD1, 0xD2, 0xD3, 0xD4, 0xD5, 0xD6, 0xD7, 0xD8, 0xD9, 0xDA, 0xDB, 0xDC, 0xDD, 0xDE, 0xDF,
    0xE0, 0xE1, 0xE2, 0xE3, 0xE4, 0xE5, 0xE6, 0xE7, 0xE8, 0xE9, 0xEA, 0xEB, 0xEC, 0xED, 0xEE, 0xEF,
    0xF0, 0xF1, 0xF2, 0xF3, 0xF4, 0xF5, 0xF6, 0xF7, 0xF8, 0xF9, 0xFA, 0xFB, 0xFC, 0xFD, 0xFE, 0xFF
};

/** Read buffer for verification */
static uint8_t read_buffer[TEST_BUFFER_SIZE];

/**@}*/

/**********************************************************************//**
 * @name Helper Functions
 **************************************************************************/
/**@{*/

/**********************************************************************//**
 * @brief Print test result
 **************************************************************************/
void print_test_result(const char* test_name, int result) {
    if (result == 0) {
        neorv32_uart0_printf("[PASS] %s\n", test_name);
    } else {
        neorv32_uart0_printf("[FAIL] %s (Error code: %d)\n", test_name, result);
    }
}

/**********************************************************************//**
 * @brief Compare two buffers
 **************************************************************************/
int compare_buffers(const uint8_t* buf1, const uint8_t* buf2, uint32_t size) {
    for (uint32_t i = 0; i < size; i++) {
        if (buf1[i] != buf2[i]) {
            neorv32_uart0_printf("Mismatch at byte %d: expected 0x%x, got 0x%x\n",
                               i, buf1[i], buf2[i]);
            return -1;
        }
    }
    return 0;
}

/**********************************************************************//**
 * @brief Print status register details
 **************************************************************************/
void print_status_details(uint8_t status) {
    neorv32_uart0_printf("Status Register: 0x%x\n", status);
    neorv32_uart0_printf("  Busy: %d\n", (status >> 0) & 1);
    neorv32_uart0_printf("  Write Enabled: %d\n", (status >> 1) & 1);
    neorv32_uart0_printf("  Block Protect 0: %d\n", (status >> 2) & 1);
    neorv32_uart0_printf("  Block Protect 1: %d\n", (status >> 3) & 1);
    neorv32_uart0_printf("  Block Protect 2: %d\n", (status >> 4) & 1);
}

/**********************************************************************//**
 * @brief Manual sector erase using different command codes
 **************************************************************************/
int manual_sector_erase(uint32_t address, uint8_t erase_cmd) {
    neorv32_uart0_printf("Manual sector erase with command 0x%x at address 0x%06x\n", erase_cmd, address);

    // Enable write
    int result = spi_flash_hal_write_enable();
    if (result != 0) {
        neorv32_uart0_printf("Write enable failed: %d\n", result);
        return result;
    }

    // Send erase command manually
    neorv32_spi_cs_en(SPI_FLASH_HAL_CS);
    neorv32_spi_transfer(erase_cmd);
    // Send address (4 bytes)
    neorv32_spi_transfer((address >> 24) & 0xFF);
    neorv32_spi_transfer((address >> 16) & 0xFF);
    neorv32_spi_transfer((address >> 8) & 0xFF);
    neorv32_spi_transfer(address & 0xFF);
    neorv32_spi_cs_dis();

    // Wait for completion with extended timeout
    result = spi_flash_hal_wait_ready(10000); // 10 second timeout
    if (result != 0) {
        neorv32_uart0_printf("Erase timeout with command 0x%x\n", erase_cmd);
        return result;
    }

    neorv32_uart0_printf("Erase completed with command 0x%x\n", erase_cmd);
    return 0;
}

/**********************************************************************//**
 * @brief Try multiple erase approaches
 **************************************************************************/
int try_multiple_erase_approaches(uint32_t address) {
    neorv32_uart0_printf("\n=== Trying Multiple Erase Approaches ===\n");

    uint8_t erase_commands[] = {0x21, 0xD8, 0x52}; // Different erase commands
    const char* cmd_names[] = {"4KB Sector (0x20)", "64KB Block (0xD8)", "32KB Block (0x52)"};

    for (int i = 0; i < 1; i++) {
        neorv32_uart0_printf("\nTrying %s erase...\n", cmd_names[i]);

        int result = manual_sector_erase(address, erase_commands[i]);
        if (result == 0) {
            // Verify erase
            uint8_t verify_buffer[16];
            result = spi_flash_hal_read(address, verify_buffer, 16);
            if (result == 0) {
                int ff_count = 0;
                for (int j = 0; j < 16; j++) {
                    if (verify_buffer[j] == 0xFF) ff_count++;
                }
                neorv32_uart0_printf("Verification: %d/16 bytes are 0xFF\n", ff_count);
                if (ff_count == 16) {
                    neorv32_uart0_printf("SUCCESS: %s erase worked!\n", cmd_names[i]);
                    return 0; // Found working command
                }
            }
        }
    }

    return -1; // No erase command worked
}

/**@}*/

/**********************************************************************//**
 * @name Test Functions
 **************************************************************************/
/**@{*/

/**********************************************************************//**
 * @brief Test SPI Flash HAL initialization
 **************************************************************************/
int test_init(void) {
    neorv32_uart0_printf("Testing SPI Flash HAL initialization...\n");

    int result = spi_flash_hal_init();
    print_test_result("Initialization", result);

    return result;
}

/**********************************************************************//**
 * @brief Test reading device information
 **************************************************************************/
int test_read_info(void) {
    neorv32_uart0_printf("Testing device information read...\n");

    spi_flash_info_t info;
    int result = spi_flash_hal_read_info(&info);

    if (result == 0) {
        neorv32_uart0_printf("Manufacturer ID: 0x%x\n", info.manufacturer_id);
        neorv32_uart0_printf("Memory Type: 0x%x\n", info.memory_type);
        neorv32_uart0_printf("Capacity: 0x%x\n", info.capacity);
        neorv32_uart0_printf("Total Size: %d bytes\n", info.total_size);
        neorv32_uart0_printf("Sector Size: %d bytes\n", info.sector_size);
        neorv32_uart0_printf("Page Size: %d bytes\n", info.page_size);

        // Determine flash type based on manufacturer ID
        switch (info.manufacturer_id) {
            case 0x1F: neorv32_uart0_printf("Manufacturer: Adesto\n"); break;
            case 0x01: neorv32_uart0_printf("Manufacturer: Spansion/Cypress\n"); break;
            case 0x20: neorv32_uart0_printf("Manufacturer: Micron\n"); break;
            case 0xEF: neorv32_uart0_printf("Manufacturer: Winbond\n"); break;
            case 0xC2: neorv32_uart0_printf("Manufacturer: Macronix\n"); break;
            case 0x9D: neorv32_uart0_printf("Manufacturer: Intel\n"); break;
            default: neorv32_uart0_printf("Manufacturer: Unknown (0x%x)\n", info.manufacturer_id); break;
        }
    }

    print_test_result("Read Info", result);

    return result;
}

/**********************************************************************//**
 * @brief Test reading status register with detailed info
 **************************************************************************/
int test_read_status(void) {
    neorv32_uart0_printf("Testing status register read...\n");

    spi_flash_status_t status;
    int result = spi_flash_hal_read_status(&status);

    //! read bank register if applicable
    // neorv32_spi_cs_en(SPI_FLASH_HAL_CS);
    // neorv32_spi_transfer(16);
    // uint8_t res = neorv32_spi_transfer(0);
    // uint8_t res2 = neorv32_spi_transfer(0);
    // neorv32_spi_cs_dis();
    // neorv32_uart0_printf("bank register%d\n", res);
    // neorv32_uart0_printf("bank register%d\n", res2);

    if (result == 0) {
        print_status_details(status.status_reg);
    }

    print_test_result("Read Status", result);

    return result;
}

/**********************************************************************//**
 * @brief Test write enable/disable
 **************************************************************************/
int test_write_enable_disable(void) {
    neorv32_uart0_printf("Testing write enable/disable...\n");

    int result = 0;
    spi_flash_status_t status;

    // Test write enable
    result = spi_flash_hal_write_enable();
    if (result == 0) {
        // Verify status
        spi_flash_hal_read_status(&status);
        neorv32_uart0_printf("Status after write enable:\n");
        print_status_details(status.status_reg);
        if (!status.write_enabled) {
            result = -1;
            neorv32_uart0_printf("ERROR: Write enable failed - status doesn't show WEL=1\n");
        }
    }
    print_test_result("Write Enable", result);

    // Test write disable
    int disable_result = spi_flash_hal_write_disable();
    if (disable_result == 0) {
        // Verify status
        spi_flash_hal_read_status(&status);
        neorv32_uart0_printf("Status after write disable:\n");
        print_status_details(status.status_reg);
        if (status.write_enabled) {
            disable_result = -1;
            neorv32_uart0_printf("ERROR: Write disable failed - status still shows WEL=1\n");
        }
    }
    result |= disable_result;
    print_test_result("Write Disable", disable_result);

    return result;
}

/**********************************************************************//**
 * @brief Test sector erase with multiple approaches
 **************************************************************************/
int test_sector_erase(void) {
    neorv32_uart0_printf("Testing sector erase at address 0x%06x...\n", TEST_FLASH_ADDR);

    // First try the standard approach
    int result = spi_flash_hal_erase_sector(TEST_FLASH_ADDR);

    if (result != 0) {
        neorv32_uart0_printf("Standard erase failed: %d\n", result);
        // Try alternative approaches
        result = try_multiple_erase_approaches(TEST_FLASH_ADDR);
    } else {
        // Standard erase succeeded, verify it
        uint8_t verify_buffer[16];
        result = spi_flash_hal_read(TEST_FLASH_ADDR, verify_buffer, 16);
        if (result == 0) {
            int ff_count = 0;
            for (int i = 0; i < 16; i++) {
                if (verify_buffer[i] == 0xFF) ff_count++;
            }
            neorv32_uart0_printf("Verification: %d/16 bytes are 0xFF\n", ff_count);
            if (ff_count != 16) {
                neorv32_uart0_printf("Standard erase didn't work properly, trying alternatives...\n");
                result = try_multiple_erase_approaches(TEST_FLASH_ADDR);
            }
        }
    }

    print_test_result("Sector Erase", result);

    return result;
}

/**********************************************************************//**
 * @brief Test data programming
 **************************************************************************/
int test_program(void) {
    neorv32_uart0_printf("Testing data programming at address 0x%06x...\n", TEST_FLASH_ADDR);

    // Check flash protection before programming
    spi_flash_status_t status;
    spi_flash_hal_read_status(&status);
    if (status.block_protect) {
        neorv32_uart0_printf("WARNING: Block protection is active!\n");
    }

    // Ensure write is enabled
    int result = spi_flash_hal_write_enable();
    if (result != 0) {
        print_test_result("Write Enable (for programming)", result);
        return result;
    }

    // Program the data
    result = spi_flash_hal_program(TEST_FLASH_ADDR, test_pattern, TEST_BUFFER_SIZE);
    if (result == 0) {
        // Wait for programming to complete
        result = spi_flash_hal_wait_ready(5000);
        if (result != 0) {
            print_test_result("Data Program - Wait for Ready", result);
            return result;
        }
    }

    print_test_result("Data Program", result);

    return result;
}

/**********************************************************************//**
 * @brief Test data reading
 **************************************************************************/
int test_read(void) {
    neorv32_uart0_printf("Testing data read from address 0x%06x...\n", TEST_FLASH_ADDR);

    int result = spi_flash_hal_read(TEST_FLASH_ADDR, read_buffer, TEST_BUFFER_SIZE);

    if (result == 0) {
        neorv32_uart0_printf("First 16 bytes: ");
        for (int i = 0; i < 16; i++) {
            neorv32_uart0_printf("0x%x ", read_buffer[i]);
        }
        neorv32_uart0_printf("\n");
    }

    print_test_result("Data Read", result);

    return result;
}

/**********************************************************************//**
 * @brief Test data verification
 **************************************************************************/
int test_verify(void) {
    neorv32_uart0_printf("Testing data verification...\n");

    int result = compare_buffers(test_pattern, read_buffer, TEST_BUFFER_SIZE);
    print_test_result("Data Verification", result);

    return result;
}

/**********************************************************************//**
 * @brief Test power management
 **************************************************************************/
int test_power_management(void) {
    neorv32_uart0_printf("Testing power management...\n");

    int result = 0;

    // Test power down
    result |= spi_flash_hal_power_down();
    print_test_result("Power Down", result);

    // Small delay
    for (volatile int i = 0; i < 100000; i++);

    // Test wake up
    result |= spi_flash_hal_wake_up();
    print_test_result("Wake Up", result);

    return result;
}

/**@}*/

/**********************************************************************//**
 * @brief SPI Flash HAL test program with enhanced debugging
 *
 * @note This program requires the UART and the SPI to be synthesized.
 *
 * @return Irrelevant.
 **************************************************************************/
int main() {

    // capture all exceptions and give debug info via UART
    // this is not required, but keeps us safe
    neorv32_rte_setup();

    // setup UART at default baud rate, no interrupts
    neorv32_uart0_setup(BAUD_RATE, 0);

    // check if UART0 unit is implemented at all
    if (neorv32_uart0_available() == 0) {
        return 1;
    }

    // intro
    neorv32_uart0_printf("\n<<< SPI Flash HAL Test Program (Enhanced Debug Version) >>>\n\n");

    // check if SPI unit is implemented at all
    if (neorv32_spi_available() == 0) {
        neorv32_uart0_printf("ERROR! No SPI unit implemented.");
        return 1;
    }
    neorv32_uart0_printf("SYSINFO CLK: %u Hz\n", neorv32_sysinfo_get_clk());
    // disable global interrupts
    neorv32_cpu_csr_clr(CSR_MIE, -1);

    // Run tests
    int total_result = 0;

    total_result |= test_init();
    total_result |= test_read_info();
    total_result |= test_read_status();
    total_result |= test_write_enable_disable();
    total_result |= test_sector_erase();
    total_result |= test_program();
    total_result |= test_read();
    total_result |= test_verify();
    total_result |= test_power_management();

    // Final result
    neorv32_uart0_printf("\n=== Test Summary ===\n");
    if (total_result == 0) {
        neorv32_uart0_printf("All tests PASSED!\n");
    } else {
        neorv32_uart0_printf("Some tests FAILED!\n");
        neorv32_uart0_printf("Error code: %d\n", total_result);
    }

    // Cleanup
    spi_flash_hal_deinit();

    // infinite loop
    while(1) {
        asm volatile ("nop");
    }

    return 0;
}