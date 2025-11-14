/*
 * This file is part of the EasyFlash Library.
 *
 * Copyright (c) 2015-2019, Armink, <armink.ztl@gmail.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * 'Software'), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 * Function: Portable interface for each platform.
 * Created on: 2015-01-16
 */

#include <easyflash.h>
#include <stdarg.h>
#include <neorv32.h>
#include "../../spi_flash/include/spi_flash_hal.h"

static uint32_t ef_mie_state = 0;

/* default environment variables set for user */
static const ef_env default_env_set[] = {
    {"dev", "neorv32", 0},
    {"app", "easyflash_demo", 0}
};

/**
 * Flash port for hardware initialize.
 *
 * @param default_env default ENV set for user
 * @param default_env_size default ENV size
 *
 * @return result
 */
EfErrCode ef_port_init(ef_env const **default_env, size_t *default_env_size) {
    EfErrCode result = EF_NO_ERR;

    if (spi_flash_hal_init() != 0) {
        return EF_ENV_INIT_FAILED;
    }

    *default_env = default_env_set;
    *default_env_size = sizeof(default_env_set) / sizeof(default_env_set[0]);

    return result;
}

/**
 * Read data from flash.
 * @note This operation's units is word.
 *
 * @param addr flash address
 * @param buf buffer to store read data
 * @param size read bytes size
 *
 * @return result
 */
EfErrCode ef_port_read(uint32_t addr, uint32_t *buf, size_t size) {
    EfErrCode result = EF_NO_ERR;
    if (spi_flash_hal_wait_ready(1000) != 0) {
        return EF_READ_ERR;
    }
    if (spi_flash_hal_read(addr, (uint8_t*)buf, (uint32_t)size) != 0) {
        result = EF_READ_ERR;
    }

    return result;
}

/**
 * Erase data on flash.
 * @note This operation is irreversible.
 * @note This operation's units is different which on many chips.
 *
 * @param addr flash address
 * @param size erase bytes size
 *
 * @return result
 */
EfErrCode ef_port_erase(uint32_t addr, size_t size) {
    EfErrCode result = EF_NO_ERR;

    /* make sure the start address is a multiple of EF_ERASE_MIN_SIZE */
    EF_ASSERT(addr % EF_ERASE_MIN_SIZE == 0);
    if (spi_flash_hal_wait_ready(1000) != 0) {
        return EF_ERASE_ERR;
    }
    uint32_t start = addr;
    uint32_t end = addr + (uint32_t)size;
    while (start < end) {
        if (((start % 65536u) == 0) && (end - start) >= 65536u) {
            if (spi_flash_hal_erase_block(start, 65536u) != 0) {
                return EF_ERASE_ERR;
            }
            start += 65536u;
        } else {
            if (spi_flash_hal_erase_sector(start) != 0) {
                return EF_ERASE_ERR;
            }
            start += EF_ERASE_MIN_SIZE;
        }
    }

    return result;
}
/**
 * Write data to flash.
 * @note This operation's units is word.
 * @note This operation must after erase. @see flash_erase.
 *
 * @param addr flash address
 * @param buf the write data buffer
 * @param size write bytes size
 *
 * @return result
 */
EfErrCode ef_port_write(uint32_t addr, const uint32_t *buf, size_t size) {
    EfErrCode result = EF_NO_ERR;
    EF_ASSERT(size % 4 == 0);
    if (spi_flash_hal_wait_ready(1000) != 0) {
        return EF_WRITE_ERR;
    }
    if (spi_flash_hal_program(addr, (const uint8_t*)buf, (uint32_t)size) != 0) {
        result = EF_WRITE_ERR;
    }

    return result;
}

/**
 * lock the ENV ram cache
 */
void ef_port_env_lock(void) {
    ef_mie_state = neorv32_cpu_csr_read(CSR_MIE);
    neorv32_cpu_csr_clr(CSR_MIE, (uint32_t)-1);
}

/**
 * unlock the ENV ram cache
 */
void ef_port_env_unlock(void) {
    neorv32_cpu_csr_write(CSR_MIE, ef_mie_state);
}


/**
 * This function is print flash debug info.
 *
 * @param file the file which has call this function
 * @param line the line number which has call this function
 * @param format output format
 * @param ... args
 *
 */
void ef_log_debug(const char *file, const long line, const char *format, ...) {

#ifdef PRINT_DEBUG

    va_list args;

    /* args point to the first variable parameter */
    va_start(args, format);

    neorv32_uart0_printf("[EF][%s:%ld] ", file, line);
    neorv32_uart_vprintf(NEORV32_UART0,format, args);
    va_end(args);

#endif

}

/**
 * This function is print flash routine info.
 *
 * @param format output format
 * @param ... args
 */
void ef_log_info(const char *format, ...) {
    va_list args;

    /* args point to the first variable parameter */
    va_start(args, format);

    neorv32_uart_vprintf(NEORV32_UART0,format, args);
    va_end(args);
}
/**
 * This function is print flash non-package info.
 *
 * @param format output format
 * @param ... args
 */
void ef_print(const char *format, ...) {
    va_list args;

    /* args point to the first variable parameter */
    va_start(args, format);

    neorv32_uart_vprintf(NEORV32_UART0,format, args);
    va_end(args);
}
