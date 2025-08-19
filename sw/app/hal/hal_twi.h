#ifndef HAL_TWI_H
#define HAL_TWI_H

// ----------------------------------------------------------------------------
// Abstraction layer for I2C communication
// ----------------------------------------------------------------------------

typedef struct ST_DRV_I2C
{
    void (*init)(void);
    void (*test)(void);
    void (*read)(char, unsigned short, char *, char, char);
    void (*read_burst)(char, unsigned short, char *, char, char, char);
    void (*write)(char, unsigned short, char, char, char);
    void (*write_burst)(char, unsigned short, char *, char, char, char);
} ST_DRV_I2C_T;

extern ST_DRV_I2C_T st_drv_i2c;

/**
 * @brief Scan I2C bus for a connected device.
 *
 * @param channel I2C channel (ignored, only one TWI peripheral).
 * @return The 7-bit address of the first device found, or 0 if no device responds.
 */
extern int i2c_addr_find(char channel);

// Target SCL frequency in Hz.
// The actual frequency is calculated in i2c_init() based on the main clock frequency
// and might differ slightly.
#define FREQUENCY_I2C_MASTER_MODE 100000

#endif // HAL_TWI_H