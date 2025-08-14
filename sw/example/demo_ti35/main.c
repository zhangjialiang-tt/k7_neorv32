// ================================================================================ //
// The NEORV32 RISC-V Processor - https://github.com/stnolting/neorv32              //
// Copyright (c) NEORV32 contributors.                                              //
// Copyright (c) 2020 - 2025 Stephan Nolting. All rights reserved.                  //
// Licensed under the BSD-3-Clause license, see LICENSE for details.                //
// SPDX-License-Identifier: BSD-3-Clause                                            //
// ================================================================================ //


/**********************************************************************//**
 * @file demo_twi/main.c
 * @brief TWI AT24C04 EEPROM test program with diagnostics.
 **************************************************************************/

#include <neorv32.h>
#include <string.h>


/**********************************************************************//**
 * @name User configuration
 **************************************************************************/
/**@}*/
/** UART BAUD rate */
#define BAUD_RATE 19200
/** I2C device address of the AT24C04 EEPROM.
 * This assumes the address pins A1 and A2 are grounded. */
#define EEPROM_DEVICE_ADDR 0b1010000
/**@}*/


// Prototypes
void bus_scan(void);
int eeprom_write_byte(uint16_t address, uint8_t data);
int eeprom_read_byte(uint16_t address, uint8_t *data);
void print_hex_byte(uint8_t data);


/**********************************************************************//**
 * Simple bus-wait helper.
 *
 * @param[in] time_ms Time in ms to wait (unsigned 32-bit).
 **************************************************************************/
void delay_ms(uint32_t time_ms) {
  neorv32_aux_delay_ms(neorv32_sysinfo_get_clk(), time_ms);
}
/**********************************************************************//**
 * This program tests writing and reading a byte from an AT24C04 EEPROM.
 *
 * @note This program requires the UART and TWI to be synthesized.
 *
 * @return 0 if execution was successful
 **************************************************************************/
int main() {

  // capture all exceptions and give debug info via UART
  neorv32_rte_setup();

  // check if UART unit is implemented at all
  if (neorv32_uart0_available() == 0) {
    return 1;
  }

  // setup UART at default baud rate, no interrupts
  neorv32_uart0_setup(BAUD_RATE, 0);

  // check if TWI unit is implemented at all
  if (neorv32_twi_available() == 0) {
    neorv32_uart0_printf("ERROR! TWI controller not available!");
    return 1;
  }

  // intro
  neorv32_uart0_printf("\n--- TWI AT24C04 EEPROM Test with Diagnostics ---\n\n");

  // Configure TWI for 100kHz operation (assuming 100MHz system clock)
  // SCL_PRSC = 4, CLK_PRSC = 128 -> 100MHz / (4 * 128)/2 = 100kHz
  // SCL_CDIV = 0
  neorv32_twi_setup(CLK_PRSC_128, 1, 0);

  // Diagnostic Step 1: Scan the bus
  neorv32_uart0_printf("--- Starting I2C Bus Scan ---");
  bus_scan();
  neorv32_uart0_printf("--- Scan Complete ---\n\n");


  // Test sequence
  uint16_t test_addr = 0x0042; // eeprom address to write to
  uint8_t tx_data = 0xCA;      // data to write
  uint8_t rx_data = 0;         // data to read

  // Write byte
  neorv32_uart0_printf("Writing 0x");
  print_hex_byte(tx_data);
  neorv32_uart0_printf(" to EEPROM address 0x%x...", test_addr);

  if (eeprom_write_byte(test_addr, tx_data) == 0) {
    neorv32_uart0_printf(" OK\n");
  }
  else {
    neorv32_uart0_printf(" FAILED!\n");
    neorv32_uart0_printf("Test halted.");
    return 1;
  }

  // Read byte back
  neorv32_uart0_printf("Reading from EEPROM address 0x%x...", test_addr);

  if (eeprom_read_byte(test_addr, &rx_data) == 0) {
    neorv32_uart0_printf(" OK\n");
  }
  else {
    neorv32_uart0_printf(" FAILED!\n");
    neorv32_uart0_printf("Test halted.");
    return 1;
  }

  // Verify
  neorv32_uart0_printf("\nTX data: 0x");
  print_hex_byte(tx_data);
  neorv32_uart0_printf(", RX data: 0x");
  print_hex_byte(rx_data);
  neorv32_uart0_printf("\n");

  if (tx_data == rx_data) {
    neorv32_uart0_printf("SUCCESS! Data matches.");
  }
  else {
    neorv32_uart0_printf("ERROR! Data mismatch!");
  }

  neorv32_uart0_printf("\nTest complete.");

  return 0;
}


/**********************************************************************//**
 * Scan TWI bus for devices and print results.
 **************************************************************************/
void bus_scan(void) {

  uint8_t i;
  int num_devices = 0;

  for (i=0; i<128; i++) {
    neorv32_twi_generate_start();
    uint8_t addr_rw = (i << 1) | 0; // write address
    int ack = neorv32_twi_transfer(&addr_rw, 0);
    neorv32_twi_generate_stop();

    if (ack == 0) {
      neorv32_uart0_printf(" + Device found at address 0x");
      print_hex_byte(i);
      neorv32_uart0_printf(" (write addr 0x");
      print_hex_byte(addr_rw);
      neorv32_uart0_printf(")\n");
      num_devices++;
    }
  }

  if (num_devices == 0) {
    neorv32_uart0_printf("No devices found. Check wiring, pull-ups and power!\n");
  }
  else {
    neorv32_uart0_printf("Total devices found: %i\n", num_devices);
  }
}


/**********************************************************************//**
 * Write a single byte to EEPROM.
 *
 * @param[in] address 9-bit EEPROM memory address.
 * @param[in] data Byte to write.
 * @return 0 on success, 1 on error (NACK).
 **************************************************************************/
int eeprom_write_byte(uint16_t address, uint8_t data) {

  uint8_t device_addr_byte = (EEPROM_DEVICE_ADDR << 1) | ((address >> 7) & 0x02) | 0; // LSB=0 for write
  uint8_t word_addr_byte = (uint8_t)address;

  neorv32_twi_generate_start();

  // send device address
  if (neorv32_twi_transfer(&device_addr_byte, 0)) {
    neorv32_uart0_printf(" [NACK on device address] ");
    neorv32_twi_generate_stop();
    return 1;
  }

  // send word address
  if (neorv32_twi_transfer(&word_addr_byte, 0)) {
    neorv32_uart0_printf(" [NACK on word address] ");
    neorv32_twi_generate_stop();
    return 1;
  }

  // send data
  if (neorv32_twi_transfer(&data, 0)) {
    neorv32_uart0_printf(" [NACK on data] ");
    neorv32_twi_generate_stop();
    return 1;
  }

  neorv32_twi_generate_stop();

  // Wait for internal write cycle to complete (t_WR is max 5ms for AT24C04)
  // neorv32_cpu_
  delay_ms(5);

  return 0;
}


/**********************************************************************//**
 * Read a single byte from EEPROM.
 *
 * @param[in] address 9-bit EEPROM memory address.
 * @param[in,out] data Pointer to store the read byte.
 * @return 0 on success, 1 on error (NACK).
 **************************************************************************/
int eeprom_read_byte(uint16_t address, uint8_t *data) {

  uint8_t device_addr_byte_write = (EEPROM_DEVICE_ADDR << 1) | ((address >> 7) & 0x02) | 0; // LSB=0 for write
  uint8_t device_addr_byte_read  = (EEPROM_DEVICE_ADDR << 1) | ((address >> 7) & 0x02) | 1; // LSB=1 for read
  uint8_t word_addr_byte = (uint8_t)address;
  uint8_t rx_buffer = 0xff;

  // --- set address pointer ---
  neorv32_twi_generate_start();

  // send device address (write)
  if (neorv32_twi_transfer(&device_addr_byte_write, 0)) {
    neorv32_uart0_printf(" [NACK on dev-addr wr] ");
    neorv32_twi_generate_stop();
    return 1;
  }

  // send word address
  if (neorv32_twi_transfer(&word_addr_byte, 0)) {
    neorv32_uart0_printf(" [NACK on word-addr wr] ");
    neorv32_twi_generate_stop();
    return 1;
  }

  // --- read data from address ---
  neorv32_twi_generate_start(); // repeated start

  // send device address (read)
  if (neorv32_twi_transfer(&device_addr_byte_read, 0)) {
    neorv32_uart0_printf(" [NACK on dev-addr rd] ");
    neorv32_twi_generate_stop();
    return 1;
  }

  // receive data from slave, send NACK to slave to signal end of read
  neorv32_twi_transfer(&rx_buffer, 0);

  neorv32_twi_generate_stop();

  *data = rx_buffer;
  return 0;
}


/**********************************************************************//**
 * Print byte as hex chars via UART0.
 *
 * @param data 8-bit data to be printed as two hex chars.
 **************************************************************************/
void print_hex_byte(uint8_t data) {

  static const char symbols[] = "0123456789abcdef";

  neorv32_uart0_putc(symbols[(data >> 4) & 15]);
  neorv32_uart0_putc(symbols[(data >> 0) & 15]);
}
