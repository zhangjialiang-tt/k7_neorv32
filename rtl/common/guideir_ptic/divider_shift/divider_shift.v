// ------------------------------------------------------------------------------------------------
// Company                      : Wuhan Guide Sensmart Tech Co., Ltd
// Create Date                  : 20231110
// Author Name                  : zhangjl
// Module Name                  :
// Project Name                 :
// Tarject Device               : Titanium-ti180
// Tool Versions                : Efinity-2022.2.322.5.7
// Description                  : 该文件实现一个整数除2的n次幂，已移位方式实现
//                                  - 将a扩展1bit，成为n+1bit的数据，正数补0，负数补1；
//                                  - a算术右移`(b-1)`个bit；
//                                  - 移位结果加1；
//                                  - 截取移位结果的高`n`bit；
// Parameter Description        : IMAGE_WIDTH-->图像宽度
//                                IMAGE_HEIGHT-->图像高度
// Port Description             :
// Revision                     : 1.00.0
// Modified by                  :
// Modified Data                :
// Additional Comments          :
// Standard Syndoc              :
// ------------------------------------------------------------------------------------------------
module divider_shift #(
    parameter PIPELINE = 1,//0,1,2,3,4
    parameter DW = 32,
    parameter DENOM = 1024
) (
    //global input interface
    input  wire [1       - 1 : 0] i_Sys_clk,
    input  wire [1       - 1 : 0] i_Rst_n,
    input  wire [DW      - 1 : 0] i_Numer,
    output wire [DW      - 1 : 0] o_Quotient
);  //divider_shift
    //**********************************************************************************************
    //parameter and regs defination
    //**********************************************************************************************
    localparam HALF_DENOM = DENOM/2;
    localparam DENOM_W = $clog2(DENOM);
    localparam SHIFT_W = DENOM_W;//$clog2(DENOM_W);
    localparam SHIFT_W_1 = SHIFT_W-1'b1;//$clog2(DENOM_W)-1'b1;
    reg [DW+1      - 1 : 0] numer1;
    reg [DW+1      - 1 : 0] numer2;
    reg [DW+1      - 1 : 0] numer3;
    reg [DW      - 1 : 0] numer4;
    //**********************************************************************************************
    //4步
    //**********************************************************************************************
    generate
        if (PIPELINE == 0) begin : g_delay_1
            always @ ( * ) begin
            // always @ ( posedge i_Sys_clk ) begin
                if(~i_Rst_n) numer1<='d0;
                else numer1<=$signed(i_Numer);
            end
            always @ ( * ) begin
            // always @ ( posedge i_Sys_clk ) begin
                if(~i_Rst_n) numer2<='d0;
                else if($signed(numer1)>0 && numer1>HALF_DENOM) numer2 <= ($signed(numer1)>>>SHIFT_W_1);
                else if($signed(numer1)<0 && (~numer1+1)>HALF_DENOM) numer2 <= ($signed(numer1)>>>SHIFT_W_1);
            end
            always @ ( * ) begin
            // always @ ( posedge i_Sys_clk ) begin
                if(~i_Rst_n) numer3<='d0;
                else numer3 <= $signed(numer2)+1'b1;
            end
            always @ ( * ) begin
            // always @ ( posedge i_Sys_clk ) begin
                if(~i_Rst_n) numer4<='d0;
                else numer4 <= numer3[1+:DW];
            end
        end else if (PIPELINE == 1) begin : g_delay_2
            always @ ( * ) begin
            // always @ ( posedge i_Sys_clk ) begin
                if(~i_Rst_n) numer1<='d0;
                else numer1<=$signed(i_Numer);
            end
            always @ ( * ) begin
            // always @ ( posedge i_Sys_clk ) begin
                if(~i_Rst_n) numer2<='d0;
                else if($signed(numer1)>0 && numer1>HALF_DENOM) numer2 <= ($signed(numer1)>>>SHIFT_W_1);
                else if($signed(numer1)<0 && (~numer1+1)>HALF_DENOM) numer2 <= ($signed(numer1)>>>SHIFT_W_1);
            end
            // always @ ( * ) begin
            always @ ( posedge i_Sys_clk ) begin
                if(~i_Rst_n) numer3<='d0;
                else numer3 <= $signed(numer2)+1'b1;
            end
            always @ ( * ) begin
            // always @ ( posedge i_Sys_clk ) begin
                if(~i_Rst_n) numer4<='d0;
                else numer4 <= numer3[1+:DW];
            end
        end else if (PIPELINE == 2) begin : g_delay_2
            always @ ( * ) begin
            // always @ ( posedge i_Sys_clk ) begin
                if(~i_Rst_n) numer1<='d0;
                else numer1<=$signed(i_Numer);
            end
            // always @ ( * ) begin
            always @ ( posedge i_Sys_clk ) begin
                if(~i_Rst_n) numer2<='d0;
                else if($signed(numer1)>0 && numer1>HALF_DENOM) numer2 <= ($signed(numer1)>>>SHIFT_W_1);
                else if($signed(numer1)<0 && (~numer1+1)>HALF_DENOM) numer2 <= ($signed(numer1)>>>SHIFT_W_1);
            end
            // always @ ( * ) begin
            always @ ( posedge i_Sys_clk ) begin
                if(~i_Rst_n) numer3<='d0;
                else numer3 <= $signed(numer2)+1'b1;
            end
            always @ ( * ) begin
            // always @ ( posedge i_Sys_clk ) begin
                if(~i_Rst_n) numer4<='d0;
                else numer4 <= numer3[1+:DW];
            end
        end else if (PIPELINE == 3) begin : g_delay_3
            always @ ( * ) begin
            // always @ ( posedge i_Sys_clk ) begin
                if(~i_Rst_n) numer1<='d0;
                else numer1<=$signed(i_Numer);
            end
            // always @ ( * ) begin
            always @ ( posedge i_Sys_clk ) begin
                if(~i_Rst_n) numer2<='d0;
                else if($signed(numer1)>0 && numer1>HALF_DENOM) numer2 <= ($signed(numer1)>>>SHIFT_W_1);
                else if($signed(numer1)<0 && (~numer1+1)>HALF_DENOM) numer2 <= ($signed(numer1)>>>SHIFT_W_1);
            end
            // always @ ( * ) begin
            always @ ( posedge i_Sys_clk ) begin
                if(~i_Rst_n) numer3<='d0;
                else numer3 <= $signed(numer2)+1'b1;
            end
            // always @ ( * ) begin
            always @ ( posedge i_Sys_clk ) begin
                if(~i_Rst_n) numer4<='d0;
                else numer4 <= numer3[1+:DW];
            end
        end else if (PIPELINE == 4) begin : g_delay_4
            // always @ ( * ) begin
            always @ ( posedge i_Sys_clk ) begin
                if(~i_Rst_n) numer1<='d0;
                else numer1<=$signed(i_Numer);
            end
            // always @ ( * ) begin
            always @ ( posedge i_Sys_clk ) begin
                if(~i_Rst_n) numer2<='d0;
                else if($signed(numer1)>0 && numer1>HALF_DENOM) numer2 <= ($signed(numer1)>>>SHIFT_W_1);
                else if($signed(numer1)<0 && (~numer1+1)>HALF_DENOM) numer2 <= ($signed(numer1)>>>SHIFT_W_1);
                else numer2 <= 0;
            end
            // always @ ( * ) begin
            always @ ( posedge i_Sys_clk ) begin
                if(~i_Rst_n) numer3<='d0;
                else numer3 <= $signed(numer2) + 1;
            end
            // always @ ( * ) begin
            always @ ( posedge i_Sys_clk ) begin
                if(~i_Rst_n) numer4<='d0;
                else numer4 <= numer3[1+:DW];
            end
        end
    endgenerate
    assign o_Quotient = numer4;
    
    // else if($signed(numer1)>0 && numer1>DENOM) numer2 <= (numer1>>>SHIFT_W_1);
    // else if($signed(numer1)<0 && (~numer1+1)>DENOM) numer2 <= (numer1>>>SHIFT_W_1);
    // else numer2 <= 0;

endmodule
