/**
 * @file hal_i2c.c
 * @brief I2C HAL implementation for NEORV32 TWI controller
 */

#include "hal_i2c.h"
#include "../../lib/include/neorv32_twi.h" // 引入底层 BSP 接口
#include "../../lib/include/neorv32.h"     // 引入底层 BSP 接口

/* ========================================== */
/*              私有变量与宏定义              */
/* ========================================== */

// 检查控制器是否可用
#define IS_I2C_AVAILABLE() (neorv32_twi_available() != 0)

/* ========================================== */
/*              私有函数声明                  */
/* ========================================== */

static hal_i2c_status_t hal_i2c_wait_not_busy(uint32_t timeout_ms);

/* ========================================== */
/*                 API 实现                   */
/* ========================================== */

bool hal_i2c_is_available(void)
{
    return IS_I2C_AVAILABLE();
}

hal_i2c_status_t hal_i2c_init(const hal_i2c_config_t *config)
{
    if (!IS_I2C_AVAILABLE())
    {
        return HAL_I2C_NOT_AVAIL;
    }

    if (config == NULL)
    {
        return HAL_I2C_ERROR;
    }

    // 计算预分频器和时钟分频值
    int prsc = 0; // 预分频器 (0-7)
    int cdiv = 0; // 时钟分频器 (0-15)

    // 根据目标速度计算分频值
    // TWI clock = f_main / (2 * prescaler * (1 + cdiv))
    uint32_t main_freq = NEORV32_SYSINFO->CLK;
    uint32_t target_freq = config->speed;

    // 尝试不同的预分频器值
    for (prsc = 0; prsc <= 7; prsc++)
    {
        uint32_t prescaler = 1U << prsc;
        // cdiv = (f_main / (2 * prescaler * target_freq)) - 1
        if (prescaler > 0 && target_freq > 0)
        {
            uint32_t temp_cdiv = (main_freq / (2U * prescaler * target_freq)) - 1U;

            if (temp_cdiv <= 15U)
            {
                cdiv = (int)temp_cdiv;
                break;
            }
        }
    }

    if (prsc > 7)
    {
        prsc = 7;  // 使用最大预分频器
        cdiv = 15; // 使用最大分频器
    }

    // 初始化 TWI 控制器
    neorv32_twi_setup(CLK_PRSC_128, 1, 0);
    // neorv32_twi_setup(prsc, cdiv, config->clock_stretch ? 1 : 0);

    return HAL_I2C_OK;
}

hal_i2c_status_t hal_i2c_deinit(void)
{
    if (!IS_I2C_AVAILABLE())
    {
        return HAL_I2C_NOT_AVAIL;
    }

    neorv32_twi_disable();
    return HAL_I2C_OK;
}

hal_i2c_status_t hal_i2c_enable(void)
{
    if (!IS_I2C_AVAILABLE())
    {
        return HAL_I2C_NOT_AVAIL;
    }

    neorv32_twi_enable();
    return HAL_I2C_OK;
}

hal_i2c_status_t hal_i2c_disable(void)
{
    if (!IS_I2C_AVAILABLE())
    {
        return HAL_I2C_NOT_AVAIL;
    }

    neorv32_twi_disable();
    return HAL_I2C_OK;
}

bool hal_i2c_is_busy(void)
{
    if (!IS_I2C_AVAILABLE())
    {
        return false;
    }

    return (neorv32_twi_busy() != 0);
}

int hal_i2c_get_fifo_depth(void)
{
    if (!IS_I2C_AVAILABLE())
    {
        return 0;
    }

    return neorv32_twi_get_fifo_depth();
}

hal_i2c_status_t hal_i2c_generate_start(void)
{
    if (!IS_I2C_AVAILABLE())
    {
        return HAL_I2C_NOT_AVAIL;
    }

    // 等待总线空闲
    if (hal_i2c_wait_not_busy(100) != HAL_I2C_OK)
    {
        return HAL_I2C_BUSY;
    }

    neorv32_twi_generate_start();
    return HAL_I2C_OK;
}

hal_i2c_status_t hal_i2c_generate_stop(void)
{
    if (!IS_I2C_AVAILABLE())
    {
        return HAL_I2C_NOT_AVAIL;
    }

    neorv32_twi_generate_stop();
    return HAL_I2C_OK;
}

hal_i2c_status_t hal_i2c_send_byte(uint8_t data, bool send_ack)
{
    if (!IS_I2C_AVAILABLE())
    {
        return HAL_I2C_NOT_AVAIL;
    }

    int result = neorv32_twi_transfer(&data, send_ack ? 1 : 0);

    if (result == 0)
    {
        return HAL_I2C_OK; // ACK received
    }
    else if (result == 1)
    {
        return HAL_I2C_NACK; // NACK received
    }
    else
    {
        return HAL_I2C_ERROR; // Other error
    }
}

hal_i2c_status_t hal_i2c_receive_byte(uint8_t *data, bool send_ack)
{
    if (!IS_I2C_AVAILABLE() || data == NULL)
    {
        return HAL_I2C_NOT_AVAIL;
    }

    int result = neorv32_twi_get(data);

    if (result == 0)
    {
        // 成功接收数据
        // 发送 ACK/NACK
        uint8_t dummy = 0;
        (void)neorv32_twi_transfer(&dummy, send_ack ? 1 : 0);
        return HAL_I2C_OK;
    }
    else
    {
        return HAL_I2C_ERROR;
    }
}

hal_i2c_status_t hal_i2c_master_write(uint8_t slave_addr, const uint8_t *data, uint16_t size, uint32_t timeout_ms)
{
    if (!IS_I2C_AVAILABLE() || data == NULL || size == 0)
    {
        return HAL_I2C_ERROR;
    }

    // 等待总线空闲
    if (hal_i2c_wait_not_busy(timeout_ms) != HAL_I2C_OK)
    {
        return HAL_I2C_BUSY;
    }

    // 生成 START 条件和从设备地址
    uint8_t addr_byte = (slave_addr << 1) | (uint8_t)(HAL_I2C_DIRECTION_WRITE & 0x01);

    // 发送 START + 地址
    if (hal_i2c_generate_start() != HAL_I2C_OK)
    {
        return HAL_I2C_ERROR;
    }

    if (hal_i2c_send_byte(addr_byte, true) != HAL_I2C_OK)
    {
        (void)hal_i2c_generate_stop();
        return HAL_I2C_NACK; // 设备未响应
    }

    // 发送数据
    for (uint16_t i = 0; i < size; i++)
    {
        if (hal_i2c_send_byte(data[i], true) != HAL_I2C_OK)
        {
            (void)hal_i2c_generate_stop();
            return HAL_I2C_NACK;
        }
    }

    // 生成 STOP 条件
    if (hal_i2c_generate_stop() != HAL_I2C_OK)
    {
        return HAL_I2C_ERROR;
    }

    return HAL_I2C_OK;
}

hal_i2c_status_t hal_i2c_master_read(uint8_t slave_addr, uint8_t *data, uint16_t size, uint32_t timeout_ms)
{
    if (!IS_I2C_AVAILABLE() || data == NULL || size == 0)
    {
        return HAL_I2C_ERROR;
    }

    // 等待总线空闲
    if (hal_i2c_wait_not_busy(timeout_ms) != HAL_I2C_OK)
    {
        return HAL_I2C_BUSY;
    }

    // 生成 START 条件和从设备地址
    uint8_t addr_byte = (slave_addr << 1) | (uint8_t)(HAL_I2C_DIRECTION_READ & 0x01);

    // 发送 START + 地址
    if (hal_i2c_generate_start() != HAL_I2C_OK)
    {
        return HAL_I2C_ERROR;
    }

    if (hal_i2c_send_byte(addr_byte, true) != HAL_I2C_OK)
    {
        (void)hal_i2c_generate_stop();
        return HAL_I2C_NACK; // 设备未响应
    }

    // 接收数据
    for (uint16_t i = 0; i < size; i++)
    {
        bool send_ack = (i < (size - 1)); // 最后一个字节发送 NACK
        if (hal_i2c_receive_byte(&data[i], send_ack) != HAL_I2C_OK)
        {
            (void)hal_i2c_generate_stop();
            return HAL_I2C_ERROR;
        }
    }

    // 生成 STOP 条件
    if (hal_i2c_generate_stop() != HAL_I2C_OK)
    {
        return HAL_I2C_ERROR;
    }

    return HAL_I2C_OK;
}

hal_i2c_status_t hal_i2c_master_write_read(uint8_t slave_addr,
                                           const uint8_t *write_data, uint16_t write_size,
                                           uint8_t *read_data, uint16_t read_size,
                                           uint32_t timeout_ms)
{
    if (!IS_I2C_AVAILABLE() || write_data == NULL || read_data == NULL ||
        write_size == 0 || read_size == 0)
    {
        return HAL_I2C_ERROR;
    }

    // 等待总线空闲
    if (hal_i2c_wait_not_busy(timeout_ms) != HAL_I2C_OK)
    {
        return HAL_I2C_BUSY;
    }

    // 第一阶段：写操作
    uint8_t addr_byte = (slave_addr << 1) | (uint8_t)(HAL_I2C_DIRECTION_WRITE & 0x01);

    // 发送 START + 地址
    if (hal_i2c_generate_start() != HAL_I2C_OK)
    {
        return HAL_I2C_ERROR;
    }

    if (hal_i2c_send_byte(addr_byte, true) != HAL_I2C_OK)
    {
        (void)hal_i2c_generate_stop();
        return HAL_I2C_NACK;
    }

    // 发送写数据
    for (uint16_t i = 0; i < write_size; i++)
    {
        if (hal_i2c_send_byte(write_data[i], true) != HAL_I2C_OK)
        {
            (void)hal_i2c_generate_stop();
            return HAL_I2C_NACK;
        }
    }

    // 第二阶段：读操作 (重复START)
    addr_byte = (slave_addr << 1) | (uint8_t)(HAL_I2C_DIRECTION_READ & 0x01);

    // 发送重复 START + 地址
    if (hal_i2c_generate_start() != HAL_I2C_OK)
    {
        (void)hal_i2c_generate_stop();
        return HAL_I2C_ERROR;
    }

    if (hal_i2c_send_byte(addr_byte, true) != HAL_I2C_OK)
    {
        (void)hal_i2c_generate_stop();
        return HAL_I2C_NACK;
    }

    // 接收读数据
    for (uint16_t i = 0; i < read_size; i++)
    {
        bool send_ack = (i < (read_size - 1)); // 最后一个字节发送 NACK
        if (hal_i2c_receive_byte(&read_data[i], send_ack) != HAL_I2C_OK)
        {
            (void)hal_i2c_generate_stop();
            return HAL_I2C_ERROR;
        }
    }

    // 生成 STOP 条件
    if (hal_i2c_generate_stop() != HAL_I2C_OK)
    {
        return HAL_I2C_ERROR;
    }

    return HAL_I2C_OK;
}

hal_i2c_status_t hal_i2c_probe_device(uint8_t slave_addr)
{
    if (!IS_I2C_AVAILABLE())
    {
        return HAL_I2C_NOT_AVAIL;
    }

    // 等待总线空闲
    if (hal_i2c_wait_not_busy(100) != HAL_I2C_OK)
    {
        return HAL_I2C_BUSY;
    }

    // 发送 START + 地址
    uint8_t addr_byte = (slave_addr << 1) | (uint8_t)(HAL_I2C_DIRECTION_WRITE & 0x01);

    if (hal_i2c_generate_start() != HAL_I2C_OK)
    {
        return HAL_I2C_ERROR;
    }

    hal_i2c_status_t result = hal_i2c_send_byte(addr_byte, true);

    // 生成 STOP 条件
    (void)hal_i2c_generate_stop();

    return result;
}

bool hal_i2c_get_scl_state(void)
{
    if (!IS_I2C_AVAILABLE())
    {
        return false;
    }

    return (neorv32_twi_sense_scl() != 0);
}

bool hal_i2c_get_sda_state(void)
{
    if (!IS_I2C_AVAILABLE())
    {
        return false;
    }

    return (neorv32_twi_sense_sda() != 0);
}

void hal_i2c_delay_us(uint32_t us)
{
    if (us == 0)
        return;

    uint32_t cycles = us * (NEORV32_SYSINFO->CLK / 1000000U);
    if (cycles == 0)
        cycles = 1; // 至少等待一个周期

    uint32_t start = neorv32_cpu_get_cycle();

    while ((neorv32_cpu_get_cycle() - start) < cycles)
    {
        // 空循环等待
    }
}

void hal_i2c_delay_ms(uint32_t ms)
{
    for (uint32_t i = 0; i < ms; i++)
    {
        hal_i2c_delay_us(1000);
    }
}

/* ========================================== */
/*              EEPROM 专用函数实现           */
/* ========================================== */
// 根据参考代码，AT24C04的寻址方式是特殊的
hal_i2c_status_t hal_i2c_eeprom_write_byte(uint8_t base_addr, uint16_t address, uint8_t data) {
    if (!IS_I2C_AVAILABLE()) {
        return HAL_I2C_NOT_AVAIL;
    }
    
    // 参考代码中的计算方式：
    // device_addr_byte = (base_addr << 1) | ((address >> 7) & 0x06) | 0;
    uint8_t device_addr_byte = (base_addr << 1) | ((address >> 7) & 0x06) | 0;
    
    // word_addr_byte = (uint8_t)(address & 0xFF);
    uint8_t word_addr_byte = (uint8_t)(address & 0xFF);

    // 生成START条件
    if (hal_i2c_generate_start() != HAL_I2C_OK) {
        return HAL_I2C_ERROR;
    }

    // 发送设备地址字节
    if (hal_i2c_send_byte(device_addr_byte, true) != HAL_I2C_OK) {
        (void)hal_i2c_generate_stop();
        return HAL_I2C_NACK;
    }

    // 发送内存地址字节
    if (hal_i2c_send_byte(word_addr_byte, true) != HAL_I2C_OK) {
        (void)hal_i2c_generate_stop();
        return HAL_I2C_NACK;
    }

    // 发送数据字节
    if (hal_i2c_send_byte(data, true) != HAL_I2C_OK) {
        (void)hal_i2c_generate_stop();
        return HAL_I2C_NACK;
    }

    // 生成STOP条件
    if (hal_i2c_generate_stop() != HAL_I2C_OK) {
        return HAL_I2C_ERROR;
    }
    
    // 等待EEPROM内部写入完成
    hal_i2c_delay_ms(5);
    
    return HAL_I2C_OK;
}

hal_i2c_status_t hal_i2c_eeprom_read_byte(uint8_t base_addr, uint16_t address, uint8_t* data) {
    if (!IS_I2C_AVAILABLE() || data == NULL) {
        return HAL_I2C_NOT_AVAIL;
    }
    
    // 参考代码中的计算方式：
    uint8_t device_addr_byte_write = (base_addr << 1) | ((address >> 7) & 0x06) | 0;  // 写操作
    uint8_t device_addr_byte_read = (base_addr << 1) | ((address >> 7) & 0x06) | 1;   // 读操作
    
    // 内存地址字节
    uint8_t word_addr_byte = (uint8_t)(address & 0xFF);
    
    uint8_t rx_data = 0;

    // --- 写阶段：设置内存地址 ---
    if (hal_i2c_generate_start() != HAL_I2C_OK) {
        return HAL_I2C_ERROR;
    }
    
    // 发送设备地址字节(写操作)
    if (hal_i2c_send_byte(device_addr_byte_write, true) != HAL_I2C_OK) {
        (void)hal_i2c_generate_stop();
        return HAL_I2C_NACK;
    }
    
    // 发送内存地址字节
    if (hal_i2c_send_byte(word_addr_byte, true) != HAL_I2C_OK) {
        (void)hal_i2c_generate_stop();
        return HAL_I2C_NACK;
    }

    // --- 读阶段：读取数据 ---
    // 生成重复START条件
    if (hal_i2c_generate_start() != HAL_I2C_OK) {
        (void)hal_i2c_generate_stop();
        return HAL_I2C_ERROR;
    }
    
    // 发送设备地址字节(读操作)
    if (hal_i2c_send_byte(device_addr_byte_read, true) != HAL_I2C_OK) {
        (void)hal_i2c_generate_stop();
        return HAL_I2C_NACK;
    }
    
    // 接收数据字节(发送NACK)
    if (hal_i2c_receive_byte(&rx_data, false) != HAL_I2C_OK) {
        (void)hal_i2c_generate_stop();
        return HAL_I2C_ERROR;
    }

    // 生成STOP条件
    if (hal_i2c_generate_stop() != HAL_I2C_OK) {
        return HAL_I2C_ERROR;
    }

    // 存储接收到的数据
    *data = rx_data;
    
    return HAL_I2C_OK;
}


int hal_i2c_bus_scan(uint8_t *found_devices, int max_devices)
{
    if (!IS_I2C_AVAILABLE() || found_devices == NULL || max_devices <= 0)
    {
        return 0;
    }

    int num_devices = 0;

    // 遍历所有可能的7位地址
    for (uint8_t addr = 0; addr < 128; addr++)
    {
        // 跳过保留地址
        if ((addr >= 0x00 && addr <= 0x07) || (addr >= 0x78 && addr <= 0x7F))
        {
            continue;
        }

        // 生成START条件
        if (hal_i2c_generate_start() != HAL_I2C_OK)
        {
            continue;
        }

        // 准备设备地址(写操作)
        uint8_t addr_rw = (addr << 1) | 0;

        // 尝试传输地址并检查ACK
        hal_i2c_status_t result = hal_i2c_send_byte(addr_rw, true);

        // 生成STOP条件
        (void)hal_i2c_generate_stop();

        // 如果收到ACK，设备存在
        if (result == HAL_I2C_OK)
        {
            if (num_devices < max_devices)
            {
                found_devices[num_devices] = addr;
            }
            num_devices++;
        }

        // 短暂延时避免总线过载
        hal_i2c_delay_us(100);
    }

    return (num_devices > max_devices) ? max_devices : num_devices;
}

/* ========================================== */
/*              私有函数实现                  */
/* ========================================== */

static hal_i2c_status_t hal_i2c_wait_not_busy(uint32_t timeout_ms)
{
    if (!IS_I2C_AVAILABLE())
    {
        return HAL_I2C_NOT_AVAIL;
    }

    if (timeout_ms == 0)
    {
        // 无超时等待
        while (neorv32_twi_busy())
        {
            // 空循环
        }
        return HAL_I2C_OK;
    }

    uint32_t timeout_cycles = timeout_ms * (NEORV32_SYSINFO->CLK / 1000U);
    uint32_t start_time = neorv32_cpu_get_cycle();

    while (neorv32_twi_busy())
    {
        // 检查超时
        if ((neorv32_cpu_get_cycle() - start_time) > timeout_cycles)
        {
            return HAL_I2C_TIMEOUT;
        }
    }

    return HAL_I2C_OK;
}
