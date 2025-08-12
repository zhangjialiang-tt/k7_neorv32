// ------------------------------------------------------------------------------------------------
// Company                      : Wuhan Guide Sensmart Tech Co., Ltd
// Create Date                  : 20231110
// Author Name                  : zhangjl
// Module Name                  :
// Project Name                 :
// Tarject Device               : Titanium-ti180
// Tool Versions                : Efinity-2022.2.322.5.7
// Description                  : 将ddr中的数据读出
//                              
//                              
//                              
// Parameter Description        : IMAGE_WIDTH-->图像宽度
//                                IMAGE_HEIGHT-->图像高度
// Port Description             :
// Revision                     : 1.00.0000
// Modified by                  :
// Modified Data                :
// Additional Comments          :
// Standard Syndoc              :
// ------------------------------------------------------------------------------------------------
module ddr_to_logic #(
    parameter DW           = 16,
    parameter AXI_AW       = 32,
    parameter RST_DELAY    = 'd640
) (
    //global input interface
    input  wire [ 1       - 1 : 0] i_Sys_clk,
    input  wire [ 1       - 1 : 0] i_Rst_n,
    input  wire [ 1       - 1 : 0] i_Din_vs,
    input  wire [ 1       - 1 : 0] i_Din_hs,
    input  wire [AXI_AW   - 1 : 0] i_last_addr1,
    input  wire [AXI_AW   - 1 : 0] i_last_addr2,
    output wire [1        - 1 : 0] o_last_rd_rst,
    output wire [1        - 1 : 0] o_last_rd_vs,
    output wire [1        - 1 : 0] o_last_rd_hs,
    input  wire [DW       - 1 : 0] i_last_rd_data,
    output wire [AXI_AW   - 1 : 0] o_last_rd_addr,
    output wire [ 1       - 1 : 0] o_Dout_vs,
    output wire [ 1       - 1 : 0] o_Dout_valid,
    output wire [ DW      - 1 : 0] o_Dout
);  //ddr_to_logic
    //************************parameter defination***********************
    wire [1   - 1 : 0] axi_reset;
    wire [1   - 1 : 0] last_rd_vs;
    wire [1   - 1 : 0] last_rd_hs;
    wire [1   - 1 : 0] last_rd_rst;
    reg  [  1 - 1 : 0] switch_flag;
    //**********************************************************************************************
    //function
    //**********************************************************************************************
    gen_axi_reset_v2 #(
        .RST_DELAY                          (512                       ),
        .RST_PERIOD                         (30                        ) 
    ) gen_axi_reset_inst (
        .i_Sys_clk                          (i_Sys_clk                 ),
        .i_Rst_n                            (i_Rst_n                   ),
        .i_Field_sync                       (i_Din_vs                  ),
        .o_Axi_reset                        (axi_reset                 ) 
    );
    assign last_rd_rst = axi_reset;
    assign last_rd_vs = i_Din_vs;
    assign last_rd_hs = i_Din_hs;
    //************************reg signal defination***********************
    always @(posedge i_Sys_clk) begin
        if (!i_Rst_n) begin
            switch_flag <= 0;
        end else if (axi_reset) begin
            switch_flag <= ~switch_flag;
        end else begin
            switch_flag <= switch_flag;
        end
    end
    assign o_last_rd_rst  = last_rd_rst;
    assign o_last_rd_addr = switch_flag ? i_last_addr1 : i_last_addr2;
    assign o_last_rd_vs  = last_rd_vs;
    assign o_last_rd_hs  = last_rd_hs;
    //**********************************************************************************************
    //function
    //**********************************************************************************************
    reg [1  - 1 : 0] dout_vs;
    reg [1  - 1 : 0] dout_vld;
    always @(posedge i_Sys_clk) begin
        if (~i_Rst_n) begin
            dout_vs <= 'd0;
            dout_vld <= 'd0;
        end else begin
            dout_vs <= i_Din_vs;
            dout_vld <= i_Din_hs;
        end
    end
    assign o_Dout_vs = dout_vs;
    assign o_Dout_valid = dout_vld;
    assign o_Dout = dout_vld ? i_last_rd_data : 0;
    // always @ ( posedge i_Sys_clk ) begin
    //     if(~i_Rst_n) begin
    //         o_Dout_valid<='d0;
    //         o_Dout<='d0;
    //     end
    //     else begin
    //         o_Dout_valid<=dout_vld;
    //         o_Dout<=i_last_rd_data;
    //     end
    // end
endmodule
