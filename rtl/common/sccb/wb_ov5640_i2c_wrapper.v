`timescale 1ns / 1ps

module wb_ov5640_i2c_wrapper #(
    parameter CLK_FREQ = 100_000_000, // Wishbone System Clock Frequency (Hz)
    parameter I2C_FREQ = 200_000      // Target SCCB/I2C Clock Frequency (Hz)
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

    // --- Internal Signals ---
    reg [31:0] tx_data_reg;    // Transmit Data Buffer
    reg [15:0] counts_reg;     // {rd_cnt, wr_cnt}
    reg        ctrl_mode;      // 0=Normal, 1=SCCB/Random
    reg        start_pulse;    // Start Signal
    
    wire [7:0] rx_data_wire;   // Receive Data
    wire       iic_busy;       // Busy Status

    // --- Wishbone Bus Logic ---
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            tx_data_reg <= 32'd0;
            counts_reg  <= 16'd0;
            ctrl_mode   <= 1'b0;
            start_pulse <= 1'b0;
            wb_ack_o    <= 1'b0;
        end else begin
            // Auto-clear Start signal: when Busy detected or transfer triggered
            if (iic_busy || start_pulse) start_pulse <= 1'b0; 
            
            // Generate ACK signal (1-cycle delay)
            wb_ack_o <= wb_stb_i && wb_cyc_i && !wb_ack_o;

            // Write Register Logic
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

    // Read Register Logic
    always @(*) begin
        wb_dat_o = 32'd0;
        case (wb_adr_i)
            3'd0: wb_dat_o = {30'd0, ctrl_mode, 1'b0}; // REG_CTRL (Start reads as 0)
            3'd1: wb_dat_o = {31'd0, iic_busy};        // REG_STATUS (0x04)
            3'd2: wb_dat_o = {16'd0, counts_reg};      // REG_CFG (0x08)
            3'd3: wb_dat_o = tx_data_reg;              // REG_TX (0x0C)
            3'd4: wb_dat_o = {24'd0, rx_data_wire};    // REG_RX (0x10)
            default: wb_dat_o = 32'd0;
        endcase
    end

    // --- Instantiate I2C Core ---
    // Auto Calculate Divider: System_Clk / (4 * I2C_Freq)
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
