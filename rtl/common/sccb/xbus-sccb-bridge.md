
这是一个针对 **NEORV32 软核**与 **OV5640 摄像头**应用场景优化的完整设计方案（方案 A）。

本方案的核心理念是 **"硬件极简，软件灵活"**。利用 NEORV32 的 32 位数据总线优势，将复杂的 I2C/SCCB 协议数据打包工作交给软件完成，从而极大简化硬件逻辑，提高系统稳定性。

---

## NEORV32 Wishbone SCCB/I2C 接口控制器方案

### 1. 系统架构

该设计通过一个轻量级的 Wrapper 模块将标准的 Wishbone 总线信号转换为 `uii2c` 模块所需的控制信号。

```mermaid
graph LR
    CPU[NEORV32 CPU] --"Wishbone (32-bit)"--> WB_Wrapper[wb_ov5640_i2c_wrapper]
    WB_Wrapper --"Control & Data"--> UII2C[uii2c Core]
    UII2C --"SCCB / I2C"--> OV5640[OV5640 Sensor]
```

### 2. 寄存器映射 (Register Map)

基地址由 SoC 总线互联逻辑分配（例如 `0xF0000000`）。所有寄存器均为 32 位宽。

|偏移地址|寄存器名称|读/写|功能描述|
|---|---|---|---|
|**0x00**|**REG_CTRL**|R/W|**控制寄存器**`Bit 0`: **START** (写1启动传输，传输开始后自动清零)`Bit 1`: **MODE** (0=普通/页读写, 1=SCCB/随机读)|
|**0x04**|**REG_STATUS**|RO|**状态寄存器**`Bit 0`: **BUSY** (1=总线忙，0=空闲)|
|**0x08**|**REG_CFG**|R/W|**长度配置寄存器**`Bit [7:0]`: **WR_CNT** (写字节数，含器件地址)`Bit [15:8]`: **RD_CNT** (读字节数)|
|**0x0C**|**REG_TX**|R/W|**发送数据寄存器** (32-bit)直接映射到 I2C 写缓冲。软件需按 `Byte0(DevAddr) -> Byte1 -> Byte2…` 的顺序将数据打包写入此寄存器。|
|**0x10**|**REG_RX**|RO|**接收数据寄存器**低 8 位有效，存储读取到的 I2C 数据。|

---

### 3. 硬件 RTL 代码

#### 3.1 Wishbone Wrapper (`wb_ov5640_i2c_wrapper.v`)

```verilog
`timescale 1ns / 1ps

module wb_ov5640_i2c_wrapper #(
    parameter CLK_FREQ = 100_000_000, // Wishbone 系统时钟频率 (Hz)
    parameter I2C_FREQ = 200_000      // 目标 SCCB/I2C 时钟频率 (Hz)
)(
    // Wishbone Interface
    input  wire        wb_clk_i,
    input  wire        wb_rst_i,
    input  wire        wb_stb_i,
    input  wire        wb_cyc_i,
    input  wire        wb_we_i,
    input  wire [31:0] wb_dat_i,
    input  wire [3:0]  wb_sel_i, // Ignored, assumes 32-bit access
    input  wire [2:0]  wb_adr_i, // Connected to adr_i[4:2] typically
    output reg  [31:0] wb_dat_o,
    output reg         wb_ack_o,

    // External I2C Interface
    output wire        i2c_scl,
    inout  wire        i2c_sda
);

    // --- 内部信号 ---
    reg [31:0] tx_data_reg;    // 发送数据缓冲
    reg [15:0] counts_reg;     // {rd_cnt, wr_cnt}
    reg        ctrl_mode;      // 0=Normal, 1=SCCB/Random
    reg        start_pulse;    // 启动信号
    
    wire [7:0] rx_data_wire;   // 接收数据
    wire       iic_busy;       // 忙状态

    // --- Wishbone 总线逻辑 ---
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            tx_data_reg <= 32'd0;
            counts_reg  <= 16'd0;
            ctrl_mode   <= 1'b0;
            start_pulse <= 1'b0;
            wb_ack_o    <= 1'b0;
        end else begin
            // 自动清除 Start 信号：当检测到 Busy 或传输已触发时
            if (iic_busy || start_pulse) start_pulse <= 1'b0; 
            
            // 生成 ACK 信号 (单周期延迟)
            wb_ack_o <= wb_stb_i && wb_cyc_i && !wb_ack_o;

            // 写寄存器逻辑
            if (wb_stb_i && wb_cyc_i && wb_we_i && !wb_ack_o) begin
                case (wb_adr_i) 
                    3'd0: begin // REG_CTRL (0x00)
                        start_pulse <= wb_dat_i[0];
                        ctrl_mode   <= wb_dat_i[1];
                    end
                    3'd2: counts_reg  <= wb_dat_i[15:0]; // REG_CFG (0x08)
                    3'd3: tx_data_reg <= wb_dat_i;       // REG_TX (0x0C)
                endcase
            end
        end
    end

    // 读寄存器逻辑
    always @(*) begin
        wb_dat_o = 32'd0;
        case (wb_adr_i)
            3'd0: wb_dat_o = {30'd0, ctrl_mode, 1'b0}; // REG_CTRL (Start自动读0)
            3'd1: wb_dat_o = {31'd0, iic_busy};        // REG_STATUS (0x04)
            3'd2: wb_dat_o = {16'd0, counts_reg};      // REG_CFG (0x08)
            3'd3: wb_dat_o = tx_data_reg;              // REG_TX (0x0C)
            3'd4: wb_dat_o = {24'd0, rx_data_wire};    // REG_RX (0x10)
            default: wb_dat_o = 32'd0;
        endcase
    end

    // --- 实例化 I2C 核心 ---
    // 自动计算分频系数: System_Clk / (4 * I2C_Freq)
    localparam CALC_DIV = (CLK_FREQ / (I2C_FREQ * 4));

    uii2c #(
        .WMEN_LEN('d4),      // 32-bit Write Buffer
        .RMEN_LEN('d1),      // 8-bit Read Buffer
        .CLK_DIV(CALC_DIV)   // Auto Calculated Divider
    ) u_i2c_core (
        .i_clk      (wb_clk_i),
        .o_iic_scl  (i2c_scl),
        .io_iic_sda (i2c_sda),
        
        .i_wr_data  (tx_data_reg),      // [31:0]
        .i_wr_cnt   (counts_reg[7:0]),  // Write Count
        .o_rd_data  (rx_data_wire),     // [7:0]
        .i_rd_cnt   (counts_reg[15:8]), // Read Count
        
        .i_iic_en   (start_pulse),
        .i_iic_mode (ctrl_mode),
        .o_iic_busy (iic_busy),
        .o_sda_dg   ()
    );

endmodule
```

#### 3.2 I2C Core (`uii2c.v`)

_注意：参数已根据您的要求修改为适配 32位写/8位读。_

```verilog
`timescale 1ns / 1ps

module uii2c #(
    parameter WMEN_LEN = 'd4,  // 写数据最大字节数 (32-bit)
    parameter RMEN_LEN = 'd1,  // 读数据最大字节数 (8-bit)
    parameter CLK_DIV  = 'd499 // 默认分频，会被顶层覆盖
) (
    input  wire [0 : 0]             i_clk,
    output wire [0 : 0]             o_iic_scl,
    inout  wire [0 : 0]             io_iic_sda,
    input  wire [WMEN_LEN * 8 - 1 : 0] i_wr_data,
    input  wire [7 : 0]              i_wr_cnt,
    output wire [RMEN_LEN * 8 - 1 : 0] o_rd_data,
    input  wire [7 : 0]              i_rd_cnt,
    input  wire [0 : 0]              i_iic_en,
    input  wire [0 : 0]              i_iic_mode,
    output wire [0 : 0]              o_iic_busy,
    output wire [0 : 0]              o_sda_dg
);

// ... (此处保留您原始提供的 uii2c 内部逻辑代码，无需变动，
//      仅确保 IOBUF, PULLUP 等原语在您的 FPGA 平台可用) ...
// ... (为节省篇幅，省略内部状态机代码，逻辑与前文分析一致) ...
// 关键点：wcnt 逻辑会自动处理 32位 i_wr_data 的切片
// sda_r <= i_wr_data[(wcnt * 8) +: 8]; 

    // --- 简略版内部逻辑占位 (请使用完整的 uii2c.v) ---
    // 必须包含完整的状态机实现
    // ...
    
endmodule
```

---

### 4. 软件驱动代码 (C 语言)

以下代码可直接用于 NEORV32 的软件工程中。

#### 4.1 头文件定义

```c
#include <stdint.h>

// 根据 SoC 地址映射修改基地址
#define I2C_BASE_ADDR 0xF0000000 

// 寄存器结构体映射
typedef struct {
    volatile uint32_t CTRL;   // 0x00
    volatile uint32_t STATUS; // 0x04
    volatile uint32_t CFG;    // 0x08
    volatile uint32_t TX;     // 0x0C
    volatile uint32_t RX;     // 0x10
} wb_i2c_t;

#define WB_I2C ((wb_i2c_t *)I2C_BASE_ADDR)

// OV5640 I2C 地址 (7-bit: 0x3C, Write: 0x78, Read: 0x79)
#define OV5640_ADDR_WR 0x78
```

#### 4.2 驱动函数实现

```c
// 检查总线是否忙碌
static inline void i2c_wait_busy(void) {
    while (WB_I2C->STATUS & 0x01);
}

/**
 * @brief 写 OV5640 寄存器 (16位地址, 8位数据)
 * 
 * 硬件打包逻辑 (Little Endian):
 * TX[7:0]   = Device Addr (0x78)
 * TX[15:8]  = Reg Addr High
 * TX[23:16] = Reg Addr Low
 * TX[31:24] = Data
 */
void ov5640_write_reg(uint16_t reg_addr, uint8_t data) {
    i2c_wait_busy();

    // 1. 准备数据包 (注意字节序)
    uint32_t payload = 0;
    payload |= (uint32_t)OV5640_ADDR_WR;             // Byte 0: DevAddr
    payload |= (uint32_t)((reg_addr >> 8) & 0xFF) << 8;  // Byte 1: RegH
    payload |= (uint32_t)(reg_addr & 0xFF) << 16;        // Byte 2: RegL
    payload |= (uint32_t)data << 24;                     // Byte 3: Data

    // 2. 写入数据寄存器
    WB_I2C->TX = payload;

    // 3. 配置传输长度: 写4字节，读0字节
    // CFG = (RdCnt << 8) | WrCnt
    WB_I2C->CFG = (0 << 8) | 4;

    // 4. 启动传输: Start=1, Mode=0 (Normal Write)
    WB_I2C->CTRL = 0x01;
}

/**
 * @brief 读取 OV5640 寄存器 (SCCB 协议)
 * 
 * SCCB 读操作分为两步:
 * 1. 写阶段: 发送 DevAddr + RegAddrH + RegAddrL (不带 Stop, 而是 Restart)
 * 2. 读阶段: 发送 DevAddr(Read) + 读取数据
 * 
 * uii2c 模块在 Mode=1 时自动处理中间的 Restart 和读阶段地址发送
 */
uint8_t ov5640_read_reg(uint16_t reg_addr) {
    i2c_wait_busy();

    // 1. 准备写阶段数据包
    // 注意：SCCB 读只需要写入地址部分，不需要写入数据
    uint32_t payload = 0;
    payload |= (uint32_t)OV5640_ADDR_WR;             // Byte 0: DevAddr
    payload |= (uint32_t)((reg_addr >> 8) & 0xFF) << 8;  // Byte 1: RegH
    payload |= (uint32_t)(reg_addr & 0xFF) << 16;        // Byte 2: RegL
    // Byte 3 unused

    // 2. 写入数据寄存器
    WB_I2C->TX = payload;

    // 3. 配置传输长度
    // 写 3 字节 (Dev + RegH + RegL)
    // 读 1 字节
    WB_I2C->CFG = (1 << 8) | 3;

    // 4. 启动传输: Start=1, Mode=1 (SCCB/Random Read)
    WB_I2C->CTRL = 0x03;

    // 5. 等待完成
    i2c_wait_busy();

    // 6. 获取结果 (低8位)
    return (uint8_t)(WB_I2C->RX & 0xFF);
}
```

### 5. 设计总结

1. **极简集成**: 仅需实例化 Wrapper 并连接 Wishbone 总线。
2. **OV5640 完美适配**: 驱动代码专门针对 OV5640 的 16 位寄存器结构编写，通过软件位移操作解决数据打包问题。
3. **资源占用低**: 相比通用 I2C IP，省去了复杂的 FIFO 和中断逻辑，非常适合资源受限的 FPGA 或嵌入式软核应用。
