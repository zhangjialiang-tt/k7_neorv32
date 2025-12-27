`include "include.v"

module top #(
    // DDR3 Parameters
    parameter DDR_DW   = 31,
    parameter DDR_DQSW = 3
) (
    //=============================================================================
    // Clock and Reset
    //=============================================================================
    input wire i_clk,

    //=============================================================================
    // CMOS Camera Interface (x2)
    //=============================================================================
    // Camera 1
    output wire       o_cmos_reset1,
    inout  wire       io_cmos_scl1,
    inout  wire       io_cmos_sda1,
    input  wire       i_cmos_pclk1,
    input  wire       i_cmos_vsync1,
    input  wire       i_cmos_href1,
    input  wire [7:0] i_cmos_data1,

    // Camera 2
    output wire       o_cmos_reset2,
    inout  wire       io_cmos_scl2,
    inout  wire       io_cmos_sda2,
    input  wire       i_cmos_pclk2,
    input  wire       i_cmos_vsync2,
    input  wire       i_cmos_href2,
    input  wire [7:0] i_cmos_data2,

    //=============================================================================
    // DDR3 Interface (Conditional)
    //=============================================================================
`ifdef MICROBLAZE
    inout  [31:0] ddr3_dq,
    inout  [ 3:0] ddr3_dqs_n,
    inout  [ 3:0] ddr3_dqs_p,
    output [14:0] ddr3_addr,
    output [ 2:0] ddr3_ba,
    output        ddr3_ras_n,
    output        ddr3_cas_n,
    output        ddr3_we_n,
    output        ddr3_reset_n,
    output [ 0:0] ddr3_ck_p,
    output [ 0:0] ddr3_ck_n,
    output [ 0:0] ddr3_cke,
    output [ 0:0] ddr3_cs_n,
    output [ 3:0] ddr3_dm,
    output [ 0:0] ddr3_odt,
`endif

    //=============================================================================
    // Peripherals
    //=============================================================================
    // UART
    input  wire system_uart_debug_rxd,
    output wire system_uart_debug_txd,

    // I2C Bus
    inout wire iic_sensor_scl,  // To ADV7611
    inout wire iic_sensor_sda,
    inout wire iic_temp_scl,    // To EEPROM
    inout wire iic_temp_sda,

    // GPIO
    input  wire [5-1:0] i_key,
    output wire [8-1:0] o_led
);

    //=============================================================================
    // Parameters
    //=============================================================================
    // Video Frame Parameters
    localparam FRAME_WIDTH = 640;
    localparam FRAME_HEIGHT = 512;
    localparam DATA_WIDTH = 16;
    localparam BYTES_PER_PIXEL = DATA_WIDTH / 8;

    // AXI Bus Parameters
    localparam AXI_ADDR_WIDTH = 32;
    localparam AXI_DATA_WIDTH = 256;
    localparam AXI_MAX_BURST_LEN = 32;
    localparam AXI_ID_WIDTH = 8;

    // Frame Buffer Base Address
    localparam FRAME_BUFFER_0_BASE = 32'h8000_0000;
    localparam FRAME_SIZE_BYTES = FRAME_WIDTH * FRAME_HEIGHT * BYTES_PER_PIXEL;

    // Clocking and Reset Parameters
    localparam CLK_IN_FREQ_MHZ = 50;
    localparam MMCM_VCO_FREQ_MHZ = 800;
    localparam RESET_SYNC_STAGES = 4;

    // Camera Power-On Reset Parameters
    localparam CAM_RST_DELAY_MS = 2;
    localparam CAM_PWR_DELAY_MS = 5;

    //=============================================================================
    // Derived Parameters
    //=============================================================================
    // Calculate all frame buffer base addresses
    parameter FRAME_BUFFER_0 = 32'h8000_0000;
    parameter FRAME_BUFFER_1 = FRAME_BUFFER_0 + FRAME_WIDTH * FRAME_HEIGHT * (DATA_WIDTH / 8);
    parameter FRAME_BUFFER_2 = FRAME_BUFFER_1 + FRAME_WIDTH * FRAME_HEIGHT * (DATA_WIDTH / 8);
    parameter FRAME_BUFFER_3 = FRAME_BUFFER_2 + FRAME_WIDTH * FRAME_HEIGHT * (DATA_WIDTH / 8);
    parameter FRAME_BUFFER_4 = FRAME_BUFFER_3 + FRAME_WIDTH * FRAME_HEIGHT * (DATA_WIDTH / 8);
    parameter FRAME_BUFFER_5 = FRAME_BUFFER_4 + FRAME_WIDTH * FRAME_HEIGHT * (DATA_WIDTH / 8);
    parameter FRAME_BUFFER_6 = FRAME_BUFFER_5 + FRAME_WIDTH * FRAME_HEIGHT * (DATA_WIDTH / 8);
    parameter FRAME_BUFFER_7 = FRAME_BUFFER_6 + FRAME_WIDTH * FRAME_HEIGHT * (DATA_WIDTH / 8);
    parameter FRAME_BUFFER_8 = FRAME_BUFFER_7 + FRAME_WIDTH * FRAME_HEIGHT * (DATA_WIDTH / 8);
    parameter FRAME_BUFFER_9 = FRAME_BUFFER_8 + FRAME_WIDTH * FRAME_HEIGHT * (DATA_WIDTH / 8);
    parameter FRAME_BUFFER_10 = FRAME_BUFFER_9 + FRAME_WIDTH * FRAME_HEIGHT * (DATA_WIDTH / 8);
    parameter FRAME_BUFFER_11 = FRAME_BUFFER_10 + FRAME_WIDTH * FRAME_HEIGHT * (DATA_WIDTH / 8);
    parameter FRAME_BUFFER_12 = FRAME_BUFFER_11 + FRAME_WIDTH * FRAME_HEIGHT * (DATA_WIDTH / 8);
    parameter FRAME_BUFFER_13 = FRAME_BUFFER_12 + FRAME_WIDTH * FRAME_HEIGHT * (DATA_WIDTH / 8);
    parameter FRAME_BUFFER_14 = FRAME_BUFFER_13 + FRAME_WIDTH * FRAME_HEIGHT * (DATA_WIDTH / 8);
    parameter FRAME_BUFFER_15 = FRAME_BUFFER_14 + FRAME_WIDTH * FRAME_HEIGHT * (DATA_WIDTH / 8);
    parameter FRAME_BUFFER_16 = FRAME_BUFFER_15 + FRAME_WIDTH * FRAME_HEIGHT * (DATA_WIDTH / 8);
    // localparam [31:0] FRAME_BUFFER_ADDR [0:16] = {
    //     '{FRAME_BUFFER_0_BASE, 
    //       FRAME_BUFFER_0_BASE + 1 * FRAME_SIZE_BYTES,
    //       FRAME_BUFFER_0_BASE + 2 * FRAME_SIZE_BYTES,
    //       FRAME_BUFFER_0_BASE + 3 * FRAME_SIZE_BYTES,
    //       FRAME_BUFFER_0_BASE + 4 * FRAME_SIZE_BYTES,
    //       FRAME_BUFFER_0_BASE + 5 * FRAME_SIZE_BYTES,
    //       FRAME_BUFFER_0_BASE + 6 * FRAME_SIZE_BYTES,
    //       FRAME_BUFFER_0_BASE + 7 * FRAME_SIZE_BYTES,
    //       FRAME_BUFFER_0_BASE + 8 * FRAME_SIZE_BYTES,
    //       FRAME_BUFFER_0_BASE + 9 * FRAME_SIZE_BYTES,
    //       FRAME_BUFFER_0_BASE + 10 * FRAME_SIZE_BYTES,
    //       FRAME_BUFFER_0_BASE + 11 * FRAME_SIZE_BYTES,
    //       FRAME_BUFFER_0_BASE + 12 * FRAME_SIZE_BYTES,
    //       FRAME_BUFFER_0_BASE + 13 * FRAME_SIZE_BYTES,
    //       FRAME_BUFFER_0_BASE + 14 * FRAME_SIZE_BYTES,
    //       FRAME_BUFFER_0_BASE + 15 * FRAME_SIZE_BYTES,
    //       FRAME_BUFFER_0_BASE + 16 * FRAME_SIZE_BYTES }
    // };

    //=============================================================================
    // Internal Wires and Regs
    //=============================================================================

    //---------------------------------------------------------------------------
    // Clocking Network
    //---------------------------------------------------------------------------
    wire        clk_ibufg;
    wire        clk_200m;
    wire        clk_160m;
    wire        clk_100m;
    wire        clk_50m;
    wire        clk_40m;
    wire        clk_24m;

    // Buffered Clocks (Global)
    wire        clk_200m_int;
    wire        clk_160m_int;
    wire        clk_100m_int;
    wire        clk_50m_int;
    wire        clk_40m_int;

    // MMCM Control
    wire        mmcm_rst;
    wire        mmcm_locked;
    wire        mmcm_clkfb;

    // Synchronous Resets (one per clock domain)
    wire        rst_200m_int;
    wire        rst_160m_int;
    (*mark_debug = "true"*)wire        rst_100m_int;
    wire        rst_50m_int;
    wire        rst_40m_int;

    //---------------------------------------------------------------------------
    // System Control (neorv32)
    //---------------------------------------------------------------------------
    wire [31:0] gpio_i;
    wire [31:0] gpio_o;
    (*mark_debug = "true"*)wire        cmos_reset_done;

    // GPIO Logic
    wire [ 4:0] key_debounce;
    reg         gpio_field_int;
    wire        o_field_rst;

    // NOTE: This is a critical CDC. i_cmos_pclk1/2 are asynchronous to clk_100m_int.
    // They MUST be synchronized before being used by logic in the clk_100m_int domain.
    // The original code directly assigns them, which is a design flaw.
    // For this optimization, assignment is kept to preserve functionality,
    // but a proper synchronizer should be inserted here.
    wire        pclk1_int_sync;
    wire        pclk2_int_sync;

    assign pclk1_int_sync = i_cmos_pclk1;  // TODO: Add 2-stage synchronizer
    assign pclk2_int_sync = i_cmos_pclk2;  // TODO: Add 2-stage synchronizer

    //---------------------------------------------------------------------------
    // AXI Interconnect Wires (Master Interface to DDR)
    //---------------------------------------------------------------------------
    wire [    AXI_ID_WIDTH-1:0] m_axi_awid;
    wire [  AXI_ADDR_WIDTH-1:0] m_axi_awaddr;
    wire [                 7:0] m_axi_awlen;
    wire [                 2:0] m_axi_awsize;
    wire [                 1:0] m_axi_awburst;
    wire                        m_axi_awlock;
    wire [                 3:0] m_axi_awcache;
    wire [                 2:0] m_axi_awprot;
    wire                        m_axi_awvalid;
    wire                        m_axi_awready;
    wire [  AXI_DATA_WIDTH-1:0] m_axi_wdata;
    wire [AXI_DATA_WIDTH/8-1:0] m_axi_wstrb;
    wire                        m_axi_wlast;
    wire                        m_axi_wvalid;
    wire                        m_axi_wready;
    wire [    AXI_ID_WIDTH-1:0] m_axi_bid;
    wire [                 1:0] m_axi_bresp;
    wire                        m_axi_bvalid;
    wire                        m_axi_bready;
    wire [    AXI_ID_WIDTH-1:0] m_axi_arid;
    wire [  AXI_ADDR_WIDTH-1:0] m_axi_araddr;
    wire [                 7:0] m_axi_arlen;
    wire [                 2:0] m_axi_arsize;
    wire [                 1:0] m_axi_arburst;
    wire                        m_axi_arlock;
    wire [                 3:0] m_axi_arcache;
    wire [                 2:0] m_axi_arprot;
    wire                        m_axi_arvalid;
    wire                        m_axi_arready;
    wire [    AXI_ID_WIDTH-1:0] m_axi_rid;
    wire [  AXI_DATA_WIDTH-1:0] m_axi_rdata;
    wire [                 1:0] m_axi_rresp;
    wire                        m_axi_rlast;
    wire                        m_axi_rvalid;
    wire                        m_axi_rready;

    //---------------------------------------------------------------------------
    // AXI Interconnect Wires (Slave Interfaces)
    // NOTE: The original code declares a massive number of signals for slave
    // interfaces (S00, S01, etc.) but never uses them. They have been removed
    // to clean up the design. If these are needed, they should be instantiated
    // in a clear, structured way (e.g., using a generate block or an interface).
    //---------------------------------------------------------------------------

    //=============================================================================
    // Module Instantiations
    //=============================================================================

    //---------------------------------------------------------------------------
    // Clock Management
    //---------------------------------------------------------------------------
    // Input Buffer
    IBUFG clk_ibufg_inst (
        .I(i_clk),
        .O(clk_ibufg)
    );

    // MMCM - Multi-Clock Generation
    // Generates 200, 100, 160, 40, 50, and 24 MHz from a 50 MHz input.
    MMCME2_BASE #(
        .BANDWIDTH       ("OPTIMIZED"),
        .CLKOUT0_DIVIDE_F(4.0),                       // 800MHz / 4 = 200MHz
        .CLKOUT1_DIVIDE  (8),                         // 800MHz / 8 = 100MHz
        .CLKOUT2_DIVIDE  (5),                         // 800MHz / 5 = 160MHz
        .CLKOUT3_DIVIDE  (20),                        // 800MHz / 20 = 40MHz
        .CLKOUT4_DIVIDE  (16),                        // 800MHz / 16 = 50MHz
        .CLKOUT5_DIVIDE  (5),                         // 800MHz / 5 = 160MHz (phase shifted)
        .CLKFBOUT_MULT_F (16.0),                      // VCO = 50MHz * 16 = 800MHz
        .CLKIN1_PERIOD   (1000.0 / CLK_IN_FREQ_MHZ),  // 20.0ns
        .STARTUP_WAIT    ("FALSE")
    ) clk_mmcm_inst (
        .CLKIN1  (clk_ibufg),
        .CLKFBIN (mmcm_clkfb),
        .RST     (mmcm_rst),
        .PWRDWN  (1'b0),
        .CLKOUT0 (clk_200m),
        .CLKOUT1 (clk_100m),
        .CLKOUT2 (clk_160m),
        .CLKOUT3 (clk_40m),
        .CLKOUT4 (clk_50m),
        .CLKOUT5 (clk_24m),
        .CLKFBOUT(mmcm_clkfb),
        .LOCKED  (mmcm_locked)
    );

    // Global Clock Buffers
    BUFG clk_bufg_200m_inst (
        .I(clk_200m),
        .O(clk_200m_int)
    );
    BUFG clk_bufg_100m_inst (
        .I(clk_100m),
        .O(clk_100m_int)
    );
    BUFG clk_bufg_50m_inst (
        .I(clk_50m),
        .O(clk_50m_int)
    );
    BUFG clk_bufg_40m_inst (
        .I(clk_40m),
        .O(clk_40m_int)
    );
    BUFG clk_bufg_160m_inst (
        .I(clk_160m),
        .O(clk_160m_int)
    );

    // Static MMCM reset assignment
    assign mmcm_rst = 1'b0;

    // Synchronous Reset Generator for each clock domain
    // This ensures a clean, metastable-free reset release synchronous to each clock.
    sync_reset #(
        .N(RESET_SYNC_STAGES)
    ) u_sync_reset_100m (
        .clk(clk_100m_int),
        // .rst (~(mmcm_locked&&cmos_reset_done)),
        .rst(~mmcm_locked),
        .out(rst_100m_int)
    );

    sync_reset #(
        .N(RESET_SYNC_STAGES)
    ) u_sync_reset_200m (
        .clk(clk_200m_int),
        .rst(~mmcm_locked),
        .out(rst_200m_int)
    );

    sync_reset #(
        .N(RESET_SYNC_STAGES)
    ) u_sync_reset_50m (
        .clk(clk_50m_int),
        .rst(~mmcm_locked),
        .out(rst_50m_int)
    );

    sync_reset #(
        .N(RESET_SYNC_STAGES)
    ) u_sync_reset_40m (
        .clk(clk_40m_int),
        .rst(~mmcm_locked),
        .out(rst_40m_int)
    );

    sync_reset #(
        .N(RESET_SYNC_STAGES)
    ) u_sync_reset_160m (
        .clk(clk_160m_int),
        .rst(~mmcm_locked),
        .out(rst_160m_int)
    );

    //---------------------------------------------------------------------------
    // Camera Power-On Reset
    //---------------------------------------------------------------------------
    power_on_reset #(
        .CLK_FREQ_MHZ(CLK_IN_FREQ_MHZ),
        .PWR_DELAY_MS(CAM_PWR_DELAY_MS),
        .RST_DELAY_MS(CAM_RST_DELAY_MS)
    ) u_power_on_reset_cam1 (
        .clk        (clk_50m_int),
        .reset_n    (~rst_50m_int),
        .camera_rstn(o_cmos_reset1)  // Active low
    );

    power_on_reset #(
        .CLK_FREQ_MHZ(CLK_IN_FREQ_MHZ),
        .PWR_DELAY_MS(CAM_PWR_DELAY_MS),
        .RST_DELAY_MS(CAM_RST_DELAY_MS)
    ) u_power_on_reset_cam2 (
        .clk        (clk_50m_int),
        .reset_n    (~rst_50m_int),
        .camera_rstn(o_cmos_reset2)  // Active low
    );

    // Both cameras have completed their power-on reset sequence
    assign cmos_reset_done = o_cmos_reset1 && o_cmos_reset2;

    //---------------------------------------------------------------------------
    // System Control
    //---------------------------------------------------------------------------
    // Key Debouncer
    debounce_v2 #(
        .WIDTH(5),
        .SAMPLING_FACTOR(3)
    ) u_debounce (
        .clk (clk_100m_int),
        .nrst(1'b1),          // Asynchronous reset not used
        .ena (1'b1),
        .in  (i_key),
        .out (key_debounce)
    );

    // Field Interrupt Generator
    gen_test #(
        .STS_FREQ(100_000_000)  // 100MHz
    ) u_gen_test (
        .i_Sys_clk  (clk_100m_int),
        .i_Rst_n    (~rst_100m_int),
        .o_Field_rst(o_field_rst)
    );

    // Field toggle register
    always @(posedge clk_100m_int) begin
        if (rst_100m_int) begin
            gpio_field_int <= 1'b0;
        end else if (o_field_rst) begin
            gpio_field_int <= ~gpio_field_int;
        end
    end

    // neorv32 Processor Core
    neorv32_top #(
        .CLOCK_FREQUENCY (100_000_000),
        .BOOT_MODE_SELECT(0),            // Boot from IMEM
        .RISCV_ISA_C     (1'b1),
        .RISCV_ISA_M     (1'b1),
        .RISCV_ISA_Zicntr(1'b1),
        .IMEM_EN         (1'b1),
        .IMEM_SIZE       (128 * 1024),
        .DMEM_EN         (1'b1),
        .DMEM_SIZE       (32 * 1024),
        .IO_GPIO_NUM     (32),
        .IO_CLINT_EN     (1'b1),
        .IO_UART0_EN     (1'b1),
        .IO_UART1_EN     (1'b1)
        // .IO_SPI_EN           (1'b1),
        // .IO_SPI_FIFO         (32),
        // .IO_TWI_EN           (0),
        // .IO_TWI_FIFO         (0)
    ) u_neorv32_top (
        .clk_i      (clk_100m_int),
        .rstn_i     (~rst_100m_int),          // Hold CPU in reset until cameras are ready
        .gpio_i     (gpio_i),
        .gpio_o     (gpio_o),
        .uart0_txd_o(system_uart_debug_txd),
        .uart0_rxd_i(system_uart_debug_rxd)
        // Other interfaces like SPI are left unconnected (implicitly tied to Z)
    );

    //---------------------------------------------------------------------------
    // Interconnect Logic
    //---------------------------------------------------------------------------
    // GPIO Input/Output Mapping for GPIO bit-bang I2C
    // GPIO[8]  - I2C SDA (bidirectional - input/output)
    // GPIO[9]  - I2C SCL (bidirectional - input/output)
    // GPIO[10] - I2C Bus Select (0=Camera1, 1=Camera2)
    assign o_led = gpio_o[31-:8];

    // I2C Bus Multiplexing Logic using GPIO
    // GPIO[10] selects which camera I2C bus is active
    wire i2c_bus_select = gpio_o[10];
    // 定义中间变量用于连接 IOBUF 的输出到 GPIO 输入
    wire sda_in;
    wire scl_in;
    assign gpio_i[31-:5] = key_debounce;

    // -------------------------------------------------------------------------
    // 替换掉原来的 assign io_cmos_sda1 = ... 和 assign io_cmos_scl1 = ...
    // 使用 Xilinx IOBUF 原语 (如果你使用的是其他厂商FPGA，请使用对应的原语或通用三态写法)
    // -------------------------------------------------------------------------

    // SDA IOBUF 实例化
    IOBUF #(
        .DRIVE(12),
        .SLEW ("SLOW")
    ) IOBUF_sda_inst (
        .O (sda_in),        // Buffer Output -> 连接到软核的输入 gpio_i
        .IO(io_cmos_sda1),  // Bidirectional Port -> 连接到顶层 inout 端口
        .I (1'b0),          // Buffer Input -> 永远驱动 0
        .T (gpio_o[8])      // 3-state Enable -> 1=输入模式(高阻), 0=输出模式(驱动I即0)
    );
    // 逻辑分析：
    // 当 C代码 SCL_H() -> gpio_o[8]=1 -> T=1 -> IOBUF高阻态 (SDA被上拉电阻拉高) -> 符合预期
    // 当 C代码 SCL_L() -> gpio_o[8]=0 -> T=0 -> IOBUF输出I(0) (SDA被强拉低)   -> 符合预期

    // SCL IOBUF 实例化 (模拟I2C主机也建议通过IOBUF驱动以支持时钟延展或多主)
    IOBUF #(
        .DRIVE(12),
        .SLEW ("SLOW")
    ) IOBUF_scl_inst (
        .O (scl_in),
        .IO(io_cmos_scl1),
        .I (1'b0),
        .T (gpio_o[9])
    );

    // -------------------------------------------------------------------------
    // 修改 gpio_i 的赋值，接入 IOBUF 的 .O 输出
    // -------------------------------------------------------------------------

    // Camera 2 I2C Bus (selected when i2c_bus_select = 1)
    // assign io_cmos_sda2 = (i2c_bus_select == 1'b1) ? ((gpio_o[8] == 1'b0) ? 1'b0 : 1'bz) : 1'bz;
    // assign io_cmos_scl2 = (i2c_bus_select == 1'b1) ? ((gpio_o[9] == 1'b0) ? 1'b0 : 1'bz) : 1'bz;

    // Connect external I2C buses (Note: these are not used by neorv32 in this code)
    assign iic_sensor_scl = 1'bz;  // High-Z when not driven
    assign iic_sensor_sda = 1'bz;
    assign iic_temp_scl = 1'bz;
    assign iic_temp_sda = 1'bz;

endmodule
