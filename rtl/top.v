`include "include.v"
module top #(
    parameter DDR_DW   = 31,
    parameter DDR_DQSW = 3
) (
    // Clock: 50MHz
    input  wire         i_clk,
    output wire         o_cmos_reset1,  // cmos reset
    output wire         o_cmos_scl1,    // cmos i2c clock
    inout  wire         io_cmos_sda1,   // cmos i2c data
    input  wire         i_cmos_pclk1,   // cmos pxiel clock
    input  wire         i_cmos_vsync1,  // cmos vsync
    input  wire         i_cmos_href1,   // cmos hsync refrence
    input  wire [8-1:0] i_cmos_data1,   // cmos data

    output wire         o_cmos_reset2,  // cmos reset
    output wire         o_cmos_scl2,    // cmos i2c clock
    inout  wire         io_cmos_sda2,   // cmos i2c data
    input  wire         i_cmos_pclk2,   // cmos pxiel clock
    input  wire         i_cmos_vsync2,  // cmos vsync
    input  wire         i_cmos_href2,   // cmos hsync refrence
    input  wire [8-1:0] i_cmos_data2,   //cmos data   

    //HDMI接口信号
    output wire         o_TMDS1_CLK_P,
    output wire         o_TMDS1_CLK_N,
    output wire [  2:0] o_TMDS1_P,
    output wire [  2:0] o_TMDS1_N,
    output wire         o_TMDS1_en,
`ifdef MICROBLAZE
    inout       [ 31:0] ddr3_dq,                //ddr3 data
    inout       [  3:0] ddr3_dqs_n,             //ddr3 dqs negative
    inout       [  3:0] ddr3_dqs_p,             //ddr3 dqs positive
    output      [ 14:0] ddr3_addr,              //ddr3 address
    output      [  2:0] ddr3_ba,                //ddr3 bank
    output              ddr3_ras_n,             //ddr3 ras_n
    output              ddr3_cas_n,             //ddr3 cas_n
    output              ddr3_we_n,              //ddr3 write enable
    output              ddr3_reset_n,           //ddr3 reset,
    output      [  0:0] ddr3_ck_p,              //ddr3 clock negative
    output      [  0:0] ddr3_ck_n,              //ddr3 clock positive
    output      [  0:0] ddr3_cke,               //ddr3_cke,
    output      [  0:0] ddr3_cs_n,              //ddr3 chip select,
    output      [  3:0] ddr3_dm,                //ddr3_dm
    output      [  0:0] ddr3_odt,               //ddr3_odt
`endif
    inout  wire         system_spi_0_io0_io,
    inout  wire         system_spi_0_io1_io,
    inout  wire         system_spi_0_io2_io,
    inout  wire         system_spi_0_io3_io,
    inout  wire         system_spi_0_ss_io,
    input  wire         system_uart_debug_rxd,
    output wire         system_uart_debug_txd,
    inout  wire         iic_sensor_scl,
    inout  wire         iic_sensor_sda,
    inout  wire         iic_temp_scl,
    inout  wire         iic_temp_sda,
    output wire         eth_mdio_mdc,
    inout  wire         eth_mdio_mdio_io,
    output wire         eth_reset,
    input  wire [  3:0] eth_rgmii_rd,
    input  wire         eth_rgmii_rx_ctl,
    input  wire         eth_rgmii_rxc,
    output wire [  3:0] eth_rgmii_td,
    output wire         eth_rgmii_tx_ctl,
    output wire         eth_rgmii_txc,
    input  wire [5-1:0] i_key,
    output wire [8-1:0] o_led
);

    parameter FRAME_WIDTH = 640;
    parameter FRAME_HEIGHT = 512;
    parameter AXI_ADDR_WIDTH = 32;
    parameter AXI_DATA_WIDTH = 256;
    parameter AXI_MAX_BURST_LEN = 32;
    parameter AXI_ID_WIDTH = 8;
    parameter DATA_WIDTH = 16;
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
    //**********************************************************************************************
    // wire and reg
    //**********************************************************************************************
    wire clk_ibufg;
    wire clk_200m;
    wire clk_160m;
    wire clk_100m;
    wire clk_50m;
    wire clk_40m;
    wire clk_24m;
    wire clk_20m;
    wire clk_200m_int;
    wire clk_160m_int;
    wire clk_100m_int;
    wire clk_50m_int;
    wire clk_40m_int;
    wire clk_24m_int;
    wire clk_20m_int;
    wire pclk1_int;
    wire pclk2_int;
    wire mmcm_rst;
    wire mmcm_locked;
    wire mmcm_clkfb;
    wire mmcm2_rst;
    wire mmcm2_locked;
    wire mmcm2_clkfb;
    wire rst_200m_int;
    wire rst_160m_int;
    wire rst_100m_int;
    wire rst_50m_int;
    wire rst_40m_int;
    wire rst_20m_int;
    wire clk_mmcm_out;
    assign mmcm_rst = 1'b0;
    wire                        axi_clk;
    wire                        axi_rst;
    wire                        ddr_init_done;

    wire [              1 -1:0] cam1_vs;
    wire [              1 -1:0] cam1_de;
    wire [              16-1:0] cam1_data;
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
    //     wire [    AXI_ID_WIDTH-1:0] S00_AXI_0_awid;
    // wire [  AXI_ADDR_WIDTH-1:0] S00_AXI_0_awaddr;
    // wire [                 7:0] S00_AXI_0_awlen;
    // wire [                 2:0] S00_AXI_0_awsize;
    // wire [                 1:0] S00_AXI_0_awburst;
    // wire                        S00_AXI_0_awlock;
    // wire [                 3:0] S00_AXI_0_awcache;
    // wire [                 2:0] S00_AXI_0_awprot;
    // wire                        S00_AXI_0_awvalid;
    // wire                        S00_AXI_0_awready;
    // wire [  AXI_DATA_WIDTH-1:0] S00_AXI_0_wdata;
    // wire [AXI_DATA_WIDTH/8-1:0] S00_AXI_0_wstrb;
    // wire                        S00_AXI_0_wlast;
    // wire                        S00_AXI_0_wvalid;
    // wire                        S00_AXI_0_wready;
    // wire [    AXI_ID_WIDTH-1:0] S00_AXI_0_bid;
    // wire [                 1:0] S00_AXI_0_bresp;
    // wire                        S00_AXI_0_bvalid;
    // wire                        S00_AXI_0_bready;
    // wire [    AXI_ID_WIDTH-1:0] S00_AXI_0_arid;
    // wire [  AXI_ADDR_WIDTH-1:0] S00_AXI_0_araddr;
    // wire [                 7:0] S00_AXI_0_arlen;
    // wire [                 2:0] S00_AXI_0_arsize;
    // wire [                 1:0] S00_AXI_0_arburst;
    // wire                        S00_AXI_0_arlock;
    // wire [                 3:0] S00_AXI_0_arcache;
    // wire [                 2:0] S00_AXI_0_arprot;
    // wire                        S00_AXI_0_arvalid;
    // wire                        S00_AXI_0_arready;
    // wire [    AXI_ID_WIDTH-1:0] S00_AXI_0_rid;
    // wire [  AXI_DATA_WIDTH-1:0] S00_AXI_0_rdata;
    // wire [                 1:0] S00_AXI_0_rresp;
    // wire                        S00_AXI_0_rlast;
    // wire                        S00_AXI_0_rvalid;
    // wire                        S00_AXI_0_rready;
    wire [AXI_ID_WIDTH-1:0] S00_AXI_0_awid, S01_AXI_0_awid, S02_AXI_0_awid, S03_AXI_0_awid, S04_AXI_0_awid;
    wire [AXI_ADDR_WIDTH-1:0] S00_AXI_0_awaddr, S01_AXI_0_awaddr, S02_AXI_0_awaddr, S03_AXI_0_awaddr, S04_AXI_0_awaddr;
    wire [7:0] S00_AXI_0_awlen, S01_AXI_0_awlen, S02_AXI_0_awlen, S03_AXI_0_awlen, S04_AXI_0_awlen;
    wire [2:0] S00_AXI_0_awsize, S01_AXI_0_awsize, S02_AXI_0_awsize, S03_AXI_0_awsize, S04_AXI_0_awsize;
    wire [1:0] S00_AXI_0_awburst, S01_AXI_0_awburst, S02_AXI_0_awburst, S03_AXI_0_awburst, S04_AXI_0_awburst;
    wire S00_AXI_0_awlock, S01_AXI_0_awlock, S02_AXI_0_awlock, S03_AXI_0_awlock, S04_AXI_0_awlock;
    wire [3:0] S00_AXI_0_awcache, S01_AXI_0_awcache, S02_AXI_0_awcache, S03_AXI_0_awcache, S04_AXI_0_awcache;
    wire [2:0] S00_AXI_0_awprot, S01_AXI_0_awprot, S02_AXI_0_awprot, S03_AXI_0_awprot, S04_AXI_0_awprot;
    wire S00_AXI_0_awvalid, S01_AXI_0_awvalid, S02_AXI_0_awvalid, S03_AXI_0_awvalid, S04_AXI_0_awvalid;
    wire S00_AXI_0_awready, S01_AXI_0_awready, S02_AXI_0_awready, S03_AXI_0_awready, S04_AXI_0_awready;
    wire [AXI_DATA_WIDTH-1:0] S00_AXI_0_wdata, S01_AXI_0_wdata, S02_AXI_0_wdata, S03_AXI_0_wdata, S04_AXI_0_wdata;
    wire [AXI_DATA_WIDTH/8-1:0] S00_AXI_0_wstrb, S01_AXI_0_wstrb, S02_AXI_0_wstrb, S03_AXI_0_wstrb, S04_AXI_0_wstrb;
    wire S00_AXI_0_wlast, S01_AXI_0_wlast, S02_AXI_0_wlast, S03_AXI_0_wlast, S04_AXI_0_wlast;
    wire S00_AXI_0_wvalid, S01_AXI_0_wvalid, S02_AXI_0_wvalid, S03_AXI_0_wvalid, S04_AXI_0_wvalid;
    wire S00_AXI_0_wready, S01_AXI_0_wready, S02_AXI_0_wready, S03_AXI_0_wready, S04_AXI_0_wready;
    wire [AXI_ID_WIDTH-1:0] S00_AXI_0_bid, S01_AXI_0_bid, S02_AXI_0_bid, S03_AXI_0_bid, S04_AXI_0_bid;
    wire [1:0] S00_AXI_0_bresp, S01_AXI_0_bresp, S02_AXI_0_bresp, S03_AXI_0_bresp, S04_AXI_0_bresp;
    wire S00_AXI_0_bvalid, S01_AXI_0_bvalid, S02_AXI_0_bvalid, S03_AXI_0_bvalid, S04_AXI_0_bvalid;
    wire S00_AXI_0_bready, S01_AXI_0_bready, S02_AXI_0_bready, S03_AXI_0_bready, S04_AXI_0_bready;
    wire [AXI_ID_WIDTH-1:0] S00_AXI_0_arid, S01_AXI_0_arid, S02_AXI_0_arid, S03_AXI_0_arid, S04_AXI_0_arid;
    wire [AXI_ADDR_WIDTH-1:0] S00_AXI_0_araddr, S01_AXI_0_araddr, S02_AXI_0_araddr, S03_AXI_0_araddr, S04_AXI_0_araddr;
    wire [7:0] S00_AXI_0_arlen, S01_AXI_0_arlen, S02_AXI_0_arlen, S03_AXI_0_arlen, S04_AXI_0_arlen;
    wire [2:0] S00_AXI_0_arsize, S01_AXI_0_arsize, S02_AXI_0_arsize, S03_AXI_0_arsize, S04_AXI_0_arsize;
    wire [1:0] S00_AXI_0_arburst, S01_AXI_0_arburst, S02_AXI_0_arburst, S03_AXI_0_arburst, S04_AXI_0_arburst;
    wire S00_AXI_0_arlock, S01_AXI_0_arlock, S02_AXI_0_arlock, S03_AXI_0_arlock, S04_AXI_0_arlock;
    wire [3:0] S00_AXI_0_arcache, S01_AXI_0_arcache, S02_AXI_0_arcache, S03_AXI_0_arcache, S04_AXI_0_arcache;
    wire [2:0] S00_AXI_0_arprot, S01_AXI_0_arprot, S02_AXI_0_arprot, S03_AXI_0_arprot, S04_AXI_0_arprot;
    wire S00_AXI_0_arvalid, S01_AXI_0_arvalid, S02_AXI_0_arvalid, S03_AXI_0_arvalid, S04_AXI_0_arvalid;
    wire S00_AXI_0_arready, S01_AXI_0_arready, S02_AXI_0_arready, S03_AXI_0_arready, S04_AXI_0_arready;
    wire [AXI_ID_WIDTH-1:0] S00_AXI_0_rid, S01_AXI_0_rid, S02_AXI_0_rid, S03_AXI_0_rid, S04_AXI_0_rid;
    wire [AXI_DATA_WIDTH-1:0] S00_AXI_0_rdata, S01_AXI_0_rdata, S02_AXI_0_rdata, S03_AXI_0_rdata, S04_AXI_0_rdata;
    wire [1:0] S00_AXI_0_rresp, S01_AXI_0_rresp, S02_AXI_0_rresp, S03_AXI_0_rresp, S04_AXI_0_rresp;
    wire S00_AXI_0_rlast, S01_AXI_0_rlast, S02_AXI_0_rlast, S03_AXI_0_rlast, S04_AXI_0_rlast;
    wire S00_AXI_0_rvalid, S01_AXI_0_rvalid, S02_AXI_0_rvalid, S03_AXI_0_rvalid, S04_AXI_0_rvalid;
    wire S00_AXI_0_rready, S01_AXI_0_rready, S02_AXI_0_rready, S03_AXI_0_rready, S04_AXI_0_rready;
    wire               hdmi_pclk_x1;
    wire               hdmi_pclk_x2p5;
    wire               hdmi_pclk_x5;
    wire               rst_hdmi;
    wire               video_vs;
    wire               video_hs;
    wire               video_de;
    wire               tpg_video_vs;
    wire               tpg_video_hs;
    wire               tpg_video_de;
    wire [       23:0] tpg_video_data;
    wire               clip_video_vs;
    wire               clip_video_de;
    reg  [       15:0] clip_video_data;
    (*mark_debug = "false"*)wire [1   - 1 : 0] ch0_wr_field_rst;
    (*mark_debug = "false"*)wire [32  - 1 : 0] ch0_wr_addr;
    (*mark_debug = "false"*)wire [1   - 1 : 0] ch0_wr_vs;
    (*mark_debug = "false"*)wire [1   - 1 : 0] ch0_wr_de;
    (*mark_debug = "false"*)wire [16  - 1 : 0] ch0_wr_data;
    (*mark_debug = "false"*)wire [1   - 1 : 0] ch0_rd_field_rst;
    (*mark_debug = "false"*)wire [32  - 1 : 0] ch0_rd_addr;
    (*mark_debug = "false"*)wire [1   - 1 : 0] ch0_rd_vs;
    (*mark_debug = "false"*)wire [1   - 1 : 0] ch0_rd_de;
    // (*mark_debug = "false"*)wire [  16  - 1 : 0]ch0_rd_data;
    (*mark_debug = "false"*)wire [1   - 1 : 0] ch1_wr_field_rst;
    (*mark_debug = "false"*)wire [32  - 1 : 0] ch1_wr_addr;
    (*mark_debug = "false"*)wire [1   - 1 : 0] ch1_wr_vs;
    (*mark_debug = "false"*)wire [1   - 1 : 0] ch1_wr_de;
    (*mark_debug = "false"*)wire [16  - 1 : 0] ch1_wr_data;
    (*mark_debug = "false"*)wire [1   - 1 : 0] ch1_rd_field_rst;
    (*mark_debug = "false"*)wire [32  - 1 : 0] ch1_rd_addr;
    (*mark_debug = "false"*)wire [1   - 1 : 0] ch1_rd_vs;
    (*mark_debug = "false"*)wire [1   - 1 : 0] ch1_rd_de;
    // (*mark_debug = "false"*)wire [  16  - 1 : 0]ch1_rd_data;
`ifndef BLOCK_DESIGN_DDR_ALONE

    wire [32-1:0] io_apbSlave_0_PADDR;
    wire          io_apbSlave_0_PSEL;
    wire          io_apbSlave_0_PENABLE;
    wire          io_apbSlave_0_PREADY;
    wire          io_apbSlave_0_PWRITE;
    wire [32-1:0] io_apbSlave_0_PWDATA;
    wire [32-1:0] io_apbSlave_0_PRDATA;
    wire          io_apbSlave_0_PSLVERROR;
`endif
    //**********************************************************************************************
    // 时钟管理
    //**********************************************************************************************
    IBUFG clk_ibufg_inst (
        .I(i_clk),
        .O(clk_ibufg)
    );

    // MMCM instance
    // 100 MHz in, 125 MHz out
    // PFD range: 10 MHz to 550 MHz
    // VCO range: 600 MHz to 1200 MHz
    // M = 10, D = 1 sets Fvco = 1000 MHz (in range)
    // Divide by 8 to get output frequency of 125 MHz
    // Need two 125 MHz outputs with 90 degree offset
    // Also need 200 MHz out for IODELAY
    // 1000 / 5 = 200 MHz
    MMCME2_BASE #(
        .BANDWIDTH         ("OPTIMIZED"),
        .CLKOUT0_DIVIDE_F  (4),            //800mhz/4=200mhz
        .CLKOUT0_DUTY_CYCLE(0.5),
        .CLKOUT0_PHASE     (0),

        .CLKOUT1_DIVIDE    (8),    //800mhz/8=100mhz
        .CLKOUT1_DUTY_CYCLE(0.5),
        .CLKOUT1_PHASE     (0),

        .CLKOUT2_DIVIDE    (5),    //800mhz/5=160mhz
        .CLKOUT2_DUTY_CYCLE(0.5),
        .CLKOUT2_PHASE     (0),

        .CLKOUT3_DIVIDE    (20),   //800mhz/20=40mhz
        .CLKOUT3_DUTY_CYCLE(0.5),
        .CLKOUT3_PHASE     (0),

        .CLKOUT4_DIVIDE    (16),   //800mhz/16=50mhz
        .CLKOUT4_DUTY_CYCLE(0.5),
        .CLKOUT4_PHASE     (0),

        .CLKOUT5_DIVIDE    (5),    //800mhz/5=160mhz
        .CLKOUT5_DUTY_CYCLE(0.5),
        .CLKOUT5_PHASE     (0),

        .CLKOUT6_DIVIDE    (15),
        .CLKOUT6_DUTY_CYCLE(0.5),
        .CLKOUT6_PHASE     (0),

        .CLKFBOUT_MULT_F(16),       //Fvco = 50mhz*16=800mhz
        .CLKFBOUT_PHASE (0),
        .DIVCLK_DIVIDE  (1),
        .REF_JITTER1    (0.010),
        .CLKIN1_PERIOD  (20.0),     //输入时钟周期-20ns
        .STARTUP_WAIT   ("FALSE"),
        .CLKOUT4_CASCADE("FALSE")
    ) clk_mmcm_1_inst (
        .CLKIN1   (clk_ibufg),   //50MHZ
        .CLKFBIN  (mmcm_clkfb),
        .RST      (mmcm_rst),
        .PWRDWN   (1'b0),
        .CLKOUT0  (clk_200m),    //200MHZ
        .CLKOUT0B (),
        .CLKOUT1  (clk_100m),    //100MHZ
        .CLKOUT1B (),
        .CLKOUT2  (clk_160m),
        .CLKOUT2B (),
        .CLKOUT3  (clk_40m),
        .CLKOUT3B (),
        .CLKOUT4  (clk_50m),
        .CLKOUT5  (clk_24m),
        .CLKOUT6  (),
        .CLKFBOUT (mmcm_clkfb),
        .CLKFBOUTB(),
        .LOCKED   (mmcm_locked)
    );
    BUFG clk_1_bufg_inst (
        .I(clk_200m),
        .O(clk_200m_int)
    );
    BUFG clk_2_bufg_inst (
        .I(clk_100m),
        .O(clk_100m_int)
    );
    BUFG clk_3_bufg_inst (
        .I(clk_50m),
        .O(clk_50m_int)
    );
    BUFG clk_4_bufg_inst (
        .I(clk_40m),
        .O(clk_40m_int)
    );
    BUFG clk_5_bufg_inst (
        .I(clk_160m),
        .O(clk_160m_int)
    );
    assign pclk1_int = i_cmos_pclk1;
    assign pclk2_int = i_cmos_pclk2;
    sync_reset #(
        .N(4)
    ) sync_reset1_inst (
        .clk(clk_100m_int),
        .rst(~mmcm_locked),
        .out(rst_100m_int)
    );
    sync_reset #(
        .N(4)
    ) sync_reset2_inst (
        .clk(clk_200m_int),
        .rst(~mmcm_locked),
        .out(rst_200m_int)
    );
    sync_reset #(
        .N(4)
    ) sync_reset3_inst (
        .clk(clk_50m_int),
        .rst(~mmcm_locked),
        .out(rst_50m_int)
    );
    sync_reset #(
        .N(4)
    ) sync_reset4_inst (
        .clk(clk_40m_int),
        .rst(~mmcm_locked),
        .out(rst_40m_int)
    );
    sync_reset #(
        .N(4)
    ) sync_reset5_inst (
        .clk(clk_160m_int),
        .rst(~mmcm_locked),
        .out(rst_160m_int)
    );
    //**********************************************************************************************
    //function
    //**********************************************************************************************
    wire [1  - 1 : 0] cmd_scaler;
    wire [5  - 1 : 0] key;
    wire [1  - 1 : 0] cmd_scaler_up;
    wire [1  - 1 : 0] cmd_scaler_down;
    wire [12 - 1 : 0] scaler_multiple;
    debounce_v2 #(
        .WIDTH                (5),
        .SAMPLING_FACTOR      (2),
        .TREAT_UNSTABLE_AS_LOW(0)
    ) ML (
        .clk (clk_40m_int),
        .nrst(~rst_40m_int),
        .ena (1'b1),
        .in  (i_key),
        .out (key)
    );
    assign cmd_scaler_up   = ~key[0];
    assign cmd_scaler_down = ~key[1];
    cmd cmd_inst (
        .i_Sys_clk      (clk_40m_int),
        .i_Rst_n        (~rst_40m_int),
        .i_External_sync(ch0_wr_vs),
        .i_Cmd_1        (cmd_scaler_up),
        .i_Cmd_2        (cmd_scaler_down),
        .o_Cmd_scaler   (scaler_multiple)
    );
    // led_blink #(
    //     .LED_NUM (1),
    //     .STS_FREQ(200_000_000)
    // ) led1_blink_inst (
    //     .i_Sys_clk(clk_200m_int),
    //     .i_Rst_n  (~rst_200m_int),
    //     .o_led    (o_led[0])
    // );
    // led_blink #(
    //     .LED_NUM (1),
    //     .STS_FREQ(100_000_000)
    // ) led2_blink_inst (
    //     .i_Sys_clk(clk_100m_int),
    //     .i_Rst_n  (~rst_100m_int),
    //     .o_led    (o_led[1])
    // );
    // led_blink #(
    //     .LED_NUM (1),
    //     .STS_FREQ(40_000_000)
    // ) led3_blink_inst (
    //     .i_Sys_clk(clk_40m_int),
    //     .i_Rst_n  (~rst_40m_int),
    //     .o_led    (o_led[2])
    // );
    // led_blink #(
    //     .LED_NUM (1),
    //     .STS_FREQ(100_000_000)
    // ) led4_blink_inst (
    //     .i_Sys_clk(axi_clk),
    //     .i_Rst_n  (~axi_rst),
    //     .o_led    (o_led[3])
    // );
    // led_blink #(
    //     .LED_NUM (1),
    //     .STS_FREQ(50_000_000)
    // ) led5_blink_inst (
    //     .i_Sys_clk(clk_50m_int),
    //     .i_Rst_n  (~rst_50m_int),
    //     .o_led    (o_led[4])
    // );
    // led_blink #(
    //     .LED_NUM (1),
    //     .STS_FREQ(20_000_000)
    // ) led6_blink_inst (
    //     .i_Sys_clk(clk_20m_int),
    //     .i_Rst_n  (~rst_20m_int),
    //     .o_led    (o_led[5])
    // );
    // assign o_led[4] = ddr_init_done;
    // assign o_led[5] = ~ddr_init_done;
    //**********************************************************************************************
    // `ifdef USE_CAMERA
    //     camera_top #(
    //         .CW           ( 11      ),
    //         .DW           ( 16      ),
    //         .IMAGE_WIDTH  ( 16'd1024 ),//16'd1280 ),
    //         .IMAGE_HEIGHT ( 16'd720 ))//16'd720 ))
    //     u_camera_core (
    //         .i_Sys_clk               ( clk_50m_int     ),
    //         .i_Rst_n                 ( ~rst_50m_int    ),

    //         .o_cmos_reset1           ( o_cmos_reset1   ),
    //         .o_cmos_scl1             ( o_cmos_scl1     ),
    //         .io_cmos_sda1            ( io_cmos_sda1    ),
    //         .i_cmos_pclk1            ( pclk1_int       ),
    //         .i_cmos_vsync1           ( i_cmos_vsync1   ),
    //         .i_cmos_href1            ( i_cmos_href1    ),
    //         .i_cmos_data1            ( i_cmos_data1    ),
    //         .o_Cam1_clk              (          ),
    //         .o_Cam1_vs               ( cam1_vs         ),
    //         .o_Cam1_de               ( cam1_de         ),
    //         .o_Cam1_data             ( cam1_data       )
    //     );
    // `endif
    //**********************************************************************************************
    (*mark_debug = "true"*)wire [         1        - 1 : 0] buffer1_data_vs;
    (*mark_debug = "true"*)wire [         1        - 1 : 0] buffer1_data_valid;
    (*mark_debug = "true"*)wire [DATA_WIDTH        - 1 : 0] buffer1_data;
    (*mark_debug = "true"*)wire [         1        - 1 : 0] buffer2_data_vs;
    (*mark_debug = "true"*)wire [         1        - 1 : 0] buffer2_data_valid;
    (*mark_debug = "true"*)wire [DATA_WIDTH        - 1 : 0] buffer2_data;
    (*mark_debug = "false"*)wire [         1        - 1 : 0] buffer3_data_vs;
    (*mark_debug = "false"*)wire [         1        - 1 : 0] buffer3_data_valid;
    (*mark_debug = "false"*)wire [DATA_WIDTH        - 1 : 0] buffer3_data;
    (*mark_debug = "false"*)wire [         1        - 1 : 0] buffer4_data_vs;
    (*mark_debug = "false"*)wire [         1        - 1 : 0] buffer4_data_valid;
    (*mark_debug = "false"*)wire [DATA_WIDTH        - 1 : 0] buffer4_data;
    (*mark_debug = "false"*)wire [         1        - 1 : 0] buffer5_data_vs;
    (*mark_debug = "false"*)wire [         1        - 1 : 0] buffer5_data_valid;
    (*mark_debug = "false"*)wire [DATA_WIDTH        - 1 : 0] buffer5_data;
    (*mark_debug = "false"*)wire [         1        - 1 : 0] buffer6_data_vs;
    (*mark_debug = "false"*)wire [         1        - 1 : 0] buffer6_data_valid;
    (*mark_debug = "false"*)wire [DATA_WIDTH        - 1 : 0] buffer6_data;
    (*mark_debug = "false"*)wire [         1        - 1 : 0] buffer7_data_vs;
    (*mark_debug = "false"*)wire [         1        - 1 : 0] buffer7_data_valid;
    (*mark_debug = "false"*)wire [DATA_WIDTH        - 1 : 0] buffer7_data;
    (*mark_debug = "false"*)wire [         1        - 1 : 0] buffer8_data_vs;
    (*mark_debug = "false"*)wire [         1        - 1 : 0] buffer8_data_valid;
    (*mark_debug = "false"*)wire [DATA_WIDTH        - 1 : 0] buffer8_data;
    //**********************************************************************************************
`ifdef NEORV32
    neorv32_top #(
        .CLOCK_FREQUENCY(100_000_000),
        .BOOT_MODE_SELECT(0),
        .RISCV_ISA_C(1'b1),
        .RISCV_ISA_M(1'b1),
        .RISCV_ISA_Zicntr(1'b1),
        .IMEM_EN(1'b1),
        .IMEM_SIZE(16 * 1024),
        .DMEM_EN(1'b1),
        .DMEM_SIZE(8 * 1024),
        .IO_GPIO_NUM(8),
        .IO_CLINT_EN(1'b1),
        .IO_UART0_EN(1'b1)
    ) neorv32_top_inst (
        .clk_i      (clk_100m_int),
        .rstn_i     (~rst_100m_int),
        .gpio_o     (o_led),
        .uart0_txd_o(system_uart_debug_txd),
        .uart0_rxd_i(system_uart_debug_rxd)
    );
`endif
    //**********************************************************************************************
`ifdef BLOCK_DESIGN_DDR_ALONE
    axi_video_bridge #(
        .FRAME_WIDTH             (FRAME_WIDTH),
        .FRAME_HEIGHT            (FRAME_HEIGHT),
        .DVP_DATA_WIDTH          (DATA_WIDTH),
        .AXI_DATA_WIDTH          (AXI_DATA_WIDTH),
        .AXI_ADDR_WIDTH          (AXI_ADDR_WIDTH),
        .AXI_BURST_LEN           (AXI_MAX_BURST_LEN),
        .FRAME_BUFFER_BASE_ADDR_A(FRAME_BUFFER_0),     //32'h1000_0000),
        .FRAME_BUFFER_BASE_ADDR_B(FRAME_BUFFER_1)      //32'h1200_0000)
    ) dut (
        // System Interface
        .axi_clk  (axi_clk),
        .axi_rst_n(~axi_rst),

        // DVP Write Path (Input from simulated source)
        .i_wr_clk    (clk_40m_int),
        .i_wr_rstn   (~rst_40m_int),
        // .i_wr_req    (wr_req),
        .i_wr_data_vs(ch0_wr_vs),
        .i_wr_data_de(ch0_wr_de),
        .i_wr_data   (ch0_wr_data),

        // DVP Read Path (Output to simulated display)
        .i_rd_clk    (clk_40m_int),
        .i_rd_rstn   (~rst_40m_int),
        // .i_rd_req    (rd_req),
        .i_rd_data_vs(ch0_rd_vs),
        .i_rd_data_de(ch0_rd_de),
        .o_rd_data_vs(buffer1_data_vs),
        .o_rd_data_de(buffer1_data_valid),
        .o_rd_data   (buffer1_data),

        // AXI Master Interface (to RAM)
        .m_axi_awid   (S00_AXI_0_awid),
        .m_axi_awaddr (S00_AXI_0_awaddr),
        .m_axi_awlen  (S00_AXI_0_awlen),
        .m_axi_awsize (S00_AXI_0_awsize),
        .m_axi_awburst(S00_AXI_0_awburst),
        .m_axi_awlock (S00_AXI_0_awlock),
        .m_axi_awcache(S00_AXI_0_awcache),
        .m_axi_awprot (S00_AXI_0_awprot),
        .m_axi_awvalid(S00_AXI_0_awvalid),
        .m_axi_awready(S00_AXI_0_awready),
        .m_axi_wdata  (S00_AXI_0_wdata),
        .m_axi_wstrb  (S00_AXI_0_wstrb),
        .m_axi_wlast  (S00_AXI_0_wlast),
        .m_axi_wvalid (S00_AXI_0_wvalid),
        .m_axi_wready (S00_AXI_0_wready),
        .m_axi_bid    (S00_AXI_0_bid),
        .m_axi_bresp  (S00_AXI_0_bresp),
        .m_axi_bvalid (S00_AXI_0_bvalid),
        .m_axi_bready (S00_AXI_0_bready),
        .m_axi_arid   (S00_AXI_0_arid),
        .m_axi_araddr (S00_AXI_0_araddr),
        .m_axi_arlen  (S00_AXI_0_arlen),
        .m_axi_arsize (S00_AXI_0_arsize),
        .m_axi_arburst(S00_AXI_0_arburst),
        .m_axi_arlock (S00_AXI_0_arlock),
        .m_axi_arcache(S00_AXI_0_arcache),
        .m_axi_arprot (S00_AXI_0_arprot),
        .m_axi_arvalid(S00_AXI_0_arvalid),
        .m_axi_arready(S00_AXI_0_arready),
        .m_axi_rid    (S00_AXI_0_rid),
        .m_axi_rdata  (S00_AXI_0_rdata),
        .m_axi_rresp  (S00_AXI_0_rresp),
        .m_axi_rlast  (S00_AXI_0_rlast),
        .m_axi_rvalid (S00_AXI_0_rvalid),
        .m_axi_rready (S00_AXI_0_rready)
    );
    axi_video_bridge #(
        .FRAME_WIDTH             (FRAME_WIDTH),
        .FRAME_HEIGHT            (FRAME_HEIGHT),
        .DVP_DATA_WIDTH          (DATA_WIDTH),
        .AXI_DATA_WIDTH          (AXI_DATA_WIDTH),
        .AXI_ADDR_WIDTH          (AXI_ADDR_WIDTH),
        .AXI_BURST_LEN           (AXI_MAX_BURST_LEN),
        .FRAME_BUFFER_BASE_ADDR_A(FRAME_BUFFER_2),
        .FRAME_BUFFER_BASE_ADDR_B(FRAME_BUFFER_3)
    ) dut_2 (
        // System Interface
        .axi_clk  (axi_clk),
        .axi_rst_n(~axi_rst),

        // DVP Write Path (Input from simulated source)
        .i_wr_clk    (clk_40m_int),
        .i_wr_rstn   (~rst_40m_int),
        // .i_wr_req    (wr_req),
        .i_wr_data_vs(buffer1_data_vs),
        .i_wr_data_de(buffer1_data_valid),
        .i_wr_data   (buffer1_data),

        // DVP Read Path (Output to simulated display)
        .i_rd_clk    (clk_40m_int),
        .i_rd_rstn   (~rst_40m_int),
        // .i_rd_req    (rd_req),
        .i_rd_data_vs(ch0_rd_vs),
        .i_rd_data_de(ch0_rd_de),
        .o_rd_data_vs(buffer2_data_vs),
        .o_rd_data_de(buffer2_data_valid),
        .o_rd_data   (buffer2_data),

        // AXI Master Interface (to RAM)
        .m_axi_awid   (S01_AXI_0_awid),
        .m_axi_awaddr (S01_AXI_0_awaddr),
        .m_axi_awlen  (S01_AXI_0_awlen),
        .m_axi_awsize (S01_AXI_0_awsize),
        .m_axi_awburst(S01_AXI_0_awburst),
        .m_axi_awlock (S01_AXI_0_awlock),
        .m_axi_awcache(S01_AXI_0_awcache),
        .m_axi_awprot (S01_AXI_0_awprot),
        .m_axi_awvalid(S01_AXI_0_awvalid),
        .m_axi_awready(S01_AXI_0_awready),
        .m_axi_wdata  (S01_AXI_0_wdata),
        .m_axi_wstrb  (S01_AXI_0_wstrb),
        .m_axi_wlast  (S01_AXI_0_wlast),
        .m_axi_wvalid (S01_AXI_0_wvalid),
        .m_axi_wready (S01_AXI_0_wready),
        .m_axi_bid    (S01_AXI_0_bid),
        .m_axi_bresp  (S01_AXI_0_bresp),
        .m_axi_bvalid (S01_AXI_0_bvalid),
        .m_axi_bready (S01_AXI_0_bready),
        .m_axi_arid   (S01_AXI_0_arid),
        .m_axi_araddr (S01_AXI_0_araddr),
        .m_axi_arlen  (S01_AXI_0_arlen),
        .m_axi_arsize (S01_AXI_0_arsize),
        .m_axi_arburst(S01_AXI_0_arburst),
        .m_axi_arlock (S01_AXI_0_arlock),
        .m_axi_arcache(S01_AXI_0_arcache),
        .m_axi_arprot (S01_AXI_0_arprot),
        .m_axi_arvalid(S01_AXI_0_arvalid),
        .m_axi_arready(S01_AXI_0_arready),
        .m_axi_rid    (S01_AXI_0_rid),
        .m_axi_rdata  (S01_AXI_0_rdata),
        .m_axi_rresp  (S01_AXI_0_rresp),
        .m_axi_rlast  (S01_AXI_0_rlast),
        .m_axi_rvalid (S01_AXI_0_rvalid),
        .m_axi_rready (S01_AXI_0_rready)
    );
    axi_video_bridge #(
        .FRAME_WIDTH             (FRAME_WIDTH),
        .FRAME_HEIGHT            (FRAME_HEIGHT),
        .DVP_DATA_WIDTH          (DATA_WIDTH),
        .AXI_DATA_WIDTH          (AXI_DATA_WIDTH),
        .AXI_ADDR_WIDTH          (AXI_ADDR_WIDTH),
        .AXI_BURST_LEN           (AXI_MAX_BURST_LEN),
        .FRAME_BUFFER_BASE_ADDR_A(FRAME_BUFFER_4),
        .FRAME_BUFFER_BASE_ADDR_B(FRAME_BUFFER_5)
    ) dut_3 (
        // System Interface
        .axi_clk  (axi_clk),
        .axi_rst_n(~axi_rst),

        // DVP Write Path (Input from simulated source)
        .i_wr_clk    (clk_40m_int),
        .i_wr_rstn   (~rst_40m_int),
        .i_wr_data_vs(buffer2_data_vs),
        .i_wr_data_de(buffer2_data_valid),
        .i_wr_data   (buffer2_data),

        // DVP Read Path (Output to simulated display)
        .i_rd_clk    (clk_40m_int),
        .i_rd_rstn   (~rst_40m_int),
        .i_rd_data_vs(ch0_rd_vs),
        .i_rd_data_de(ch0_rd_de),
        .o_rd_data_vs(buffer3_data_vs),
        .o_rd_data_de(buffer3_data_valid),
        .o_rd_data   (buffer3_data),

        // AXI Master Interface (to RAM)
        .m_axi_awid   (S02_AXI_0_awid),
        .m_axi_awaddr (S02_AXI_0_awaddr),
        .m_axi_awlen  (S02_AXI_0_awlen),
        .m_axi_awsize (S02_AXI_0_awsize),
        .m_axi_awburst(S02_AXI_0_awburst),
        .m_axi_awlock (S02_AXI_0_awlock),
        .m_axi_awcache(S02_AXI_0_awcache),
        .m_axi_awprot (S02_AXI_0_awprot),
        .m_axi_awvalid(S02_AXI_0_awvalid),
        .m_axi_awready(S02_AXI_0_awready),
        .m_axi_wdata  (S02_AXI_0_wdata),
        .m_axi_wstrb  (S02_AXI_0_wstrb),
        .m_axi_wlast  (S02_AXI_0_wlast),
        .m_axi_wvalid (S02_AXI_0_wvalid),
        .m_axi_wready (S02_AXI_0_wready),
        .m_axi_bid    (S02_AXI_0_bid),
        .m_axi_bresp  (S02_AXI_0_bresp),
        .m_axi_bvalid (S02_AXI_0_bvalid),
        .m_axi_bready (S02_AXI_0_bready),
        .m_axi_arid   (S02_AXI_0_arid),
        .m_axi_araddr (S02_AXI_0_araddr),
        .m_axi_arlen  (S02_AXI_0_arlen),
        .m_axi_arsize (S02_AXI_0_arsize),
        .m_axi_arburst(S02_AXI_0_arburst),
        .m_axi_arlock (S02_AXI_0_arlock),
        .m_axi_arcache(S02_AXI_0_arcache),
        .m_axi_arprot (S02_AXI_0_arprot),
        .m_axi_arvalid(S02_AXI_0_arvalid),
        .m_axi_arready(S02_AXI_0_arready),
        .m_axi_rid    (S02_AXI_0_rid),
        .m_axi_rdata  (S02_AXI_0_rdata),
        .m_axi_rresp  (S02_AXI_0_rresp),
        .m_axi_rlast  (S02_AXI_0_rlast),
        .m_axi_rvalid (S02_AXI_0_rvalid),
        .m_axi_rready (S02_AXI_0_rready)
    );
    design_1_wrapper design_1_wrapper_inst (
        .sys_clk_i_0      (clk_200m_int),
        .sys_rst_0        (~rst_200m_int),
        .ddr_clk          (axi_clk),
        .ddr_sync_rst     (axi_rst),
        .ddr_init_done    (ddr_init_done),
        .DDR3_addr        (ddr3_addr),
        .DDR3_ba          (ddr3_ba),
        .DDR3_cas_n       (ddr3_cas_n),
        .DDR3_ck_n        (ddr3_ck_n),
        .DDR3_ck_p        (ddr3_ck_p),
        .DDR3_cke         (ddr3_cke),
        .DDR3_cs_n        (ddr3_cs_n),
        .DDR3_dm          (ddr3_dm),
        .DDR3_dq          (ddr3_dq),
        .DDR3_dqs_n       (ddr3_dqs_n),
        .DDR3_dqs_p       (ddr3_dqs_p),
        .DDR3_odt         (ddr3_odt),
        .DDR3_ras_n       (ddr3_ras_n),
        .DDR3_reset_n     (ddr3_reset_n),
        .DDR3_we_n        (ddr3_we_n),
        .S00_AXI_0_araddr (S00_AXI_0_araddr),
        .S00_AXI_0_arburst(S00_AXI_0_arburst),
        .S00_AXI_0_arcache(S00_AXI_0_arcache),
        .S00_AXI_0_arid   (S00_AXI_0_arid),
        .S00_AXI_0_arlen  (S00_AXI_0_arlen),
        .S00_AXI_0_arlock (S00_AXI_0_arlock),
        .S00_AXI_0_arprot (S00_AXI_0_arprot),
        .S00_AXI_0_arqos  (S00_AXI_0_arqos),
        .S00_AXI_0_arready(S00_AXI_0_arready),
        .S00_AXI_0_arsize (S00_AXI_0_arsize),
        .S00_AXI_0_arvalid(S00_AXI_0_arvalid),
        .S00_AXI_0_awaddr (S00_AXI_0_awaddr),
        .S00_AXI_0_awburst(S00_AXI_0_awburst),
        .S00_AXI_0_awcache(S00_AXI_0_awcache),
        .S00_AXI_0_awid   (S00_AXI_0_awid),
        .S00_AXI_0_awlen  (S00_AXI_0_awlen),
        .S00_AXI_0_awlock (S00_AXI_0_awlock),
        .S00_AXI_0_awprot (S00_AXI_0_awprot),
        .S00_AXI_0_awqos  (S00_AXI_0_awqos),
        .S00_AXI_0_awready(S00_AXI_0_awready),
        .S00_AXI_0_awsize (S00_AXI_0_awsize),
        .S00_AXI_0_awvalid(S00_AXI_0_awvalid),
        .S00_AXI_0_bid    (S00_AXI_0_bid),
        .S00_AXI_0_bready (S00_AXI_0_bready),
        .S00_AXI_0_bresp  (S00_AXI_0_bresp),
        .S00_AXI_0_bvalid (S00_AXI_0_bvalid),
        .S00_AXI_0_rdata  (S00_AXI_0_rdata),
        .S00_AXI_0_rid    (S00_AXI_0_rid),
        .S00_AXI_0_rlast  (S00_AXI_0_rlast),
        .S00_AXI_0_rready (S00_AXI_0_rready),
        .S00_AXI_0_rresp  (S00_AXI_0_rresp),
        .S00_AXI_0_rvalid (S00_AXI_0_rvalid),
        .S00_AXI_0_wdata  (S00_AXI_0_wdata),
        .S00_AXI_0_wlast  (S00_AXI_0_wlast),
        .S00_AXI_0_wready (S00_AXI_0_wready),
        .S00_AXI_0_wstrb  (S00_AXI_0_wstrb),
        .S00_AXI_0_wvalid (S00_AXI_0_wvalid),
        .S01_AXI_0_araddr (S01_AXI_0_araddr),
        .S01_AXI_0_arburst(S01_AXI_0_arburst),
        .S01_AXI_0_arcache(S01_AXI_0_arcache),
        .S01_AXI_0_arid   (S01_AXI_0_arid),
        .S01_AXI_0_arlen  (S01_AXI_0_arlen),
        .S01_AXI_0_arlock (S01_AXI_0_arlock),
        .S01_AXI_0_arprot (S01_AXI_0_arprot),
        .S01_AXI_0_arqos  (S01_AXI_0_arqos),
        .S01_AXI_0_arready(S01_AXI_0_arready),
        .S01_AXI_0_arsize (S01_AXI_0_arsize),
        .S01_AXI_0_arvalid(S01_AXI_0_arvalid),
        .S01_AXI_0_awaddr (S01_AXI_0_awaddr),
        .S01_AXI_0_awburst(S01_AXI_0_awburst),
        .S01_AXI_0_awcache(S01_AXI_0_awcache),
        .S01_AXI_0_awid   (S01_AXI_0_awid),
        .S01_AXI_0_awlen  (S01_AXI_0_awlen),
        .S01_AXI_0_awlock (S01_AXI_0_awlock),
        .S01_AXI_0_awprot (S01_AXI_0_awprot),
        .S01_AXI_0_awqos  (S01_AXI_0_awqos),
        .S01_AXI_0_awready(S01_AXI_0_awready),
        .S01_AXI_0_awsize (S01_AXI_0_awsize),
        .S01_AXI_0_awvalid(S01_AXI_0_awvalid),
        .S01_AXI_0_bid    (S01_AXI_0_bid),
        .S01_AXI_0_bready (S01_AXI_0_bready),
        .S01_AXI_0_bresp  (S01_AXI_0_bresp),
        .S01_AXI_0_bvalid (S01_AXI_0_bvalid),
        .S01_AXI_0_rdata  (S01_AXI_0_rdata),
        .S01_AXI_0_rid    (S01_AXI_0_rid),
        .S01_AXI_0_rlast  (S01_AXI_0_rlast),
        .S01_AXI_0_rready (S01_AXI_0_rready),
        .S01_AXI_0_rresp  (S01_AXI_0_rresp),
        .S01_AXI_0_rvalid (S01_AXI_0_rvalid),
        .S01_AXI_0_wdata  (S01_AXI_0_wdata),
        .S01_AXI_0_wlast  (S01_AXI_0_wlast),
        .S01_AXI_0_wready (S01_AXI_0_wready),
        .S01_AXI_0_wstrb  (S01_AXI_0_wstrb),
        .S01_AXI_0_wvalid (S01_AXI_0_wvalid),
        .S02_AXI_0_araddr (S02_AXI_0_araddr),
        .S02_AXI_0_arburst(S02_AXI_0_arburst),
        .S02_AXI_0_arcache(S02_AXI_0_arcache),
        .S02_AXI_0_arid   (S02_AXI_0_arid),
        .S02_AXI_0_arlen  (S02_AXI_0_arlen),
        .S02_AXI_0_arlock (S02_AXI_0_arlock),
        .S02_AXI_0_arprot (S02_AXI_0_arprot),
        .S02_AXI_0_arqos  (S02_AXI_0_arqos),
        .S02_AXI_0_arready(S02_AXI_0_arready),
        .S02_AXI_0_arsize (S02_AXI_0_arsize),
        .S02_AXI_0_arvalid(S02_AXI_0_arvalid),
        .S02_AXI_0_awaddr (S02_AXI_0_awaddr),
        .S02_AXI_0_awburst(S02_AXI_0_awburst),
        .S02_AXI_0_awcache(S02_AXI_0_awcache),
        .S02_AXI_0_awid   (S02_AXI_0_awid),
        .S02_AXI_0_awlen  (S02_AXI_0_awlen),
        .S02_AXI_0_awlock (S02_AXI_0_awlock),
        .S02_AXI_0_awprot (S02_AXI_0_awprot),
        .S02_AXI_0_awqos  (S02_AXI_0_awqos),
        .S02_AXI_0_awready(S02_AXI_0_awready),
        .S02_AXI_0_awsize (S02_AXI_0_awsize),
        .S02_AXI_0_awvalid(S02_AXI_0_awvalid),
        .S02_AXI_0_bid    (S02_AXI_0_bid),
        .S02_AXI_0_bready (S02_AXI_0_bready),
        .S02_AXI_0_bresp  (S02_AXI_0_bresp),
        .S02_AXI_0_bvalid (S02_AXI_0_bvalid),
        .S02_AXI_0_rdata  (S02_AXI_0_rdata),
        .S02_AXI_0_rid    (S02_AXI_0_rid),
        .S02_AXI_0_rlast  (S02_AXI_0_rlast),
        .S02_AXI_0_rready (S02_AXI_0_rready),
        .S02_AXI_0_rresp  (S02_AXI_0_rresp),
        .S02_AXI_0_rvalid (S02_AXI_0_rvalid),
        .S02_AXI_0_wdata  (S02_AXI_0_wdata),
        .S02_AXI_0_wlast  (S02_AXI_0_wlast),
        .S02_AXI_0_wready (S02_AXI_0_wready),
        .S02_AXI_0_wstrb  (S02_AXI_0_wstrb),
        .S02_AXI_0_wvalid (S02_AXI_0_wvalid),
        .S03_AXI_0_araddr (S03_AXI_0_araddr),
        .S03_AXI_0_arburst(S03_AXI_0_arburst),
        .S03_AXI_0_arcache(S03_AXI_0_arcache),
        .S03_AXI_0_arid   (S03_AXI_0_arid),
        .S03_AXI_0_arlen  (S03_AXI_0_arlen),
        .S03_AXI_0_arlock (S03_AXI_0_arlock),
        .S03_AXI_0_arprot (S03_AXI_0_arprot),
        .S03_AXI_0_arqos  (S03_AXI_0_arqos),
        .S03_AXI_0_arready(S03_AXI_0_arready),
        .S03_AXI_0_arsize (S03_AXI_0_arsize),
        .S03_AXI_0_arvalid(S03_AXI_0_arvalid),
        .S03_AXI_0_awaddr (S03_AXI_0_awaddr),
        .S03_AXI_0_awburst(S03_AXI_0_awburst),
        .S03_AXI_0_awcache(S03_AXI_0_awcache),
        .S03_AXI_0_awid   (S03_AXI_0_awid),
        .S03_AXI_0_awlen  (S03_AXI_0_awlen),
        .S03_AXI_0_awlock (S03_AXI_0_awlock),
        .S03_AXI_0_awprot (S03_AXI_0_awprot),
        .S03_AXI_0_awqos  (S03_AXI_0_awqos),
        .S03_AXI_0_awready(S03_AXI_0_awready),
        .S03_AXI_0_awsize (S03_AXI_0_awsize),
        .S03_AXI_0_awvalid(S03_AXI_0_awvalid),
        .S03_AXI_0_bid    (S03_AXI_0_bid),
        .S03_AXI_0_bready (S03_AXI_0_bready),
        .S03_AXI_0_bresp  (S03_AXI_0_bresp),
        .S03_AXI_0_bvalid (S03_AXI_0_bvalid),
        .S03_AXI_0_rdata  (S03_AXI_0_rdata),
        .S03_AXI_0_rid    (S03_AXI_0_rid),
        .S03_AXI_0_rlast  (S03_AXI_0_rlast),
        .S03_AXI_0_rready (S03_AXI_0_rready),
        .S03_AXI_0_rresp  (S03_AXI_0_rresp),
        .S03_AXI_0_rvalid (S03_AXI_0_rvalid),
        .S03_AXI_0_wdata  (S03_AXI_0_wdata),
        .S03_AXI_0_wlast  (S03_AXI_0_wlast),
        .S03_AXI_0_wready (S03_AXI_0_wready),
        .S03_AXI_0_wstrb  (S03_AXI_0_wstrb),
        .S03_AXI_0_wvalid (S03_AXI_0_wvalid)
    );

`endif
`ifdef MICROBLAZE
    design_1_wrapper design_1_wrapper_inst (
        .clk_flash           (clk_50m_int),
        .clk_soc             (clk_100m_int),
        .rstn_soc            (~rst_100m_int),
        .clk_ref             (clk_200m_int),
        .rstn_ref            (~rst_200m_int),
        //   output ddr_clk;
        .ddr_clk             (),
        // .clk_in1_0                         ( clk_100m_int                                            ) ,
        // .sys_clk_i_0                       ( clk_200m_int                                            ) ,
        .APB_M_paddr         (io_apbSlave_0_PADDR),
        .APB_M_penable       (io_apbSlave_0_PENABLE),
        .APB_M_prdata        (io_apbSlave_0_PRDATA),
        .APB_M_pready        (io_apbSlave_0_PREADY),
        .APB_M_psel          (io_apbSlave_0_PSEL),
        .APB_M_pslverr       (io_apbSlave_0_PSLVERROR),
        .APB_M_pwdata        (io_apbSlave_0_PWDATA),
        .APB_M_pwrite        (io_apbSlave_0_PWRITE),
        .DDR3_addr           (ddr3_addr),
        .DDR3_ba             (ddr3_ba),
        .DDR3_cas_n          (ddr3_cas_n),
        .DDR3_ck_n           (ddr3_ck_n),
        .DDR3_ck_p           (ddr3_ck_p),
        .DDR3_cke            (ddr3_cke),
        .DDR3_cs_n           (ddr3_cs_n),
        .DDR3_dm             (ddr3_dm),
        .DDR3_dq             (ddr3_dq),
        .DDR3_dqs_n          (ddr3_dqs_n),
        .DDR3_dqs_p          (ddr3_dqs_p),
        .DDR3_odt            (ddr3_odt),
        .DDR3_ras_n          (ddr3_ras_n),
        .DDR3_reset_n        (ddr3_reset_n),
        .DDR3_we_n           (ddr3_we_n),
        //----------------------------------------------------
        .user_Interrupt_tri_i(1'b0),
        .spi_flash_io0_io    (system_spi_0_io0_io),
        .spi_flash_io1_io    (system_spi_0_io1_io),
        .spi_flash_io2_io    (system_spi_0_io2_io),
        .spi_flash_io3_io    (system_spi_0_io3_io),
        .spi_flash_ss_io     (system_spi_0_ss_io),
        .uart_debug_rxd      (system_uart_debug_rxd),
        .uart_debug_txd      (system_uart_debug_txd),
        .IIC_sensor_scl_io   (iic_sensor_scl),
        .IIC_sensor_sda_io   (iic_sensor_sda),
        .IIC_temp_scl_io     (iic_temp_scl),
        .IIC_temp_sda_io     (iic_temp_sda)
    );
`endif

    // **********************************************HDMI************************************************
    assign hdmi_pclk_x5 = clk_200m_int;
    assign hdmi_pclk_x2p5 = clk_100m_int;
    assign hdmi_pclk_x1 = clk_40m_int;
    assign rst_hdmi = rst_40m_int;

    // vga timing : 800 x 600 @ 60hz 40MHz
    uivtc #(
        .H_FrameSize (800 + 40 + 128 + 88),
        .H_ActiveSize(800),
        .H_SyncStart (800 + 40),
        .H_SyncEnd   (800 + 40 + 128),
        .V_FrameSize (600 + 1 + 4 + 23),
        .V_ActiveSize(600),
        .V_SyncStart (600 + 1),
        .V_SyncEnd   (600 + 1 + 4)
    ) uivtc_inst (
        .vtc_clk_i (hdmi_pclk_x1),
        .vtc_rstn_i(~rst_hdmi),
        .vtc_vs_o  (video_vs),
        .vtc_hs_o  (video_hs),
        .vtc_de_o  (video_de)
    );

    rect #(
        .CW(10),
        .DW(16),
        .IMAGE_WIDTH(800),
        .IMAGE_HEIGHT(600)
    ) rect_1_inst (
        .i_Sys_clk      (hdmi_pclk_x1),
        .i_Rst_n        (~rst_hdmi),
        .i_Output_mode  (3'd4),
        .i_Buffer_addr_0(FRAME_BUFFER_0),
        .i_Buffer_addr_1(FRAME_BUFFER_1),
        .i_Rect_start_x (10),
        .i_Rect_start_y (10),
        .i_Rect_post_w  (FRAME_WIDTH),
        .i_Rect_post_h  (FRAME_HEIGHT),
        .i_Image_vs     (~video_vs),
        .i_Image_de     (video_de),
        .o_Field_rst    (ch0_wr_field_rst),
        .o_Base_addr    (ch0_wr_addr),
        .o_Image_vs     (ch0_wr_vs),
        .o_Image_de     (ch0_wr_de),
        .o_Image_data   (ch0_wr_data)
    );
    rect #(
        .CW(10),
        .DW(16),
        .IMAGE_WIDTH(800),
        .IMAGE_HEIGHT(600)
    ) rect_2_inst (
        .i_Sys_clk      (hdmi_pclk_x1),
        .i_Rst_n        (~rst_hdmi),
        .i_Output_mode  (3'd2),
        .i_Buffer_addr_0(FRAME_BUFFER_1),
        .i_Buffer_addr_1(FRAME_BUFFER_0),
        .i_Rect_start_x (10),
        .i_Rect_start_y (10),
        .i_Rect_post_w  (FRAME_WIDTH),
        .i_Rect_post_h  (FRAME_HEIGHT),
        .i_Image_vs     (~video_vs),
        .i_Image_de     (video_de),
        .o_Field_rst    (ch0_rd_field_rst),
        .o_Base_addr    (ch0_rd_addr),
        .o_Image_vs     (ch0_rd_vs),
        .o_Image_de     (ch0_rd_de),
        .o_Image_data   ()
    );
    rect #(
        .CW(10),
        .DW(16),
        .IMAGE_WIDTH(800),
        .IMAGE_HEIGHT(600)
    ) rect_3_inst (
        .i_Sys_clk      (hdmi_pclk_x1),
        .i_Rst_n        (~rst_hdmi),
        .i_Output_mode  (3'd2),
        .i_Buffer_addr_0(FRAME_BUFFER_2),
        .i_Buffer_addr_1(FRAME_BUFFER_3),
        .i_Rect_start_x (10),
        .i_Rect_start_y (10),
        .i_Rect_post_w  (FRAME_WIDTH),
        .i_Rect_post_h  (FRAME_HEIGHT),
        .i_Image_vs     (~video_vs),
        .i_Image_de     (video_de),
        .o_Field_rst    (ch1_wr_field_rst),
        .o_Base_addr    (ch1_wr_addr),
        .o_Image_vs     (ch1_wr_vs),
        .o_Image_de     (ch1_wr_de),
        .o_Image_data   (ch1_wr_data)
    );
    rect #(
        .CW(10),
        .DW(16),
        .IMAGE_WIDTH(800),
        .IMAGE_HEIGHT(600)
    ) rect_4_inst (
        .i_Sys_clk      (hdmi_pclk_x1),
        .i_Rst_n        (~rst_hdmi),
        .i_Output_mode  (3'd2),
        .i_Buffer_addr_0(FRAME_BUFFER_2),
        .i_Buffer_addr_1(FRAME_BUFFER_3),
        .i_Rect_start_x (10),
        .i_Rect_start_y (10),
        .i_Rect_post_w  (FRAME_WIDTH),
        .i_Rect_post_h  (FRAME_HEIGHT),
        .i_Image_vs     (~video_vs),
        .i_Image_de     (video_de),
        .o_Field_rst    (ch1_rd_field_rst),
        .o_Base_addr    (ch1_rd_addr),
        .o_Image_vs     (ch1_rd_vs),
        .o_Image_de     (ch1_rd_de),
        .o_Image_data   (ch1_rd_data)
    );

    assign tpg_video_vs   = video_vs;
    assign tpg_video_hs   = video_hs;
    assign tpg_video_de   = video_de;
`ifdef NEORV32
    assign tpg_video_data = video_de ? (ch0_wr_de ? {ch0_wr_data[7:0], ch0_wr_data[7:0], ch0_wr_data[7:0]} : {8'd255, 8'd255, 8'd255}) : 0;
`else
    // assign tpg_video_data = video_de ? (buffer1_data_valid ? {buffer1_data[7:0], buffer1_data[7:0], buffer1_data[7:0]} : {8'd255, 8'd255, 8'd255}) : 0;
    // assign tpg_video_data = video_de ? (buffer2_data_valid ? {buffer2_data[7:0], buffer2_data[7:0], buffer2_data[7:0]} : {8'd255, 8'd255, 8'd255}) : 0;
    assign tpg_video_data = video_de ? (buffer3_data_valid ? {buffer3_data[7:0], buffer3_data[7:0], buffer3_data[7:0]} : {8'd255, 8'd255, 8'd255}) : 0;
`endif
    uihdmitx_1 u_hdmi_tx (
        .RSTn_i(~rst_hdmi),
        .VS_i  (tpg_video_vs),
        .HS_i  (tpg_video_hs),
        .VDE_i (tpg_video_de),
        .RGB_i (tpg_video_data),

        .PCLKX1_i  (hdmi_pclk_x1),
        .PCLKX2_5_i(hdmi_pclk_x2p5),
        .PCLKX5_i  (hdmi_pclk_x5),

        .TMDS_TX_CLK_P(o_TMDS1_CLK_P),
        .TMDS_TX_CLK_N(o_TMDS1_CLK_N),
        .TMDS_TX_P    (o_TMDS1_P),
        .TMDS_TX_N    (o_TMDS1_N)
    );
    assign o_TMDS1_en = 1'b1;
    //**********************************************************************************************
    assign eth_rgmii_txc = cam1_de;
    assign eth_rgmii_td = cam1_data[3:0] + cam1_data[7:4] + cam1_data[11:8] + cam1_data[15:12];


    //**********************************************************************************************
endmodule
