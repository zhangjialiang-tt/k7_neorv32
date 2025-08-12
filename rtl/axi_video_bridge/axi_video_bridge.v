/*
 * Module: axi_video_bridge
 * Description: Hardware-controlled video bridge with FIFOs for CDC.
 *              Implements ping-pong buffering between DVP video stream and DDR memory
 *              via AXI DMA engine.
 * 
 * Features:
 * - Automatic ping-pong buffer management via hardware FSM
 * - Cross-clock domain transfer using async FIFOs
 * - Configurable frame resolution and data width
 * - AXI4-Lite compatible DMA interface
 */
`timescale 1ns / 1ps

module axi_video_bridge #(
    // Frame Parameters
    parameter FRAME_WIDTH    = 640,
    parameter FRAME_HEIGHT   = 512,
    parameter DVP_DATA_WIDTH = 16,

    // AXI Bus Parameters
    parameter AXI_DATA_WIDTH = 256,
    parameter AXI_ADDR_WIDTH = 32,
    parameter AXI_ID_WIDTH = 8,
    parameter AXI_BURST_LEN = 64,
    parameter AXIS_DATA_WIDTH = AXI_DATA_WIDTH,
    parameter AXIS_KEEP_WIDTH = (AXIS_DATA_WIDTH / 8),

    // Memory Parameters
    parameter FRAME_BUFFER_BASE_ADDR_A = 32'h10000000,
    parameter FRAME_BUFFER_BASE_ADDR_B = 32'h12000000,

    // FIFO Parameters
    parameter FIFO_DEPTH = 512,//AXI_BURST_LEN * 2,  // 4096 depth
    parameter TAG_WIDTH  = 8
) (
    // Clock & Reset
    input wire axi_clk,
    input wire axi_rst_n,

    // User Interface - Write DDR
    input wire                      i_wr_clk,      // User write clock domain
    input wire                      i_wr_rstn,     // User write reset, active low
    // input wire                      i_wr_req,      // User write DDR request
    input wire                      i_wr_data_vs,  // high when data valid
    input wire                      i_wr_data_de,  // high when data valid
    input wire [DVP_DATA_WIDTH-1:0] i_wr_data,     // Pixel data

    // User Interface - Read DDR
    input  wire                      i_rd_clk,      // User read clock domain
    input  wire                      i_rd_rstn,     // User read reset, active low
    // input  wire                      i_rd_req,      // User read DDR request
    input  wire                      i_rd_data_vs,  // User read DDR request
    input  wire                      i_rd_data_de,  // User read DDR request
    output wire                      o_rd_data_vs,  // high when data valid
    output wire                      o_rd_data_de,  // high when data valid
    output wire [DVP_DATA_WIDTH-1:0] o_rd_data,     // Pixel data output

    // AXI4 Master Write Interface (to interconnect)
    // Write Address Channel
    output wire [    AXI_ID_WIDTH-1:0] m_axi_awid,
    output wire [  AXI_ADDR_WIDTH-1:0] m_axi_awaddr,
    output wire [                 7:0] m_axi_awlen,
    output wire [                 2:0] m_axi_awsize,
    output wire [                 1:0] m_axi_awburst,
    output wire                        m_axi_awlock,
    output wire [                 3:0] m_axi_awcache,
    output wire [                 2:0] m_axi_awprot,
    output wire                        m_axi_awvalid,
    input  wire                        m_axi_awready,
    // Write Data Channel
    output wire [  AXI_DATA_WIDTH-1:0] m_axi_wdata,
    output wire [AXI_DATA_WIDTH/8-1:0] m_axi_wstrb,
    output wire                        m_axi_wlast,
    output wire                        m_axi_wvalid,
    input  wire                        m_axi_wready,
    // Write Response Channel
    input  wire [    AXI_ID_WIDTH-1:0] m_axi_bid,
    input  wire [                 1:0] m_axi_bresp,
    input  wire                        m_axi_bvalid,
    output wire                        m_axi_bready,
    // Read Address Channel
    output wire [    AXI_ID_WIDTH-1:0] m_axi_arid,
    output wire [  AXI_ADDR_WIDTH-1:0] m_axi_araddr,
    output wire [                 7:0] m_axi_arlen,
    output wire [                 2:0] m_axi_arsize,
    output wire [                 1:0] m_axi_arburst,
    output wire                        m_axi_arlock,
    output wire [                 3:0] m_axi_arcache,
    output wire [                 2:0] m_axi_arprot,
    output wire                        m_axi_arvalid,
    input  wire                        m_axi_arready,
    // Read Data Channel
    input  wire [    AXI_ID_WIDTH-1:0] m_axi_rid,
    input  wire [  AXI_DATA_WIDTH-1:0] m_axi_rdata,
    input  wire [                 1:0] m_axi_rresp,
    input  wire                        m_axi_rlast,
    input  wire                        m_axi_rvalid,
    output wire                        m_axi_rready,

    // Status and Interrupt Outputs
    output wire frame_done_wr,
    output wire frame_done_rd,
    output wire overflow_wr,
    output wire underflow_rd
);

    // ------------------------------------------------------------------------
    // Local Parameters and Calculations
    // ------------------------------------------------------------------------
    localparam LEN_WIDTH = 32;  // Length of data transfer in bytes

    // ------------------------------------------------------------------------
    // Internal Signals
    // ------------------------------------------------------------------------
    // Write descriptor signals
    wire [ AXI_ADDR_WIDTH-1:0] s_axis_write_desc_addr;
    wire [      LEN_WIDTH-1:0] s_axis_write_desc_len;
    wire [      TAG_WIDTH-1:0] s_axis_write_desc_tag;
    wire                       s_axis_write_desc_valid;
    wire                       s_axis_write_desc_ready;

    // Write status signals
    wire [      LEN_WIDTH-1:0] m_axis_write_desc_status_len;
    wire [      TAG_WIDTH-1:0] m_axis_write_desc_status_tag;
    wire                       m_axis_write_desc_status_valid;

    // Write data signals
    wire [ AXI_DATA_WIDTH-1:0] s_axis_write_data_tdata;
    wire [AXIS_KEEP_WIDTH-1:0] s_axis_write_data_tkeep;
    wire                       s_axis_write_data_tvalid;
    wire                       s_axis_write_data_tready;
    wire                       s_axis_write_data_tlast;

    // Read descriptor signals
    wire [ AXI_ADDR_WIDTH-1:0] s_axis_read_desc_addr;
    wire [      LEN_WIDTH-1:0] s_axis_read_desc_len;
    wire [      TAG_WIDTH-1:0] s_axis_read_desc_tag;
    wire                       s_axis_read_desc_valid;
    wire                       s_axis_read_desc_ready;

    // Read status signals
    wire [      TAG_WIDTH-1:0] m_axis_read_desc_status_tag;
    wire                       m_axis_read_desc_status_valid;

    // Read data signals
    wire [ AXI_DATA_WIDTH-1:0] m_axis_read_data_tdata;
    wire [AXIS_KEEP_WIDTH-1:0] m_axis_read_data_tkeep;
    wire                       m_axis_read_data_tvalid;
    wire                       m_axis_read_data_tready;
    wire                       m_axis_read_data_tlast;


    // Write Path: User Interface -> FIFO -> AXI-Stream
    axis_wr_path_new #(
        .FRAME_BUFFER_BASE_ADDR_A(FRAME_BUFFER_BASE_ADDR_A),
        .FRAME_BUFFER_BASE_ADDR_B(FRAME_BUFFER_BASE_ADDR_B),
        .DVP_DATA_WIDTH(DVP_DATA_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
        .FRAME_WIDTH(FRAME_WIDTH),
        .FRAME_HEIGHT(FRAME_HEIGHT),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) inst_axis_wr_path_new (
        .wr_clk   (i_wr_clk),
        .wr_rst_n (i_wr_rstn),
        .axi_clk  (axi_clk),
        .axi_rst_n(axi_rst_n),

        // User Interface - new vs/de/data timing
        .i_vs                          (i_wr_data_vs),
        .i_de                          (i_wr_data_de),
        .i_data                        (i_wr_data),
        // AXI-Stream Output
        .s_axis_write_desc_addr        (s_axis_write_desc_addr),
        .s_axis_write_desc_len         (s_axis_write_desc_len),
        .s_axis_write_desc_tag         (s_axis_write_desc_tag),
        .s_axis_write_desc_valid       (s_axis_write_desc_valid),
        .s_axis_write_desc_ready       (s_axis_write_desc_ready),
        // Write Status Interface
        .m_axis_write_desc_status_len  (m_axis_write_desc_status_len),
        .m_axis_write_desc_status_tag  (m_axis_write_desc_status_tag),
        .m_axis_write_desc_status_valid(m_axis_write_desc_status_valid),
        // Write Data Interface
        .s_axis_write_data_tdata       (s_axis_write_data_tdata),
        .s_axis_write_data_tkeep       (s_axis_write_data_tkeep),
        .s_axis_write_data_tvalid      (s_axis_write_data_tvalid),
        .s_axis_write_data_tready      (s_axis_write_data_tready),
        .s_axis_write_data_tlast       (s_axis_write_data_tlast)

        // Status
        // .overflow(overflow_wr)
    );

    // ------------------------------------------------------------------------
    // Read Path
    // ------------------------------------------------------------------------

    // Read Path: AXI-Stream -> FIFO -> User Interface
    axis_rd_path_new #(
        .FRAME_BUFFER_BASE_ADDR_A(FRAME_BUFFER_BASE_ADDR_A),
        .FRAME_BUFFER_BASE_ADDR_B(FRAME_BUFFER_BASE_ADDR_B),
        .DVP_DATA_WIDTH(DVP_DATA_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
        .FRAME_WIDTH(FRAME_WIDTH),
        .FRAME_HEIGHT(FRAME_HEIGHT),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) inst_axis_rd_path_new (
        .axi_clk  (axi_clk),
        .axi_rst_n(axi_rst_n),

        // AXI-Stream Input
        .s_axis_read_desc_addr        (s_axis_read_desc_addr),
        .s_axis_read_desc_len         (s_axis_read_desc_len),
        .s_axis_read_desc_tag         (s_axis_read_desc_tag),
        .s_axis_read_desc_valid       (s_axis_read_desc_valid),
        .s_axis_read_desc_ready       (s_axis_read_desc_ready),
        .m_axis_read_desc_status_tag  (m_axis_read_desc_status_tag),
        .m_axis_read_desc_status_valid(m_axis_read_desc_status_valid),
        .m_axis_read_data_tdata       (m_axis_read_data_tdata),
        .m_axis_read_data_tvalid      (m_axis_read_data_tvalid),
        .m_axis_read_data_tready      (m_axis_read_data_tready),
        .m_axis_read_data_tlast       (m_axis_read_data_tlast),

        // User interface - new vs/de/data timing for read control
        .rd_clk      (i_rd_clk),
        .rd_rst_n    (i_rd_rstn),
        .i_rd_data_vs(i_rd_data_vs),
        .i_rd_data_de(i_rd_data_de),
        // .i_rd_req    (i_rd_req),

        // User Interface - new vs/de/data timing
        .o_vs  (o_rd_data_vs),
        .o_de  (o_rd_data_de),
        .o_data(o_rd_data),

        // Status
        .underflow(underflow_rd)
    );

    // ------------------------------------------------------------------------
    // AXI DMA Engine
    // ------------------------------------------------------------------------

    // AXI DMA Engine
    axi_dma #(
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXI_ID_WIDTH(AXI_ID_WIDTH),
        .AXI_MAX_BURST_LEN(AXI_BURST_LEN),
        // .AXIS_KEEP_ENABLE(0),
        .LEN_WIDTH(32),
        .TAG_WIDTH(TAG_WIDTH)
    ) inst_axi_dma (
        .clk(axi_clk),
        .rst(~axi_rst_n),

        .write_enable(1'b1),
        .read_enable (1'b1),

        // Write Descriptor Interface
        .s_axis_write_desc_addr        (s_axis_write_desc_addr),
        .s_axis_write_desc_len         (s_axis_write_desc_len),
        .s_axis_write_desc_tag         (s_axis_write_desc_tag),
        .s_axis_write_desc_valid       (s_axis_write_desc_valid),
        .s_axis_write_desc_ready       (s_axis_write_desc_ready),
        // Write Status Interface
        .m_axis_write_desc_status_len  (m_axis_write_desc_status_len),
        .m_axis_write_desc_status_tag  (m_axis_write_desc_status_tag),
        .m_axis_write_desc_status_valid(m_axis_write_desc_status_valid),
        // Write Data Interface
        .s_axis_write_data_tdata       (s_axis_write_data_tdata),
        .s_axis_write_data_tkeep       (s_axis_write_data_tkeep),
        .s_axis_write_data_tvalid      (s_axis_write_data_tvalid),
        .s_axis_write_data_tready      (s_axis_write_data_tready),
        .s_axis_write_data_tlast       (s_axis_write_data_tlast),
        // Read Descriptor Interface
        .s_axis_read_desc_addr         (s_axis_read_desc_addr),
        .s_axis_read_desc_len          (s_axis_read_desc_len),
        .s_axis_read_desc_tag          (s_axis_read_desc_tag),
        .s_axis_read_desc_valid        (s_axis_read_desc_valid),
        .s_axis_read_desc_ready        (s_axis_read_desc_ready),
        // Read Status Interface
        .m_axis_read_desc_status_tag   (m_axis_read_desc_status_tag),
        .m_axis_read_desc_status_valid (m_axis_read_desc_status_valid),
        // Read Data Interface
        .m_axis_read_data_tdata        (m_axis_read_data_tdata),
        .m_axis_read_data_tkeep        (m_axis_read_data_tkeep),
        .m_axis_read_data_tvalid       (m_axis_read_data_tvalid),
        .m_axis_read_data_tready       (m_axis_read_data_tready),
        .m_axis_read_data_tlast        (m_axis_read_data_tlast),

        // AXI4 Master Write Interface
        .m_axi_awid   (m_axi_awid),
        .m_axi_awaddr (m_axi_awaddr),
        .m_axi_awlen  (m_axi_awlen),
        .m_axi_awsize (m_axi_awsize),
        .m_axi_awburst(m_axi_awburst),
        .m_axi_awlock (m_axi_awlock),
        .m_axi_awcache(m_axi_awcache),
        .m_axi_awprot (m_axi_awprot),
        .m_axi_awvalid(m_axi_awvalid),
        .m_axi_awready(m_axi_awready),

        .m_axi_wdata (m_axi_wdata),
        .m_axi_wstrb (m_axi_wstrb),
        .m_axi_wlast (m_axi_wlast),
        .m_axi_wvalid(m_axi_wvalid),
        .m_axi_wready(m_axi_wready),

        .m_axi_bresp (m_axi_bresp),
        .m_axi_bvalid(m_axi_bvalid),
        .m_axi_bready(m_axi_bready),

        // AXI4 Master Read Interface
        .m_axi_arid   (m_axi_arid),
        .m_axi_araddr (m_axi_araddr),
        .m_axi_arlen  (m_axi_arlen),
        .m_axi_arsize (m_axi_arsize),
        .m_axi_arburst(m_axi_arburst),
        .m_axi_arlock (m_axi_arlock),
        .m_axi_arcache(m_axi_arcache),
        .m_axi_arprot (m_axi_arprot),
        .m_axi_arvalid(m_axi_arvalid),
        .m_axi_arready(m_axi_arready),

        .m_axi_rdata (m_axi_rdata),
        .m_axi_rresp (m_axi_rresp),
        .m_axi_rlast (m_axi_rlast),
        .m_axi_rvalid(m_axi_rvalid),
        .m_axi_rready(m_axi_rready)
    );


endmodule
