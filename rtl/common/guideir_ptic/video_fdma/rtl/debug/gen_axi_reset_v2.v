// ------------------------------------------------------------------------------------------------
// Company                      : Wuhan Guide Sensmart Tech Co., Ltd
// Create Date                  : 20240708
// Author Name                  : zhangjl
// Module Name                  : debug
// Project Name                 : zp44b
// Tarject Device               : Titanium-ti180
// Tool Versions                : Efinix Efinity-2023.2.307.1.14
// Description                  : 生成axi读写控制模块复位信号
//                              
//                              
//                              
// Parameter Description        : IMAGE_WIDTH-->图像宽度
//                                IMAGE_HEIGHT-->图像高度
// Port Description             :
// Revision                     : 1.00.0
// Modified by                  :
// Modified Data                :
// Additional Comments          :
// Standard Syndoc              :
// ------------------------------------------------------------------------------------------------
module gen_axi_reset_v2 #(
    //复位延时，检测到i_Field_sync信号下降沿后开始延时
    parameter                           RST_DELAY            = 512,
    //复位长度，延时结束后开始复位，复位长度为RST_PERIOD
    parameter                           RST_PERIOD            = 30
) (
    //global input interface
    input  wire        [1       - 1 : 0]i_Sys_clk                  ,
    input  wire        [1       - 1 : 0]i_Rst_n                    ,
    input  wire        [1       - 1 : 0]i_Field_sync               ,
    output reg         [1       - 1 : 0]o_Axi_reset                 
);  //gen_axi_reset
    //**********************************************************************************************
    //parameter and regs defination
    //**********************************************************************************************
    localparam CNT_LEN                   = RST_DELAY + RST_PERIOD;
    localparam RST_BEGIN                 = RST_DELAY;
    localparam RST_END                   = CNT_LEN-1;
    localparam CNT_W                     = $clog2(CNT_LEN);
    reg                [ 1      - 1 : 0]   i_Field_sync_d1            ;
    reg                [ 1      - 1 : 0]   i_Field_sync_d2            ;
    wire               [ 1      - 1 : 0]   i_Field_sync_neg           ;
    reg                [CNT_W   - 1 : 0]   wait_count                 ;
    //**********************************************************************************************
    always @(posedge i_Sys_clk) begin
        if (~i_Rst_n) begin
            i_Field_sync_d1 <= 'd0;
            i_Field_sync_d2 <= 'd0;
        end else begin
            i_Field_sync_d1 <= i_Field_sync;
            i_Field_sync_d2 <= i_Field_sync_d1;
        end
    end
    assign i_Field_sync_neg = ~i_Field_sync_d1 && i_Field_sync_d2;//下降沿
    always @(posedge i_Sys_clk) begin
        if (~i_Rst_n)                           wait_count <= 'd0;
        else if (i_Field_sync_neg)              wait_count <= 'd0;
        else begin
            if (wait_count == CNT_LEN)          wait_count <= wait_count;
            else                                wait_count <= 'd1 + wait_count;
        end
    end
    always @(posedge i_Sys_clk) begin
        if (~i_Rst_n)                       o_Axi_reset <= 'd0;
        else if (wait_count == RST_END)     o_Axi_reset <= 'd0;
        else if (wait_count == RST_BEGIN)   o_Axi_reset <= 'd1;
    end
endmodule
