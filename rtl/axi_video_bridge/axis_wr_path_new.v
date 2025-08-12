/*
 * Module: axis_wr_path_new
 * Description: Write path for new vs/de/data timing interface
 *              Handles vsync and data enable signals for frame capture
 */
`timescale 1ns / 1ps

module axis_wr_path_new #(
    // AXI Bus Parameters
    parameter AXI_DATA_WIDTH           = 256,
    parameter AXI_ADDR_WIDTH           = 32,
    parameter AXI_ID_WIDTH             = 4,
    parameter AXI_BURST_LEN            = 64,
    parameter AXIS_DATA_WIDTH          = AXI_DATA_WIDTH,
    parameter AXIS_KEEP_WIDTH          = (AXIS_DATA_WIDTH / 8),
    parameter TAG_WIDTH                = 8,
    parameter DVP_DATA_WIDTH           = 16,
    parameter FRAME_WIDTH              = 640,
    parameter FRAME_HEIGHT             = 512,
    // Memory Parameters
    parameter FRAME_BUFFER_BASE_ADDR_A = 32'h10000000,
    parameter FRAME_BUFFER_BASE_ADDR_B = 32'h12000000,
    parameter FIFO_DEPTH               = AXI_BURST_LEN * 2       // 4096 depth
) (
    // Clocks and resets
    input wire wr_clk,    // User write clock
    input wire wr_rst_n,  // User write reset (active low)
    input wire axi_clk,   // AXI clock
    input wire axi_rst_n, // AXI reset (active low)

    // User interface - new vs/de/data timing
    input wire                      i_vs,   // VSYNC signal
    input wire                      i_de,   // DATA ENABLE signal
    input wire [DVP_DATA_WIDTH-1:0] i_data, // Pixel data

    // AXI-Stream output
    // Write path signals
    (*mark_debug = "false"*) output wire [ AXI_ADDR_WIDTH-1:0] s_axis_write_desc_addr,
    (*mark_debug = "false"*) output wire [               31:0] s_axis_write_desc_len,
    (*mark_debug = "false"*) output wire [      TAG_WIDTH-1:0] s_axis_write_desc_tag,
    (*mark_debug = "false"*) output wire                       s_axis_write_desc_valid,
    (*mark_debug = "false"*) input  wire                       s_axis_write_desc_ready,
    (*mark_debug = "false"*) input  wire [               31:0] m_axis_write_desc_status_len,
    (*mark_debug = "false"*) input  wire [      TAG_WIDTH-1:0] m_axis_write_desc_status_tag,
    (*mark_debug = "false"*) input  wire                       m_axis_write_desc_status_valid,
    (*mark_debug = "false"*) output wire [ AXI_DATA_WIDTH-1:0] s_axis_write_data_tdata,
    (*mark_debug = "false"*) output wire [AXIS_KEEP_WIDTH-1:0] s_axis_write_data_tkeep,
    (*mark_debug = "false"*) output wire                       s_axis_write_data_tvalid,
    (*mark_debug = "false"*) input  wire                       s_axis_write_data_tready,
    (*mark_debug = "false"*) output wire                       s_axis_write_data_tlast

    // Status
    // output wire overflow
);

    //**********************************************************************************************
    // Local Parameters
    //**********************************************************************************************
    localparam BYTES_PER_PIXEL = DVP_DATA_WIDTH / 8;
    localparam FRAME_SIZE_BYTES = FRAME_WIDTH * FRAME_HEIGHT * BYTES_PER_PIXEL;
    localparam AXI_KEEP_WIDTH = AXI_DATA_WIDTH / 8;
    localparam PIXELS_PER_BEAT = AXI_DATA_WIDTH / DVP_DATA_WIDTH;
    localparam BEATS_PER_FRAME = FRAME_SIZE_BYTES / AXI_KEEP_WIDTH;
    localparam [32-1:0] TOTAL_PIXELS = FRAME_WIDTH * FRAME_HEIGHT;
    localparam [32-1:0] TOTAL_BEATS = TOTAL_PIXELS / PIXELS_PER_BEAT;
    localparam [32-1:0] BURST_SIZE = AXI_BURST_LEN * AXI_KEEP_WIDTH;  // Burst size in bytes

    //**********************************************************************************************
    // Signal Declarations
    //**********************************************************************************************
    reg  [          1  - 1 : 0] vs_d1;
    reg  [          1  - 1 : 0] vs_d2;
    wire [          1  - 1 : 0] dvp_rst;

    // Internal signals
    (*mark_debug = "false"*)reg  [       TAG_WIDTH-1:0] wr_tag_counter;
    // (*mark_debug = "false"*)wire                        dma_write_enable;

    // FIFO signals
    wire [$clog2(FIFO_DEPTH):0] fifo_wr_count;
    (*mark_debug = "false"*)wire                        fifo_rd_en;
    (*mark_debug = "false"*)wire [  AXI_DATA_WIDTH-1:0] fifo_dout;
    // wire                        fifo_rd_empty;
    (*mark_debug = "false"*)wire [$clog2(FIFO_DEPTH):0] fifo_rd_count;
    wire                        fifo_is_full;
    wire                        fifo_is_empty;

    // Data packing signals
    reg                         wr_desc_valid;
    wire [       TAG_WIDTH-1:0] wr_sent_tag;

    //**********************************************************************************************
    // DVP Clock Domain Logic
    //**********************************************************************************************
    // -- DVP Domain Signals --
    localparam PACK_RATIO = AXIS_DATA_WIDTH / DVP_DATA_WIDTH;
    localparam PACK_CNT_WIDTH = $clog2(PACK_RATIO);

    reg  [ PACK_CNT_WIDTH-1:0] pack_counter_reg;
    reg  [AXIS_DATA_WIDTH-1:0] shift_register_reg;
    wire                       pack_is_full;
    wire                       fifo_write_enable;
    wire [AXIS_DATA_WIDTH-1:0] fifo_write_data;
    reg                        frame_active_reg = 0;
    reg                        dvp_de_d1;

    // VSYNC edge detection for DVP reset generation
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            vs_d1 <= 1'b0;
            vs_d2 <= 1'b0;
            dvp_de_d1 <= 1'b0;
        end else begin
            vs_d1 <= i_vs;
            vs_d2 <= vs_d1;
            dvp_de_d1 <= i_de;
        end
    end
    assign dvp_rst = ~vs_d2 && vs_d1;  // Reset DVP on VSYNC falling edge

    // Data packing counter - counts pixels to form AXI data words
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            pack_counter_reg <= {PACK_CNT_WIDTH{1'b0}};
        end else if (dvp_de_d1 && !fifo_is_full) begin
            if (pack_counter_reg == PACK_RATIO - 1) begin
                pack_counter_reg <= {PACK_CNT_WIDTH{1'b0}};
            end else begin
                pack_counter_reg <= pack_counter_reg + 1'b1;
            end
        end
    end

    // Shift register for packing pixel data into AXI data width
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            shift_register_reg <= {AXIS_DATA_WIDTH{1'b0}};
        end else if (i_de && !fifo_is_full) begin
            shift_register_reg <= {i_data, shift_register_reg[AXIS_DATA_WIDTH-1:DVP_DATA_WIDTH]};
        end
    end

    assign pack_is_full = (pack_counter_reg == PACK_RATIO - 1);
    assign fifo_write_enable = dvp_de_d1 && pack_is_full && !fifo_is_full;
    assign fifo_write_data = shift_register_reg;

    //**********************************************************************************************
    // Cross-clock Domain FIFO
    //**********************************************************************************************
    DC_FIFO #(
        .FIFO_MODE ("ShowAhead"),
        .DATA_WIDTH(AXI_DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) u_dc_fifo (
        .Reset  (dvp_rst || ~wr_rst_n || ~axi_rst_n),
        .WrClk  (wr_clk),
        .WrEn   (fifo_write_enable),
        .WrData (fifo_write_data),
        .WrFull (fifo_is_full),
        .WrDNum (fifo_wr_count),
        .RdClk  (axi_clk),
        .RdEn   (fifo_rd_en),
        .RdData (fifo_dout),
        .RdEmpty(fifo_is_empty),
        .RdDNum (fifo_rd_count),
        .DataVal()
    );

    //**********************************************************************************************
    // AXI Clock Domain Logic
    //**********************************************************************************************
    wire sync_wr_req_level;
    reg  sync_wr_req_level_d1;
    wire sync_wr_req;

    // Synchronize VSYNC signal from DVP clock domain to AXI clock domain
    sync_3ff u_sync_wr_req (
        .clk  (axi_clk),
        .rst_n(axi_rst_n),
        .din  (i_vs),
        .dout (sync_wr_req_level)
    );

    // Detect rising edge of synchronized VSYNC
    always @(posedge axi_clk or negedge axi_rst_n) begin
        if (!axi_rst_n) sync_wr_req_level_d1 <= 1'b0;
        else sync_wr_req_level_d1 <= sync_wr_req_level;
    end
    assign sync_wr_req = sync_wr_req_level && !sync_wr_req_level_d1;  //rising edge detection

    //**********************************************************************************************
    // Write FSM States
    //**********************************************************************************************
    localparam WR_IDLE = 2'b00;
    localparam WR_SEND_DESC = 2'b01;
    localparam WR_WAIT_STATUS = 2'b10;

    reg [1:0] wr_fsm_state;
    reg [1:0] wr_fsm_next_state;

    // Write FSM state transition logic
    always @(posedge axi_clk or negedge axi_rst_n) begin
        if (!axi_rst_n) wr_fsm_state <= WR_IDLE;
        else wr_fsm_state <= wr_fsm_next_state;
    end

    // Write FSM next state and output logic
    always @(*) begin
        wr_fsm_next_state = wr_fsm_state;
        wr_desc_valid = 1'b0;
        case (wr_fsm_state)
            WR_IDLE: begin
                if (sync_wr_req) wr_fsm_next_state = WR_SEND_DESC;
            end

            WR_SEND_DESC: begin
                wr_desc_valid = 1'b1;
                if (s_axis_write_desc_ready) wr_fsm_next_state = WR_WAIT_STATUS;
            end

            WR_WAIT_STATUS: begin
                if (m_axis_write_desc_status_valid && m_axis_write_desc_status_tag == wr_sent_tag) wr_fsm_next_state = WR_IDLE;
            end
        endcase
    end

    //**********************************************************************************************
    // Buffer Management
    //**********************************************************************************************
    reg wr_buf_is_a;
    // Toggle buffer selection on each frame start
    always @(posedge axi_clk or negedge axi_rst_n) begin
        if (!axi_rst_n) wr_buf_is_a <= 1'b0;
        else if (wr_fsm_state == WR_IDLE && sync_wr_req) wr_buf_is_a <= ~wr_buf_is_a;
    end

    // AXI Stream write descriptor outputs
    assign s_axis_write_desc_valid = wr_desc_valid;
    assign s_axis_write_desc_addr = wr_buf_is_a ? FRAME_BUFFER_BASE_ADDR_A : FRAME_BUFFER_BASE_ADDR_B;
    assign s_axis_write_desc_len = FRAME_SIZE_BYTES;
    assign s_axis_write_desc_tag = wr_tag_counter;
    assign wr_sent_tag = wr_tag_counter;

    //**********************************************************************************************
    // DMA Data Transfer Control
    //**********************************************************************************************
    (*mark_debug = "false"*) reg [1  - 1 : 0] fifo_read_flag;
    // Control when to start reading from FIFO based on FIFO level
    always @(posedge axi_clk or negedge axi_rst_n) begin
        if (!axi_rst_n) wr_tag_counter <= 'd0;
        else if (sync_wr_req) wr_tag_counter <= 'd0;
        else if (s_axis_write_data_tready && s_axis_write_data_tvalid) begin
            if (wr_tag_counter == AXI_BURST_LEN - 1) wr_tag_counter <= 0;
            else wr_tag_counter <= wr_tag_counter + 1;
        end else wr_tag_counter <= wr_tag_counter;
    end
    always @(posedge axi_clk or negedge axi_rst_n) begin
        if (!axi_rst_n) fifo_read_flag <= 'd0;
        else if (sync_wr_req) fifo_read_flag <= 'd0;
        else if (wr_tag_counter == AXI_BURST_LEN - 1) fifo_read_flag <= 'd0;
        else if (fifo_rd_count > AXI_BURST_LEN - 1) fifo_read_flag <= 'd1;
        else fifo_read_flag <= fifo_read_flag;
    end

    // FIFO read enable control
    assign fifo_rd_en = fifo_read_flag && !fifo_is_empty && s_axis_write_data_tready;

    // AXI Stream write data outputs
    assign s_axis_write_data_tkeep = {AXIS_KEEP_WIDTH{1'b1}};  // 默认 tkeep 全1
    assign s_axis_write_data_tdata = fifo_dout;
    assign s_axis_write_data_tvalid = fifo_read_flag;
    assign s_axis_write_data_tlast = wr_tag_counter == AXI_BURST_LEN - 1 && m_axis_write_desc_status_len == FRAME_SIZE_BYTES - BURST_SIZE;

    //**********************************************************************************************
    // DMA Counter Management
    //**********************************************************************************************
    (*mark_debug = "false"*) reg [16  - 1 : 0] dbg_dma_cnt;
    // Write tag counter - tracks burst transfers within a frame

    // Debug counter for tracking DMA transfers
    always @(posedge axi_clk or negedge axi_rst_n) begin
        if (!axi_rst_n) dbg_dma_cnt <= 'd0;
        else if (sync_wr_req) dbg_dma_cnt <= 'd0;
        else if (s_axis_write_data_tready && s_axis_write_data_tvalid) dbg_dma_cnt <= dbg_dma_cnt + 1;
        else dbg_dma_cnt <= dbg_dma_cnt;
    end
    (*mark_debug = "false"*)reg           [ 10  - 1 : 0 ]          dbg_hcnt               ;
    (*mark_debug = "false"*)reg           [ 10  - 1 : 0 ]          dbg_vcnt               ;
    (*mark_debug = "false"*)wire           [ 1  - 1 : 0 ]          dbg_vs_pos               ;
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) dbg_hcnt <= 'd0;
        else if (i_de) dbg_hcnt <= dbg_hcnt+'d1;
        else dbg_hcnt <= 0;
    end
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) dbg_vcnt <= 'd0;
        else if (dbg_vs_pos) dbg_vcnt <= 'd0;
        else if (dbg_hcnt== FRAME_WIDTH-1) dbg_vcnt <= dbg_vcnt+'d1;
        else dbg_vcnt <= dbg_vcnt;
    end
    capture_edge #(
        .EDGE("rising")
    ) capture_edge_1x_inst (
        .i_Sys_clk  (wr_clk),
        .i_Rst_n    (~wr_rst_n),
        .i_Din_valid(i_vs),
        .o_Dout_edge(dbg_vs_pos)
    );
endmodule
