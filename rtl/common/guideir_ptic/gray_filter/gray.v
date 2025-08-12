// ------------------------------------------------------------------------------------------------
// Company                      : Wuhan Guide Sensmart Tech Co., Ltd
// Create Date                  : 20240731
// Author Name                  : zhangjl
// Module Name                  : gray_filter
// Project Name                 : zp44b
// Tarject Device               : Titanium-ti180
// Tool Versions                : Efinix Efinity-2023.2.307.1.14
// Description                  : 对输入图像进行单边灰度滤波
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
module gray_filter #(
    parameter CW = 10,
    parameter DW = 16,
    parameter IMAGE_WIDTH = 'd640,
    parameter IMAGE_HEIGHT = 'd480
) (
    //global input interface
    input  wire [1       - 1 : 0] i_Sys_clk,
    input  wire [1       - 1 : 0] i_Rst_n,
    input  wire [1       - 1 : 0] i_Din_valid,
    input  wire [DW      - 1 : 0] i_Din,
    output wire [1       - 1 : 0] o_Dout_valid,
    output wire [DW      - 1 : 0] o_Dout
);  //gray_filter
    //**********************************************************************************************
    //parameter and regs defination
    //**********************************************************************************************
`ifndef SIM//以工程文件所在路径为根目录
    parameter RAM_INIT_FILE1 = "rtl/algorithm/eis/tan_lut_rom/tan_angle.inithex";
`else//以do文件所在路径为根目录
    parameter RAM_INIT_FILE1 = "../../rtl/iie/tan_angle.inithex";
`endif
    reg [1   - 1 : 0] en_cnt;
    reg [DW  - 1 : 0] cnt;


    //**********************************************************************************************
    // 权重表，该表由脚本生成
    //**********************************************************************************************

    // auto genetated by cal_gray_weigh_table.py
    single_port_rom #(
        .DATA_WIDTH                         (12                        ),
        .ADDR_WIDTH                         (9                        ),
        .OUTPUT_REG                         ("FALSE"                   ),
        .RAM_INIT_FILE                      (RAM_INIT_FILE1            ) 
    ) angle_rom_inst (
        .clk                                (i_Sys_clk                 ),
        .addr                               (index_addr                ),
        .data                               (angle_index               )
    );
    // auto genetated done
endmodule
