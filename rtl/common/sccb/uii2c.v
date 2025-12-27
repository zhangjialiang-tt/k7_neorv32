`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////

/// \brief      I2C ??????
/// \details    ?????????????????255??????1???????
///             ???255???????? SCCB?Serial Camera Control Bus????
/// \author     Liyang Milian Electronic Technology Co., Ltd.
/// \date       2019/02/27
/// \version    v1.0
/// \note       ?? Verilog-2001 ????????
////////////////////////////////////////////////////////////////////////////////

module uii2c #(
    parameter WMEN_LEN = 'd4,  // ????????
    parameter RMEN_LEN = 'd1,  // ????????
    parameter CLK_DIV  = 'd499 // ????????? I2C SCL ??
) (
    // ?????
    input  wire [1 - 1 : 0]          i_clk,          // ??????
    
    // I2C ??
    output wire [1 - 1 : 0]          o_iic_scl,      // I2C ????
    inout  wire [1 - 1 : 0]          io_iic_sda,     // I2C ??????
    
    // ?????
    input  wire [WMEN_LEN * 8 - 1 : 0] i_wr_data,    // ???????????
    input  wire [7 : 0]               i_wr_cnt,      // ?????????????
    
    // ?????
    output wire [RMEN_LEN * 8 - 1 : 0] o_rd_data,    // ?????
    input  wire [7 : 0]               i_rd_cnt,      // ?????
    
    // ????
    input  wire [1 - 1 : 0]           i_iic_en,      // I2C ?????????
    input  wire [1 - 1 : 0]           i_iic_mode,    // I2C ???1=????0=???/??
    output wire [1 - 1 : 0]           o_iic_busy,    // I2C ??????
    output wire [1 - 1 : 0]           o_sda_dg       // SDA ??????? ILA?
);

// ============================================================================
// ???????
// ============================================================================
localparam IDLE    = 'd0;  // ????
localparam START   = 'd1;  // ????
localparam W_WAIT  = 'd2;  // ???????
localparam W_ACK   = 'd3;  // ?????
localparam R_WAIT  = 'd4;  // ???????
localparam R_ACK   = 'd5;  // ?????
localparam STOP1   = 'd6;  // ??????1
localparam STOP2   = 'd7;  // ??????2

// ============================================================================
// ??????
// ============================================================================
localparam STATE_W      = $clog2('d8);  // ?????
localparam CLK_DIV_W    = $clog2(CLK_DIV + 'd1);  // ?????????
localparam OFFSET       = CLK_DIV - CLK_DIV / 'd4;  // SCL ?????

// ============================================================================
// ??????
// ============================================================================
reg  [STATE_W - 1 : 0]   iic_s;          // I2C ?????
reg  [CLK_DIV_W - 1 : 0] clkdiv;         // ???????
reg  [1 - 1 : 0]         scl_clk;        // SCL ????
wire [1 - 1 : 0]         scl_offset;     // SCL ??????
reg  [1 - 1 : 0]         iic_busy_r;     // I2C ??????
reg  [1 - 1 : 0]         scl_r;          // SCL ?????
reg  [1 - 1 : 0]         sda_o;          // SDA ?????
reg  [7 : 0]             sda_r;          // SDA ???????
reg  [7 : 0]             sda_i_r;        // SDA ???????
reg  [7 : 0]             wcnt;           // ??????
reg  [7 : 0]             rcnt;           // ??????
reg  [2 : 0]             bcnt;           // ????
reg  [1 - 1 : 0]         rd_en;          // ?????
wire [1 - 1 : 0]         sda_i;          // SDA ????
reg  [1 - 1 : 0]         iic_sda_r;      // SDA ?????

// ============================================================================
// ?????? SCL ??
// ============================================================================
always @(posedge i_clk) begin
    if (clkdiv < CLK_DIV) begin
        clkdiv <= clkdiv + 'd1;
    end else begin
        clkdiv  <= 'd0;
        scl_clk <= ~scl_clk;
    end
end

assign scl_offset = (clkdiv == OFFSET);

// ============================================================================
// I2C SDA ?????Xilinx IOBUF ???
// ============================================================================
IOBUF #(
    .DRIVE(12),            // ??????
    .IBUF_LOW_PWR("TRUE"), // ?????
    .IOSTANDARD("DEFAULT"),// I/O ??
    .SLEW("SLOW")          // ??????
) IOBUF_inst (
    .O(sda_i),             // ??????????
    .IO(io_iic_sda),       // ????
    .I(sda_o),             // ??????????
    .T(sda_o)              // ??????=????=??
);

// ============================================================================
// SDA ?????Xilinx PULLUP ???
// ============================================================================
PULLUP PULLUP_inst (
    .O(io_iic_sda)
);

// ============================================================================
// SCL ??????????????
// ============================================================================
reg [1 - 1 : 0] iic_scl_r;

always @(posedge i_clk) begin
    iic_scl_r <= scl_offset ? scl_r : iic_scl_r;
end

assign o_iic_scl = iic_scl_r;

// ============================================================================
// SCL ????
// ============================================================================
always @(*) begin
    if (iic_s == IDLE || iic_s == STOP1 || iic_s == STOP2) begin
        scl_r = 1'b1;
    end else begin
        scl_r = ~scl_clk;
    end
end

// ============================================================================
// SDA ????
// ============================================================================
always @(*) begin
    if (iic_s == START || iic_s == STOP1 || (iic_s == R_ACK && (rcnt != i_rd_cnt))) begin
        sda_o = 1'b0;
    end else if (iic_s == W_WAIT) begin
        sda_o = sda_r[7];
    end else begin
        sda_o = 1'b1;
    end
end

// ============================================================================
// SDA ???????
// ============================================================================
always @(negedge scl_clk) begin
    if (iic_s == W_ACK || iic_s == START) begin
        sda_r <= i_wr_data[(wcnt * 8) +: 8];
        if (rd_en) begin
            sda_r <= {i_wr_data[7:1], 1'b1};
        end
    end else if (iic_s == W_WAIT) begin
        sda_r <= {sda_r[6:0], 1'b1};
    end else begin
        sda_r <= sda_r;
    end
end

// ============================================================================
// SDA ???????
// ============================================================================
reg [RMEN_LEN * 8 - 1 : 0] rd_data_r;

always @(posedge scl_clk) begin
    if (iic_s == R_WAIT || iic_s == W_ACK) begin
        sda_i_r <= {sda_i_r[6:0], sda_i};
    end else if (iic_s == R_ACK) begin
        rd_data_r[((rcnt - 1'b1) * 8) +: 8] <= sda_i_r[7:0];
    end else if (iic_s == IDLE) begin
        sda_i_r <= 'd0;
    end
end

// ============================================================================
// SDA ?????????
// ============================================================================
always @(posedge scl_clk) begin
    iic_sda_r <= sda_i;
end

reg [1 - 1 : 0] sda_dg_r;

always @(posedge i_clk) begin
    sda_dg_r <= sda_i;
end

assign o_sda_dg = sda_dg_r;
assign o_rd_data = rd_data_r;
assign o_iic_busy = iic_busy_r;

// ============================================================================
// I2C ????? SCL ??????
// ============================================================================
always @(negedge scl_clk) begin
    case (iic_s)
        // --------------------------------------------------------------------
        // IDLE: ????????????????
        // --------------------------------------------------------------------
        IDLE: begin
            if (i_iic_en == 1'b1 || rd_en == 1'b1) begin
                iic_busy_r <= 1'b1;
                iic_s      <= START;
            end else begin
                iic_busy_r <= 1'b0;
                wcnt       <= 'd0;
                rcnt       <= 'd0;
                rd_en      <= 1'b0;
            end
        end
        
        // --------------------------------------------------------------------
        // START: ???????SDA=0??? SCL=0?
        // --------------------------------------------------------------------
        START: begin
            bcnt  <= 'd7;
            iic_s <= W_WAIT;
        end
        
        // --------------------------------------------------------------------
        // W_WAIT: ????????8????
        // --------------------------------------------------------------------
        W_WAIT: begin
            if (bcnt > 'd0) begin
                bcnt <= bcnt - 1'b1;
            end else begin
                wcnt  <= wcnt + 1'b1;
                iic_s <= W_ACK;
            end
        end
        
        // --------------------------------------------------------------------
        // W_ACK: ??????????????????
        // --------------------------------------------------------------------
        W_ACK: begin
            if (wcnt < i_wr_cnt) begin
                bcnt  <= 'd7;
                iic_s <= W_WAIT;
            end else if (i_rd_cnt > 'd0) begin
                // ??????
                if (rd_en == 1'b0 && i_iic_mode == 1'b1) begin
                    // ??????????
                    rd_en <= 1'b1;
                    iic_s <= IDLE;
                end else begin
                    // ????????
                    iic_s <= R_WAIT;
                end
                bcnt <= 'd7;
            end else begin
                // ???????????
                iic_s <= STOP1;
            end
        end
        
        // --------------------------------------------------------------------
        // R_WAIT: ????????8????
        // --------------------------------------------------------------------
        R_WAIT: begin
            rd_en <= 1'b0;
            bcnt  <= bcnt - 1'b1;
            if (bcnt == 'd0) begin
                rcnt  <= (rcnt < i_rd_cnt) ? (rcnt + 1'b1) : rcnt;
                iic_s <= R_ACK;
            end
        end
        
        // --------------------------------------------------------------------
        // R_ACK: ????????????????
        // --------------------------------------------------------------------
        R_ACK: begin
            bcnt  <= 'd7;
            iic_s <= (rcnt < i_rd_cnt) ? R_WAIT : STOP1;
        end
        
        // --------------------------------------------------------------------
        // STOP1: ??????1?SDA=0?SCL=1?
        // --------------------------------------------------------------------
        STOP1: begin
            iic_s <= STOP2;
        end
        
        // --------------------------------------------------------------------
        // STOP2: ??????2?SDA=1?SCL=1?
        // --------------------------------------------------------------------
        STOP2: begin
            iic_s <= IDLE;
        end
        
        // --------------------------------------------------------------------
        // ????
        // --------------------------------------------------------------------
        default: begin
            iic_s <= IDLE;
        end
    endcase
end

endmodule // uii2c
