/*
 * This file is part of the EasyLogger Library.
 *
 * Copyright (c) 2015, Armink, <armink.ztl@gmail.com>
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
 * Created on: 2015-04-28
 */
 
#include <elog.h>
#include <neorv32.h>
#include <stdio.h>

/**
 * EasyLogger port initialize
 *
 * @return result
 */
static uint32_t g_prev_mie = 0;

ElogErrCode elog_port_init(void) {
    ElogErrCode result = ELOG_NO_ERR;
    if (neorv32_uart0_available() == 0) {
        return result;
    }
    neorv32_uart0_printf("EasyLogger port init...\n");
    neorv32_uart0_setup(19200, 0);
    neorv32_uart0_enable();
    return result;
}

/**
 * EasyLogger port deinitialize
 *
 */
void elog_port_deinit(void) {
    if (neorv32_uart0_available()) {
        neorv32_uart0_disable();
    }
}

/**
 * output log port interface
 *
 * @param log output of log
 * @param size log size
 */
void elog_port_output(const char *log, size_t size) {
    if (log == NULL || size == 0) {
        return;
    }
    for (size_t i = 0; i < size; i++) {
        neorv32_uart0_putc(log[i]);
    }
}

/**
 * output lock
 */
void elog_port_output_lock(void) {
    uint32_t mstatus = neorv32_cpu_csr_read(CSR_MSTATUS);
    g_prev_mie = (mstatus >> CSR_MSTATUS_MIE) & 1U;
    neorv32_cpu_csr_clr(CSR_MSTATUS, 1U << CSR_MSTATUS_MIE);
}

/**
 * output unlock
 */
void elog_port_output_unlock(void) {
    if (g_prev_mie) {
        neorv32_cpu_csr_set(CSR_MSTATUS, 1U << CSR_MSTATUS_MIE);
    }
}

/**
 * get current time interface
 *
 * @return current time
 */
const char *elog_port_get_time(void) {
    static char time_str[24];
    uint64_t t = neorv32_clint_time_get();
    uint32_t clk = neorv32_sysinfo_get_clk();
    uint64_t ms = (t * 1000ULL) / (uint64_t)clk;
    uint32_t s = (uint32_t)(ms / 1000ULL);
    uint32_t rem_ms = (uint32_t)(ms % 1000ULL);
    int n = snprintf(time_str, sizeof(time_str), "%lu.%03lums", (unsigned long)s, (unsigned long)rem_ms);
    if (n <= 0) {
        time_str[0] = '\0';
    }
    return time_str;
}

/**
 * get current process name interface
 *
 * @return current process name
 */
const char *elog_port_get_p_info(void) {
    static const char pinfo[] = "hart0";
    return pinfo;
}

/**
 * get current thread name interface
 *
 * @return current thread name
 */
const char *elog_port_get_t_info(void) {
    static const char tinfo[] = "thd0";
    return tinfo;
}