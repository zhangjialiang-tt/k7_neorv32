#include <neorv32.h>
#include "hal_twi.h"
#include <string.h>

// ----------------------------------------------------------------------------
// Prototypes
// ----------------------------------------------------------------------------
void i2c_init(void);
void i2c_test(void);
void i2c_read(char dev_addr, unsigned short reg_addr, char *data, char length_reg, char channel);
void i2c_read_burst(char dev_addr, unsigned short reg_addr, char *data, char length_reg, char length_data, char channel);
void i2c_write(char dev_addr, unsigned short reg_addr, char data, char length_reg, char channel);
void i2c_write_burst(char dev_addr, unsigned short reg_addr, char *data, char length_reg, char length_data, char channel);
int i2c_addr_find(char channel);

// ----------------------------------------------------------------------------
// HAL structure
// ----------------------------------------------------------------------------
ST_DRV_I2C_T st_drv_i2c =
    {
        .init = i2c_init,
        .test = i2c_test,
        .read = i2c_read,
        .read_burst = i2c_read_burst,
        .write = i2c_write,
        .write_burst = i2c_write_burst};

// ----------------------------------------------------------------------------
// Functions
// ----------------------------------------------------------------------------

/**
 * @brief Initialize TWI/I2C peripheral
 */
void i2c_init(void)
{
    if (neorv32_twi_available() == 0)
    {
        return; // Do nothing if not implemented
    }

    // --- Configure TWI speed ---
    // f_scl = f_main / (2 * 2^prsc * (cdiv + 1))
    // Find the first valid combination of prsc and cdiv that gets us <= the target frequency.
    const uint32_t f_main = neorv32_cpu_get_clk();
    const uint32_t f_scl_target = FREQUENCY_I2C_MASTER_MODE;
    uint32_t prsc = 0;
    uint32_t cdiv = 0;

    // Prevent division by zero if f_scl_target is 0, default to slowest speed
    if (f_scl_target == 0)
    {
        neorv32_twi_setup(7, 15, 1); // Max division
        return;
    }

    // Calculate the required total divisor
    uint32_t divisor = (f_main / (2 * f_scl_target));

    for (prsc = 0; prsc < 8; prsc++)
    {
        uint32_t prescaler = 1 << prsc;
        if (divisor < prescaler)
        {
            continue;
        }
        int32_t temp_cdiv = (divisor / prescaler) - 1;

        if (temp_cdiv <= 15)
        {
            cdiv = (temp_cdiv < 0) ? 0 : (uint32_t)temp_cdiv;
            break; // Use the first valid pair found
        }
    }

    if (prsc == 8)
    {
        // If no suitable combination was found (e.g. target frequency is too high)
        // default to the slowest possible speed.
        prsc = 7;
        cdiv = 15;
    }

    // Setup TWI controller: enable, set prescaler and clock-divider, allow clock stretching
    neorv32_twi_setup((int)prsc, (int)cdiv, 1);
}

/**
 * @brief Test function for I2C - placeholder
 */
void i2c_test(void)
{
    // This is a placeholder. A real test could scan for a device.
    i2c_addr_find(0);
}

/**
 * @brief Write a single byte to an I2C device.
 */
void i2c_write(char dev_addr, unsigned short reg_addr, char data, char length_reg, char channel)
{
    (void)channel;
    uint8_t packet;

    neorv32_twi_generate_start();

    packet = (uint8_t)((dev_addr << 1) | 0); // Write
    if (neorv32_twi_transfer(&packet, 0))
    {
        neorv32_twi_generate_stop();
        return;
    }

    if (length_reg == 2)
    {
        packet = (uint8_t)(reg_addr >> 8);
        if (neorv32_twi_transfer(&packet, 0))
        {
            neorv32_twi_generate_stop();
            return;
        }
    }
    if (length_reg >= 1)
    {
        packet = (uint8_t)(reg_addr & 0xFF);
        if (neorv32_twi_transfer(&packet, 0))
        {
            neorv32_twi_generate_stop();
            return;
        }
    }

    packet = (uint8_t)data;
    neorv32_twi_transfer(&packet, 0);

    neorv32_twi_generate_stop();
}

/**
 * @brief Write a burst of bytes to an I2C device.
 */
void i2c_write_burst(char dev_addr, unsigned short reg_addr, char *data, char length_reg, char length_data, char channel)
{
    (void)channel;
    uint8_t packet;

    neorv32_twi_generate_start();

    packet = (uint8_t)((dev_addr << 1) | 0); // Write
    if (neorv32_twi_transfer(&packet, 0))
    {
        neorv32_twi_generate_stop();
        return;
    }

    if (length_reg == 2)
    {
        packet = (uint8_t)(reg_addr >> 8);
        if (neorv32_twi_transfer(&packet, 0))
        {
            neorv32_twi_generate_stop();
            return;
        }
    }
    if (length_reg >= 1)
    {
        packet = (uint8_t)(reg_addr & 0xFF);
        if (neorv32_twi_transfer(&packet, 0))
        {
            neorv32_twi_generate_stop();
            return;
        }
    }

    for (int i = 0; i < length_data; i++)
    {
        packet = (uint8_t)data[i];
        if (neorv32_twi_transfer(&packet, 0))
        {
            break;
        }
    }

    neorv32_twi_generate_stop();
}

/**
 * @brief Read a single byte from an I2C device.
 */
void i2c_read(char dev_addr, unsigned short reg_addr, char *data, char length_reg, char channel)
{
    i2c_read_burst(dev_addr, reg_addr, data, length_reg, 1, channel);
}

/**
 * @brief Read a burst of bytes from an I2C device.
 */
void i2c_read_burst(char dev_addr, unsigned short reg_addr, char *data, char length_reg, char length_data, char channel)
{
    (void)channel;
    uint8_t packet;

    if (length_data == 0)
    {
        return;
    }

    neorv32_twi_generate_start();

    packet = (uint8_t)((dev_addr << 1) | 0);
    if (neorv32_twi_transfer(&packet, 0))
    {
        neorv32_twi_generate_stop();
        return;
    }

    if (length_reg == 2)
    {
        packet = (uint8_t)(reg_addr >> 8);
        if (neorv32_twi_transfer(&packet, 0))
        {
            neorv32_twi_generate_stop();
            return;
        }
    }
    if (length_reg >= 1)
    {
        packet = (uint8_t)(reg_addr & 0xFF);
        if (neorv32_twi_transfer(&packet, 0))
        {
            neorv32_twi_generate_stop();
            return;
        }
    }

    neorv32_twi_generate_start(); // Repeated start

    packet = (uint8_t)((dev_addr << 1) | 1);
    if (neorv32_twi_transfer(&packet, 1))
    {
        neorv32_twi_generate_stop();
        return;
    }

    for (int i = 0; i < length_data; i++)
    {
        int is_last_byte = (i == (length_data - 1));
        packet = 0xFF; // Dummy write
        neorv32_twi_transfer(&packet, !is_last_byte);
        data[i] = (char)packet;
    }

    neorv32_twi_generate_stop();
}

/**
 * @brief Scan I2C bus for a connected device.
 */
int i2c_addr_find(char channel)
{
    (void)channel;
    uint8_t packet;

    if (neorv32_twi_available() == 0)
    {
        return 0;
    }

    for (uint8_t addr = 1; addr < 128; addr++)
    {
        neorv32_twi_generate_start();
        packet = (addr << 1) | 0; // Write operation
        int ack = neorv32_twi_transfer(&packet, 0);
        neorv32_twi_generate_stop();
        if (ack == 0)
        { // ACK received
            return addr;
        }
    }
    return 0; // No device found
}