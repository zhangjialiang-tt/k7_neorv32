// ================================================================================ //
// The NEORV32 RISC-V Processor - https://github.com/stnolting/neorv32              //
// ================================================================================ //

#include <neorv32.h>
#include <string.h>
#include <stdio.h>
#include "easyflash/inc/easyflash.h"
#include "spi_flash/include/spi_flash_hal.h"

// UART通信波特率设置
#define BAUD_RATE 19200

static void print_hex8(uint32_t v)
{
    char s[9];
    for (int i = 0; i < 8; i++)
    {
        uint8_t n = (uint8_t)((v >> ((7 - i) * 4)) & 0xF);
        s[i] = (char)(n < 10 ? ('0' + n) : ('a' + (n - 10)));
    }
    s[8] = '\0';
    neorv32_uart0_printf("%s ", s);
}

static void print_hex_words(const uint32_t *p, size_t words)
{
    for (size_t i = 0; i < words; i++)
    {
        if ((i % 8) == 0)
            neorv32_uart0_printf("\n  ");
        print_hex8((uint32_t)p[i]);
    }
    neorv32_uart0_printf("\n");
}

/**
 * @brief 打印测试结果
 * @param name 测试名称
 * @param rc 返回码 (0表示成功，非0表示失败)
 */
static void print_result(const char *name, int rc)
{
    if (rc == 0)
    {
        neorv32_uart0_printf("[PASS] %s\n", name);
    }
    else
    {
        neorv32_uart0_printf("[FAIL] %s (rc=%d)\n", name, rc);
    }
}

/**
 * @brief 将CPU周期数转换为微秒时间
 * @param cycles CPU周期数
 * @return 对应的微秒数
 */
static uint32_t cycles_to_us(uint64_t cycles)
{
    uint32_t clk = neorv32_sysinfo_get_clk();  // 获取系统时钟频率
    if (clk == 0)
        return 0;
    return (uint32_t)(cycles * 1000000ull / clk);  // 周期数 * 1,000,000 / 时钟频率
}

/**
 * @brief 性能测试函数
 * @param name 测试名称
 * @param fn 要测试的函数指针
 */
static void bench(const char *name, int (*fn)(void))
{
    uint64_t c0 = neorv32_cpu_get_cycle();  // 记录开始时的CPU周期数
    int rc = fn();                           // 执行测试函数
    uint64_t c1 = neorv32_cpu_get_cycle();  // 记录结束时的CPU周期数
    uint64_t d = c1 - c0;                    // 计算消耗的周期数
    
    print_result(name, rc);                   // 打印测试结果
    neorv32_uart0_printf("  cycles=%lu us=%u\n", (uint32_t)d, cycles_to_us(d));  // 打印性能数据
}

static int test_log_clean(void)
{
    if (ef_log_clean() != EF_NO_ERR)
        return -1;
    if (ef_log_get_used_size() != 0)
        return -2;
    return 0;
}

static int test_log_basic_rw(void)
{
    size_t prev = ef_log_get_used_size();
    enum { NWORDS = 64 };
    uint32_t w[NWORDS];
    for (size_t i = 0; i < NWORDS; i++)
        w[i] = 0xA5A50000u + (uint32_t)i;
    if (ef_log_write(w, sizeof(w)) != EF_NO_ERR)
        return -1;
    uint32_t rbuf[NWORDS];
    if (ef_log_read(prev, rbuf, sizeof(rbuf)) != EF_NO_ERR)
        return -2;
    if (memcmp(w, rbuf, sizeof(w)) != 0)
        return -3;
    return 0;
}

static int test_log_persist_compare(void)
{
    const uint32_t baddr = (uint32_t)(EF_START_ADDR + ENV_AREA_SIZE + LOG_AREA_SIZE);
    enum { NWORDS = 128 };
    const size_t blen = NWORDS * 4u;
    uint8_t prev[512];
    if (spi_flash_hal_read(baddr, prev, (uint32_t)blen) == 0)
    {
        int have_prev = 0;
        for (size_t i = 0; i < blen; i++) { if (prev[i] != 0xFF) { have_prev = 1; break; } }
        if (have_prev)
        {
            size_t used = ef_log_get_used_size();
            if (used >= blen)
            {
                uint8_t tail[512];
                if (ef_log_read(used - blen, (uint32_t*)tail, blen) != EF_NO_ERR)
                    return -1;
                if (memcmp(prev, tail, blen) != 0)
                    return -2;
            }
        }
    }
    uint32_t w[NWORDS];
    for (size_t i = 0; i < NWORDS; i++)
        w[i] = 0xCAFEB000u + (uint32_t)i;
    size_t prev_used = ef_log_get_used_size();
    if (ef_log_write(w, sizeof(w)) != EF_NO_ERR)
        return -3;
    uint32_t rbuf[NWORDS];
    if (ef_log_read(prev_used, rbuf, sizeof(rbuf)) != EF_NO_ERR)
        return -4;
    if (memcmp(w, rbuf, sizeof(w)) != 0)
        return -5;
    if (spi_flash_hal_erase_sector(baddr) != 0)
        return -6;
    if (spi_flash_hal_program(baddr, (const uint8_t*)w, (uint32_t)blen) != 0)
        return -7;
    return 0;
}

static int test_log_wrap(void)
{
    const size_t chunk = 4096;
    if (chunk % 4)
        return -10;
    size_t total = ef_log_get_total_size();
    if (total == 0)
        return -11;
    size_t used = ef_log_get_used_size();
    size_t max_bytes = 16*1024;
    size_t to_fill = (total > used) ? (total - used) : 0;
    int full_wrap = 1;
    if (to_fill > max_bytes) {
        to_fill = max_bytes;
        full_wrap = 0;
        neorv32_uart0_printf("LOG wrap: cap fill=%u bytes\n", (uint32_t)to_fill);
    }
    size_t nwords = chunk / 4;
    uint32_t buf_words[4096/4];
    uint32_t seed = 0x12345678u;
    for (size_t i = 0; i < nwords; i++)
        buf_words[i] = seed + (uint32_t)i;
    size_t filled = 0;
    while ((full_wrap && (used < total)) || (!full_wrap && (filled < to_fill)))
    {
        if (ef_log_write(buf_words, chunk) != EF_NO_ERR)
            return -1;
        used = ef_log_get_used_size();
        filled += chunk;
        if ((filled % (4*chunk)) == 0)
            neorv32_uart0_printf(".");
        seed += 0x1111u;
        for (size_t i = 0; i < nwords; i++)
            buf_words[i] = seed + (uint32_t)i;
    }
    if (!full_wrap)
    {
        size_t verify = (used >= chunk) ? chunk : used;
        if (verify)
        {
            size_t idx = used - verify;
            uint32_t rbuf[4096/4];
            if (ef_log_read(idx, rbuf, verify) != EF_NO_ERR)
                return -6;
        }
        return 0;
    }
    for (int k = 0; k < 2; k++)
    {
        if (ef_log_write(buf_words, chunk) != EF_NO_ERR)
            return -2;
        size_t u = ef_log_get_used_size();
        if (u != total)
            return -3;
        size_t idx = u >= chunk ? (u - chunk) : 0;
        uint32_t rbuf[4096/4];
        if (ef_log_read(idx, rbuf, chunk) != EF_NO_ERR)
            return -4;
        if (memcmp(buf_words, rbuf, chunk) != 0)
            return -5;
        seed += 0x2222u;
        for (size_t i = 0; i < nwords; i++)
            buf_words[i] = seed + (uint32_t)i;
    }
    return 0;
}

static int test_log_view(void)
{
    size_t used = ef_log_get_used_size();
    size_t total = ef_log_get_total_size();
    neorv32_uart0_printf("LOG used=%u total=%u\n", (uint32_t)used, (uint32_t)total);
    if (used == 0)
        return 0;
    size_t head_words = used/4 < 32 ? used/4 : 32;
    uint32_t head[32];
    if (head_words)
    {
        if (ef_log_read(0, head, head_words*4) != EF_NO_ERR)
            return -1;
        neorv32_uart0_printf("LOG head:");
        print_hex_words(head, head_words);
    }
    size_t tail_words = used/4 < 32 ? used/4 : 32;
    uint32_t tail[32];
    size_t tail_idx = used - tail_words*4;
    if (ef_log_read(tail_idx, tail, tail_words*4) != EF_NO_ERR)
        return -2;
    neorv32_uart0_printf("LOG tail:");
    print_hex_words(tail, tail_words);
    return 0;
}

/**
 * @brief 主函数 - EasyFlash功能演示和测试
 * @return 程序退出码
 */
int main(void)
{
    // 初始化NEORV32运行时环境
    neorv32_rte_setup();
    
    // 初始化UART0，设置波特率
    neorv32_uart0_setup(BAUD_RATE, 0);
    if (neorv32_uart0_available() == 0)
    {
        return 1;  // UART不可用，退出程序
    }
    
    // 打印测试开始信息
    neorv32_uart0_printf("\n<<< EasyFlash 功能测试 >>>\n\n");
    
    // 检查SPI接口是否可用
    if (neorv32_spi_available() == 0)
    {
        neorv32_uart0_printf("ERROR: SPI not available.\n");
        return 1;
    }
    
    // 禁用所有中断，确保测试过程不受干扰
    neorv32_cpu_csr_clr(CSR_MIE, (uint32_t)-1);

    // 初始化SPI Flash硬件抽象层
    int rc = spi_flash_hal_init();
    print_result("spi_flash_hal_init", rc);
    if (rc != 0)
        return 1;

    // 读取并显示Flash芯片信息
    spi_flash_info_t info;
    if (spi_flash_hal_read_info(&info) == 0)
    {
        neorv32_uart0_printf("Flash JEDEC: m=0x%x t=0x%x c=0x%x size=%u\n",
                             info.manufacturer_id, info.memory_type, info.capacity, info.total_size);
    }

    // 初始化EasyFlash库
    EfErrCode erc = easyflash_init();
    print_result("easyflash_init", erc == EF_NO_ERR ? 0 : -1);
    if (erc != EF_NO_ERR)
        return 1;

    // 日志功能测试
    // bench("LOG clean", test_log_clean);
    // bench("LOG basic rw", test_log_basic_rw);
    // bench("LOG persist compare", test_log_persist_compare);
    // bench("LOG wrap", test_log_wrap);
    bench("LOG view", test_log_view);

    // 测试完成
    neorv32_uart0_printf("\n=== 测试完成 ===\n");
    
    // 进入无限循环，防止程序退出
    while (1)
    {
        asm volatile("nop");  // 空操作，等待中断或复位
    }
    
    return 0;
}