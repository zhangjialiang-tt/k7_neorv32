/*
 * Module: axis_rd_path_new
 * Description: Read path for new vs/de/data timing interface
 *              Generates vsync and data enable signals for frame output
 */
`timescale 1ns / 1ps

module axis_rd_path_new #(
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
    // AXI-Stream input
                             input  wire                      axi_clk,                 // AXI clock
                             input  wire                      axi_rst_n,               // AXI reset (active low)
    (*mark_debug = "false"*) output wire [AXI_ADDR_WIDTH-1:0] s_axis_read_desc_addr,
    (*mark_debug = "false"*) output wire [            32-1:0] s_axis_read_desc_len,
    (*mark_debug = "false"*) output wire [     TAG_WIDTH-1:0] s_axis_read_desc_tag,
    (*mark_debug = "false"*) output wire                      s_axis_read_desc_valid,
    (*mark_debug = "false"*) input  wire                      s_axis_read_desc_ready,

    input wire [TAG_WIDTH-1:0] m_axis_read_desc_status_tag,
    input wire                 m_axis_read_desc_status_valid,

    (*mark_debug = "false"*) input  wire [AXI_DATA_WIDTH-1:0] m_axis_read_data_tdata,
    (*mark_debug = "false"*) input  wire [AXI_DATA_WIDTH-1:0] m_axis_read_data_tkeep,
    (*mark_debug = "false"*) input  wire                      m_axis_read_data_tvalid,
    (*mark_debug = "false"*) output wire                      m_axis_read_data_tready,
    (*mark_debug = "false"*) input  wire                      m_axis_read_data_tlast,

    // User interface - new vs/de/data timing for read control
                             input  wire                      rd_clk,        // User read clock
                             input  wire                      rd_rst_n,      // User read reset (active low)
    // input  wire                      i_rd_req,      // req信号为单周期信号，在i_rd_data_vs前拉高，表征axis_rd_path_new模块需要读取数据
                             input  wire                      i_rd_data_vs,  // VSYNC signal (active high)
                             input  wire                      i_rd_data_de,  // DATA ENABLE signal (active high)
    (*mark_debug = "false"*) output wire                      o_vs,          // VSYNC signal
    (*mark_debug = "false"*) output wire                      o_de,          // DATA ENABLE signal
    (*mark_debug = "false"*) output wire [DVP_DATA_WIDTH-1:0] o_data,        // Pixel data

    // Status
    output wire underflow
);

    // ------------------------------------------------------------------------
    // Local Parameters and Calculations
    // ------------------------------------------------------------------------
    localparam BYTES_PER_PIXEL = DVP_DATA_WIDTH / 8;
    localparam FRAME_SIZE_BYTES = FRAME_WIDTH * FRAME_HEIGHT * BYTES_PER_PIXEL;
    localparam AXI_KEEP_WIDTH = AXI_DATA_WIDTH / 8;
    localparam PIXELS_PER_BEAT = AXI_DATA_WIDTH / DVP_DATA_WIDTH;
    localparam BEATS_PER_FRAME = FRAME_SIZE_BYTES / AXI_KEEP_WIDTH;
    localparam TOTAL_PIXELS = FRAME_WIDTH * FRAME_HEIGHT;

    localparam PRE_STORE = 4;
    localparam PRE_STORE_BYTE = PRE_STORE * FRAME_WIDTH * 2;  //单位：字节
    localparam PRE_STORE_BEAT = PRE_STORE_BYTE / (AXI_DATA_WIDTH / 8);  //单位：word，axi总线位宽

    localparam PRE_STORE_HALF = 2;
    localparam PRE_STORE_BYTE_HALF = PRE_STORE_HALF * FRAME_WIDTH * 2;
    localparam PRE_STORE_BEAT_HALF = PRE_STORE_BYTE_HALF / (AXI_DATA_WIDTH / 8);  //单位：word，axi总线位宽

    localparam PACK_RATIO = AXIS_DATA_WIDTH / DVP_DATA_WIDTH;
    localparam PACK_CNT_WIDTH = $clog2(PACK_RATIO);

    // ------------------------------------------------------------------------
    // Internal signals
    // ------------------------------------------------------------------------
    // FIFO signals
    (*mark_debug = "false"*) wire                        fifo_full;
    (*mark_debug = "false"*) wire                        fifo_empty;
    (*mark_debug = "false"*) wire                        fifo_write_enable;
    (*mark_debug = "false"*) wire [  AXI_DATA_WIDTH-1:0] fifo_write_data;
    (*mark_debug = "false"*) wire                        fifo_rd_en;
    (*mark_debug = "false"*) wire [  AXI_DATA_WIDTH-1:0] fifo_dout;
    (*mark_debug = "false"*) wire                        fifo_rd_empty;
    (*mark_debug = "false"*) wire                        fifo_rd_valid;
    (*mark_debug = "false"*) wire [$clog2(FIFO_DEPTH):0] fifo_wr_count;
    (*mark_debug = "false"*) wire [$clog2(FIFO_DEPTH):0] fifo_rd_count;

    // Cross-clock domain synchronisation (rd_clk -> axi_clk)
    // Use generic 3-FF synchroniser module to cut redundant registers
    // wire                                  sync_req_level;
    (*mark_debug = "false"*) wire                        sync_rd_req_level;
    (*mark_debug = "false"*) reg                         sync_rd_req_level_d1;
    (*mark_debug = "false"*) wire                        sync_rd_req;

    // ------------------------------------------------------------------------
    // Ping-Pong Control FSM (Read Path)
    // ------------------------------------------------------------------------
    localparam RD_IDLE = 2'b00;
    localparam RD_SEND_DESC = 2'b01;
    localparam RD_WAIT_STATUS = 2'b10;

    (*mark_debug = "false"*) reg [1:0] rd_fsm_state, rd_fsm_next_state;
    (*mark_debug = "false"*) reg                  rd_desc_valid;

    (*mark_debug = "false"*) reg  [TAG_WIDTH-1:0] rd_tag_counter;
    (*mark_debug = "false"*) wire [TAG_WIDTH-1:0] rd_sent_tag;
    (*mark_debug = "false"*) reg                  frame_read_start;
    (*mark_debug = "false"*) reg                  rd_buf_is_a;
    localparam IDLE = 2'b00;
    localparam PRE_STORE_ST = 2'b01;
    localparam WAIT_READ = 2'b10;
    localparam CONTINUE_RD = 2'b11;

    (*mark_debug = "false"*)reg  [               1:0] axi_state;
    (*mark_debug = "false"*) reg  [              15:0] data_count;
    (*mark_debug = "false"*) reg                       axis_tready_reg;

    (*mark_debug = "false"*) reg  [PACK_CNT_WIDTH-1:0] unpack_cnt_reg;
    (*mark_debug = "false"*) reg                       data_valid_reg;
    (*mark_debug = "false"*) reg  [DVP_DATA_WIDTH-1:0] dvp_data;
    (*mark_debug = "false"*) reg  [        1  - 1 : 0] vs_d1;
    (*mark_debug = "false"*) reg  [        1  - 1 : 0] vs_d2;
    (*mark_debug = "false"*) wire [        1  - 1 : 0] dvp_rst;
    // ------------------------------------------------------------------------
    // AXI clock domain synchronization
    // ------------------------------------------------------------------------
    sync_3ff u_sync_rd_req (
        .clk  (axi_clk),
        .rst_n(axi_rst_n),
        .din  (i_rd_data_vs),
        .dout (sync_rd_req_level)
    );

    always @(posedge axi_clk or negedge axi_rst_n) begin
        if (!axi_rst_n) sync_rd_req_level_d1 <= 1'b0;
        else sync_rd_req_level_d1 <= sync_rd_req_level;
    end

    assign sync_rd_req = sync_rd_req_level && !sync_rd_req_level_d1;  // rising edge detection
wire sync_rd_req_delay;
    data_avl_delay#(
    .DW    ( 1) ,
    .DELAY_NUM    ( 8)
    )inst_signal_delay2(
    .i_clk(axi_clk),
    .i_rst_n(axi_rst_n),
    .i_pixel_vld(1'b1),
    .i_data(sync_rd_req),
    .o_data(sync_rd_req_delay)
);
    always @(posedge axi_clk or negedge axi_rst_n) begin
        if (!axi_rst_n) begin
            rd_tag_counter <= {TAG_WIDTH{1'b0}};
        end else begin
            if (rd_fsm_state == RD_IDLE && sync_rd_req_delay) begin
                rd_tag_counter <= rd_tag_counter + 1'b1;
            end
        end
    end

    always @(posedge axi_clk or negedge axi_rst_n) begin
        if (!axi_rst_n) rd_fsm_state <= RD_IDLE;
        else rd_fsm_state <= rd_fsm_next_state;
    end

    always @(*) begin
        rd_fsm_next_state = rd_fsm_state;
        rd_desc_valid = 1'b0;
        frame_read_start = 1'b0;

        case (rd_fsm_state)
            RD_IDLE: begin
                if (sync_rd_req_delay) begin
                    rd_fsm_next_state = RD_SEND_DESC;
                end
            end

            RD_SEND_DESC: begin
                rd_desc_valid = 1'b1;
                if (s_axis_read_desc_ready) begin
                    rd_fsm_next_state = RD_WAIT_STATUS;
                    frame_read_start  = 1'b1;
                end
            end

            RD_WAIT_STATUS: begin
                if (m_axis_read_desc_status_valid && m_axis_read_desc_status_tag == rd_sent_tag) begin
                    rd_fsm_next_state = RD_IDLE;
                end
            end
        endcase
    end

    always @(posedge axi_clk or negedge axi_rst_n) begin
        if (!axi_rst_n) rd_buf_is_a <= 1'b0;
        else if (rd_fsm_state == RD_IDLE && sync_rd_req_delay) rd_buf_is_a <= ~rd_buf_is_a;
    end

    assign s_axis_read_desc_valid = rd_desc_valid;
    assign s_axis_read_desc_addr = rd_buf_is_a ? FRAME_BUFFER_BASE_ADDR_B : FRAME_BUFFER_BASE_ADDR_A;
    assign s_axis_read_desc_len = FRAME_SIZE_BYTES;
    assign s_axis_read_desc_tag = rd_tag_counter;
    assign rd_sent_tag = rd_tag_counter;

    always @(posedge axi_clk or negedge axi_rst_n) begin
        if (!axi_rst_n) begin
            axi_state       <= IDLE;
            data_count      <= 16'h0000;
            axis_tready_reg <= 1'b0;
        end else begin
            case (axi_state)
                IDLE: begin
                    data_count <= 16'h0000;
                    if (rd_fsm_state == RD_WAIT_STATUS) axi_state <= PRE_STORE_ST;
                end

                PRE_STORE_ST: begin
                    axis_tready_reg <= 1'b1;  // Enable ready signal for pre-stored data
                    if (m_axis_read_data_tvalid && axis_tready_reg) begin
                        data_count <= data_count + 1'b1;
                        // if (data_count + 1'b1 >= PRE_STORE_BEAT || m_axis_read_data_tlast) begin
                        if (data_count + 1'b1 >= AXI_BURST_LEN || m_axis_read_data_tlast) begin
                            axi_state       <= WAIT_READ;
                            axis_tready_reg <= 1'b0;
                        end
                    end
                end

                WAIT_READ: begin
                    data_count <= 0;
                    if (fifo_wr_count < AXI_BURST_LEN) axi_state <= CONTINUE_RD;
                end

                CONTINUE_RD: begin
                    axis_tready_reg <= 1'b1;
                    if (m_axis_read_data_tvalid && axis_tready_reg) begin
                        data_count <= data_count + 1'b1;
                        if (data_count + 1'b1 >= AXI_BURST_LEN || m_axis_read_data_tlast) begin
                            axi_state       <= WAIT_READ;
                            axis_tready_reg <= 1'b0;
                        end
                    end
                end

                default: begin
                    axi_state <= IDLE;
                end
            endcase
        end
    end

    // ------------------------------------------------------------------------
    // Synchronization circuits
    // ------------------------------------------------------------------------


    // ------------------------------------------------------------------------
    // FIFO Implementation
    // ------------------------------------------------------------------------
    DC_FIFO #(
        .FIFO_MODE ("ShowAhead"),
        .DATA_WIDTH(AXI_DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) u_dc_fifo (
        .Reset  (~axi_rst_n || ~rd_rst_n || dvp_rst),
        .WrClk  (axi_clk),
        .WrEn   (fifo_write_enable),
        .WrData (fifo_write_data),
        .WrFull (fifo_full),
        .WrDNum (fifo_wr_count),
        .RdClk  (rd_clk),
        .RdEn   (fifo_rd_en),
        .RdData (fifo_dout),
        .RdEmpty(fifo_rd_empty),
        .RdDNum (fifo_rd_count),
        .DataVal(fifo_rd_valid)
    );

    // ------------------------------------------------------------------------
    // FIFO write control
    // ------------------------------------------------------------------------
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            vs_d1 <= 1'b0;
            vs_d2 <= 1'b0;
        end else begin
            vs_d1 <= i_rd_data_vs;
            vs_d2 <= vs_d1;
        end
    end
    assign dvp_rst = ~vs_d2 && vs_d1;  // Reset DVP on VSYNC falling edge
    assign fifo_rd_en = i_rd_data_de && (~fifo_rd_empty) && (unpack_cnt_reg == PACK_RATIO - 1);
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) unpack_cnt_reg <= 0;
        else if (i_rd_data_de) begin
            if (unpack_cnt_reg == PACK_RATIO - 1) unpack_cnt_reg <= 0;
            else unpack_cnt_reg <= unpack_cnt_reg + 1'b1;
        end else unpack_cnt_reg <= 0;
    end

    always @(posedge rd_clk) begin
        data_valid_reg <= i_rd_data_de;
        dvp_data <= fifo_dout[unpack_cnt_reg*DVP_DATA_WIDTH+:DVP_DATA_WIDTH];
    end
    assign fifo_write_enable = m_axis_read_data_tvalid && axis_tready_reg;
    assign fifo_write_data = m_axis_read_data_tdata;
    assign m_axis_read_data_tready = axis_tready_reg;

    // ------------------------------------------------------------------------
    // Data unpacking logic (AXI_DATA_WIDTH -> DVP_DATA_WIDTH)
    // ------------------------------------------------------------------------

    // ------------------------------------------------------------------------
    // Output assignments
    // ------------------------------------------------------------------------
    assign o_vs = vs_d2;//i_rd_data_vs;
    assign o_de = data_valid_reg;  // && word_valid;
    assign o_data = dvp_data;  //pixel_sel;

    // ------------------------------------------------------------------------
    // Underflow detection
    // ------------------------------------------------------------------------
    // assign underflow = i_rd_data_de && !word_valid;
    // assign frame_done_rd = (rd_fsm_state == RD_WAIT_STATUS) && m_axis_read_desc_status_valid && (m_axis_read_desc_status_tag == rd_sent_tag);

    // ------------------------------------------------------------------------
    // Debug
    // ------------------------------------------------------------------------
    (*mark_debug = "false"*)reg [16  - 1 : 0] dbg_dma_cnt;
    (*mark_debug = "false"*)reg [16  - 1 : 0] dbg_hcnt;
    (*mark_debug = "false"*)reg [16  - 1 : 0] dbg_vcnt;
    always @(posedge axi_clk or negedge axi_rst_n) begin
        if (!axi_rst_n) dbg_dma_cnt <= 1'b0;
        else if (frame_read_start) dbg_dma_cnt <= 1'b0;
        else if (m_axis_read_data_tvalid && m_axis_read_data_tready) dbg_dma_cnt <= dbg_dma_cnt + 1;
    end
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            dbg_hcnt <= 'd0;
        end else if (o_de) begin
            dbg_hcnt <= dbg_hcnt==FRAME_WIDTH-1?0:dbg_hcnt + 1'b1;
        end else begin
            dbg_hcnt <= 'd0;
        end
    end
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            dbg_vcnt <= 'd0;
        end else if (o_de) begin
            dbg_vcnt <= dbg_hcnt==FRAME_WIDTH-1?dbg_vcnt + 1'b1:dbg_vcnt;
        end else begin
            dbg_vcnt <= 'd0;
        end
    end
endmodule
