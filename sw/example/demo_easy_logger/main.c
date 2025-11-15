#include <neorv32.h>
// #include <elog.h>
#include "../../lib_3rd/easylogger/inc/elog.h"

#define NEORV32_RTE_HAS_STDOUT
#define BAUD_RATE 19200
// #define LOG_TAG "demo"
#define LOG_LVL ELOG_LVL_VERBOSE

int main()
{
    neorv32_rte_setup();
    neorv32_uart0_setup(BAUD_RATE, 0);

    if (neorv32_uart0_available() == 0)
    {
        return -1;
    }
    // neorv32_uart0_enable();
    // print project logo via UART
    neorv32_aux_print_logo();
#ifdef NEORV32_RTE_HAS_STDOUT
    elog_init();
    neorv32_uart0_puts("initial done!\n");
    elog_set_fmt(ELOG_LVL_ASSERT, ELOG_FMT_ALL);
    elog_set_fmt(ELOG_LVL_ERROR, ELOG_FMT_ALL);
    elog_set_fmt(ELOG_LVL_WARN, ELOG_FMT_ALL);
    elog_set_fmt(ELOG_LVL_INFO, ELOG_FMT_ALL);
    elog_set_fmt(ELOG_LVL_DEBUG, ELOG_FMT_ALL);
    elog_set_fmt(ELOG_LVL_VERBOSE, ELOG_FMT_ALL);
    elog_start();
    neorv32_uart0_puts("elog start...\n");
    log_a("assert test: %d", 1);
    log_e("error test");
    log_w("warn test");
    log_i("info test");
    log_d("debug test: 0x%x", 0x1234);
    log_v("verbose test");
#endif
    // while (1)
    // {
    //   log_i("tick");
    //   neorv32_aux_delay_ms(neorv32_sysinfo_get_clk(), 500);
    // }
    // 进入无限循环，防止程序退出
    while (1)
    {
        neorv32_aux_delay_ms(neorv32_sysinfo_get_clk(), 1000);

        // neorv32_uart0_puts("Hello world! :)\n");
        asm volatile("nop"); // 空操作，等待中断或复位
    }

    return 0;
}
