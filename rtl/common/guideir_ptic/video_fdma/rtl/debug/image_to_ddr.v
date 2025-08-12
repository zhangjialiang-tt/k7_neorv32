// ------------------------------------------------------------------------------------------------
// Company                      : Wuhan Guide Sensmart Tech Co., Ltd
// Create Date                  : 20231110
// Author Name                  : zhangjl
// Module Name                  :
// Project Name                 :
// Tarject Device               : Titanium-ti180
// Tool Versions                : Efinity-2022.2.322.5.7
// Description                  : 将数据流写入到ddr中
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
module image_to_ddr #(
    parameter                           CW                        = 10    ,
    parameter                           DW                        = 16    ,
    parameter                           AXI_AW                    = 32    ,
    parameter                           IMAGE_WIDTH               = 'd640 ,
    parameter                           IMAGE_HEIGHT              = 'd480 
) (
    //global input interface
    input  wire        [ 1       - 1 : 0]i_Sys_clk                 ,
    input  wire        [ 1       - 1 : 0]i_Rst_n                   ,
    input  wire        [ 1       - 1 : 0]i_Fix_en               ,
    input  wire        [ 1       - 1 : 0]i_Din_field_sync               ,
    input  wire        [ 1       - 1 : 0]i_Din_valid               ,
    input  wire        [ DW      - 1 : 0]i_Din                     ,
    input  wire        [AXI_AW   - 1 : 0]i_last_addr1              ,
    input  wire        [AXI_AW   - 1 : 0]i_last_addr2              ,
    output wire        [1        - 1 : 0]o_last_wr_rst             ,
    output wire        [1        - 1 : 0]o_last_wr_req             ,
    output wire        [1        - 1 : 0]o_last_wr_vs             ,
    output wire        [1        - 1 : 0]o_last_wr_hs             ,
    output wire        [DW       - 1 : 0]o_last_wr_data            ,
    output wire        [AXI_AW   - 1 : 0]o_last_wr_addr             
);  //image_to_ddr
    //**********************************************************************************************
    localparam DVP_DATA_FRAME_SIZE = IMAGE_WIDTH * IMAGE_HEIGHT * DW / 8;
    //**********************************************************************************************
    reg  [  1 - 1 : 0] last_wr_rst;
    reg  [  1 - 1 : 0] last_wr_req;
    reg  [  1 - 1 : 0] last_wr_vs;
    reg  [  1 - 1 : 0] last_wr_hs;
    reg  [ DW - 1 : 0] last_wr_data;
    reg  [  1 - 1 : 0] switch_flag;
    wire [1   - 1 : 0] axi_reset;
    gen_axi_reset_v2 #(
        .RST_DELAY                          (512                       ),
        .RST_PERIOD                         (30                        ) 
    ) gen_axi_reset_inst (
        .i_Sys_clk                          (i_Sys_clk                 ),
        .i_Rst_n                            (i_Rst_n                   ),
        .i_Field_sync                       (i_Din_field_sync               ),
        .o_Axi_reset                        (axi_reset                 ) 
    );


    always @(posedge i_Sys_clk) begin
        if (!i_Rst_n) begin
            switch_flag <= 0;
        end else if (axi_reset) begin
            switch_flag <= ~switch_flag;
        end else begin
            switch_flag <= switch_flag;
        end
    end
    always @(posedge i_Sys_clk) begin
        if (~i_Rst_n) begin
            last_wr_rst  <= 'd0;
            last_wr_req  <= 'd0;
            last_wr_vs  <= 'd0;
            last_wr_hs  <= 'd0;
            last_wr_data <= 'd0;
        end else begin
            last_wr_rst  <= axi_reset;
            last_wr_req  <= i_Din_valid;
            last_wr_vs  <= i_Din_field_sync;
            last_wr_hs  <= i_Din_valid;
            last_wr_data <= i_Din;
        end
    end
    reg           [ 8  - 1 : 0 ]                 din_hcnt        ;
    always @ ( posedge i_Sys_clk ) begin
        if(~i_Rst_n)    din_hcnt <= 'd0;
        else if(i_Din_valid)       din_hcnt <= din_hcnt + 'd1;
        else            din_hcnt <= 'd0;
    end
    assign o_last_wr_rst  = i_Fix_en?1'b0:last_wr_rst;
    assign o_last_wr_addr = switch_flag ? i_last_addr2 : i_last_addr1;
    assign o_last_wr_req  = i_Fix_en?1'b0:last_wr_req;
    assign o_last_wr_vs  = i_Fix_en?1'b0:last_wr_vs;
    assign o_last_wr_hs  = i_Fix_en?1'b0:last_wr_hs;
    assign o_last_wr_data = i_Fix_en?{DW{1'b0}}:din_hcnt;
    // assign o_last_wr_len  = DVP_DATA_FRAME_SIZE;
    //**********************************************************************************************
endmodule
