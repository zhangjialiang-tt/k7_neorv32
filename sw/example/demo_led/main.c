// ================================================================================ //
// The NEORV32 RISC-V Processor - https://github.com/stnolting/neorv32              //
// Copyright (c) NEORV32 contributors.                                              //
// Copyright (c) 2020 - 2025 Stephan Nolting. All rights reserved.                  //
// Licensed under the BSD-3-Clause license, see LICENSE for details.                //
// SPDX-License-Identifier: BSD-3-Clause                                            //
// ================================================================================ //

/**********************************************************************
 * @file demo_blink_led/main.c
 * @author Stephan Nolting
 * @brief Key-controlled LED toggle demo program + OV5640 I2C Test
 **************************************************************************/
#include <neorv32.h>
#include <stdint.h> // Added for uint32_t and uint8_t
#include "led.h"
#include "key.h"

/**********************************************************************
 * @name User configuration
 **************************************************************************/
/**@{*/
/** UART BAUD rate */
#define BAUD_RATE 115200
/**@}*/

// ============================================================================ //
// OV5640 I2C / Wishbone Wrapper Driver                                         //
// ============================================================================ //

// According to SoC mapping in top.v, Base Address is 0xF0000000
#define I2C_BASE_ADDR 0xF0000000 

// Register Struct
typedef struct {
    volatile uint32_t CTRL;   // 0x00
    volatile uint32_t STATUS; // 0x04
    volatile uint32_t CFG;    // 0x08
    volatile uint32_t TX;     // 0x0C
    volatile uint32_t RX;     // 0x10
} wb_i2c_t;

#define WB_I2C ((wb_i2c_t *)I2C_BASE_ADDR)

// OV5640 I2C Address (7-bit: 0x3C, Write: 0x78, Read: 0x79)
#define OV5640_ADDR_WR 0x78

// Check if bus is busy
static inline void i2c_wait_busy(void) {
    while (WB_I2C->STATUS & 0x01);
}

/**
 * @brief Write OV5640 Register (16-bit address, 8-bit data)
 * 
 * Hardware packing logic (Little Endian):
 * TX[7:0]   = Device Addr (0x78)
 * TX[15:8]  = Reg Addr High
 * TX[23:16] = Reg Addr Low
 * TX[31:24] = Data
 */
void ov5640_write_reg(uint16_t reg_addr, uint8_t data) {
    i2c_wait_busy();

    // 1. Prepare Payload
    uint32_t payload = 0;
    payload |= (uint32_t)OV5640_ADDR_WR;             // Byte 0: DevAddr
    payload |= (uint32_t)((reg_addr >> 8) & 0xFF) << 8;  // Byte 1: RegH
    payload |= (uint32_t)(reg_addr & 0xFF) << 16;        // Byte 2: RegL
    payload |= (uint32_t)data << 24;                     // Byte 3: Data

    // 2. Write to Data Register
    WB_I2C->TX = payload;

    // 3. Configure Length: Write 4 bytes, Read 0
    WB_I2C->CFG = (0 << 8) | 4;

    // 4. Start Transfer: Start=1, Mode=0 (Normal Write)
    WB_I2C->CTRL = 0x01;
}

/**
 * @brief Read OV5640 Register (SCCB Protocol)
 */
uint8_t ov5640_read_reg(uint16_t reg_addr) {
    i2c_wait_busy();

    // 1. Prepare Write Phase Payload
    uint32_t payload = 0;
    payload |= (uint32_t)OV5640_ADDR_WR;             // Byte 0: DevAddr
    payload |= (uint32_t)((reg_addr >> 8) & 0xFF) << 8;  // Byte 1: RegH
    payload |= (uint32_t)(reg_addr & 0xFF) << 16;        // Byte 2: RegL
    // Byte 3 unused

    // 2. Write to Data Register
    WB_I2C->TX = payload;

    // 3. Configure Length
    // Write 3 bytes (Dev + RegH + RegL)
    // Read 1 byte
    WB_I2C->CFG = (1 << 8) | 3;

    // 4. Start Transfer: Start=1, Mode=1 (SCCB/Random Read)
    WB_I2C->CTRL = 0x03;

    // 5. Wait for completion
    i2c_wait_busy();

    // 6. Get Result (Lower 8 bits)
    return (uint8_t)(WB_I2C->RX & 0xFF);
}

// Helper to print hex
void print_hex_byte(uint8_t byte) {
    char hex[] = "0123456789ABCDEF";
    neorv32_uart0_putc(hex[(byte >> 4) & 0xF]);
    neorv32_uart0_putc(hex[byte & 0xF]);
}

/**********************************************************************
 * Simple bus-wait helper.
 * 
 * @param[in] time_ms Time in ms to wait (unsigned 32-bit).
 **************************************************************************/
void delay_ms(uint32_t time_ms)
{
    neorv32_aux_delay_ms(neorv32_sysinfo_get_clk(), time_ms);
}

/**********************************************************************
 * Main function
 **************************************************************************/
int main()
{
    // capture all exceptions and give debug info via UART
    // this is not required, but keeps us safe
    neorv32_rte_setup();

    // setup UART at default baud rate, no interrupts
    neorv32_uart0_setup(BAUD_RATE, 0);

    // print project logo via UART
    neorv32_aux_print_logo();

    neorv32_uart0_puts("\nOV5640 Wishbone I2C Wrapper Demo\n");
    neorv32_uart0_puts("--------------------------------\n");

    // Initialize LEDs (clears them)
    led_init();

    // Initialize keys
    key_init();
    
    // --- OV5640 Test ---
    neorv32_uart0_puts("Checking Camera ID (Reg 0x300A, 0x300B)...");
    
    // Read ID
    uint8_t id_h = ov5640_read_reg(0x300A);
    uint8_t id_l = ov5640_read_reg(0x300B);

    neorv32_uart0_puts("ID Read: 0x");
    print_hex_byte(id_h);
    print_hex_byte(id_l);
    neorv32_uart0_puts("\n");

    if (id_h == 0x56 && id_l == 0x40) {
        neorv32_uart0_puts("SUCCESS: OV5640 Detected!\n");
    } else {
        neorv32_uart0_puts("WARNING: OV5640 ID Mismatch or Read Error.\n");
    }

    uint32_t keys;
    uint8_t led_state = 0;
    uint32_t last_keys = 0x1F; // Initialize to all released (active-low: 1=released)

    neorv32_uart0_puts("\nLED Toggle Control Demo Running...\n");

    while (1)
    {
        // Read key states
        keys = key_get_state();

        // Detect key press for each key
        for (int i = 0; i < KEY_NUM; i++)
        {
            if (key_detect_press(keys, last_keys, i))
            {
                // Toggle corresponding LED
                led_state ^= (1U << i);
                led_set_byte(led_state);

                // Print debug message
                neorv32_uart0_puts("Key");
                neorv32_uart0_putc('0' + i);
                neorv32_uart0_puts(" pressed - LED");
                neorv32_uart0_putc('0' + i);
                neorv32_uart0_puts(" now ");
                neorv32_uart0_puts((led_state & (1U << i)) ? "ON\n" : "OFF\n");
                
                // Optional: Read camera ID again on key press to verify stability
                // id_h = ov5640_read_reg(0x300A);
                // print_hex_byte(id_h); neorv32_uart0_puts("\n");
            }
        }

        // Store current key state for next iteration
        last_keys = keys;

        // Small delay for debouncing
        delay_ms(20);
    }

    // this should never be reached
    return 0;
}
