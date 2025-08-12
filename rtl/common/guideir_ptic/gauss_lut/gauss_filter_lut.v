// ------------------------------------------------------------------------------------------------
// Company                      : Wuhan Guide Sensmart Tech Co., Ltd
// Create Date                  : 20231110
// Author Name                  : zhangjl
// Module Name                  :
// Project Name                 :
// Tarject Device               : Titanium-ti180
// Tool Versions                : Efinity-2022.2.322.5.7
// Description                  : 该文件使用查表方式实现高斯滤波
//                                  使用python脚本实现查表数据的生成和移位运算的实现
//                                  python脚本-gauss_coef_decom.py
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
module gauss_filter_lut #(
    parameter K_SIZE = 5,
    parameter STD = 1,
    parameter SCALER = 1024,
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

    output wire [1       - 1 : 0] o_Align_valid,
    output wire [DW      - 1 : 0] o_Align_dout,
    output wire [1       - 1 : 0] o_Dout_valid,
    output wire [DW      - 1 : 0] o_Dout
);  //gauss_filter_lut
    //**********************************************************************************************
    //parameter and regs defination
    //**********************************************************************************************
    function integer clog2;
        input integer bit_depth;
        begin
            bit_depth = bit_depth - 1;
            for (clog2 = 0; bit_depth > 0; clog2 = clog2 + 1) begin
                bit_depth = bit_depth >> 1;
            end
        end
    endfunction
    localparam WIN_SIZE = K_SIZE * K_SIZE;
    localparam KERNEL_SUM_W = $clog2(SCALER);
    wire               [1                      - 1 : 0]win_cen_vld  ;
    wire               [DW                     - 1 : 0]win_cen_data  ;
    wire               [1                      - 1 : 0]field_vld_array  ;
    wire               [DW*K_SIZE*K_SIZE       - 1 : 0]data_array  ;
    reg                [32*K_SIZE*K_SIZE       - 1 : 0]gauss_result  ;
    wire               [              32       - 1 : 0]gauss_sum   ;
    // wire               [              16       - 1 : 0]kernel_sum  ;
    //**********************************************************************************************
    //function
    //**********************************************************************************************
    win_nxn #(
        .K_SIZE                             (K_SIZE                    ),
        .DW                                 (DW                        ),
        .CW                                 (CW                        ),
        .IMAGE_WIDTH                        (IMAGE_WIDTH               ),
        .IMAGE_HEIGHT                       (IMAGE_HEIGHT              ) 
    ) u_win_nxn (
        .i_Sys_clk                          (i_Sys_clk                 ),
        .i_Rst_n                            (i_Rst_n                   ),
        .i_pixel_vld                        (1'b1                      ),
        .i_field_vld                        (i_Din_valid               ),
        .i_image_data                       (i_Din                     ),
        .o_Cen_valid                        (win_cen_vld               ),
        .o_Cen_data                         (win_cen_data              ),
        .o_field_vld                        (field_vld_array           ),//delay 0 clock
        .o_image_data                       (data_array                ) //delay 0 clock
    );
    generate
        if (K_SIZE == 3 && STD == 1 && SCALER == 1024) begin : g_std1_win3_1024
            always @(posedge i_Sys_clk) begin
                if (~i_Rst_n) begin
                    gauss_result <= 'd0;
                end else begin
                    gauss_result[ 0 * 32 +: 32 ] <= (data_array[0 *DW+:DW ]<< 6) + (data_array[0 *DW+:DW ]<< 3) + (data_array[0 *DW+:DW ]<< 2) + (data_array[0 *DW+:DW ]<< 0 ); 
                    gauss_result[ 1 * 32 +: 32 ] <= (data_array[1 *DW+:DW ]<< 6) + (data_array[1 *DW+:DW ]<< 5) + (data_array[1 *DW+:DW ]<< 4) + (data_array[1 *DW+:DW ]<< 3) + (data_array[1 *DW+:DW ]<< 2) + (data_array[1 *DW+:DW ]<< 1) + (data_array[1 *DW+:DW ]<< 0 ); 
                    gauss_result[ 2 * 32 +: 32 ] <= (data_array[2 *DW+:DW ]<< 6) + (data_array[2 *DW+:DW ]<< 3) + (data_array[2 *DW+:DW ]<< 2) + (data_array[2 *DW+:DW ]<< 0 ); 
                    gauss_result[ 3 * 32 +: 32 ] <= (data_array[3 *DW+:DW ]<< 6) + (data_array[3 *DW+:DW ]<< 5) + (data_array[3 *DW+:DW ]<< 4) + (data_array[3 *DW+:DW ]<< 3) + (data_array[3 *DW+:DW ]<< 2) + (data_array[3 *DW+:DW ]<< 1) + (data_array[3 *DW+:DW ]<< 0 ); 
                    gauss_result[ 4 * 32 +: 32 ] <= (data_array[4 *DW+:DW ]<< 7) + (data_array[4 *DW+:DW ]<< 6) + (data_array[4 *DW+:DW ]<< 4 ); 
                    gauss_result[ 5 * 32 +: 32 ] <= (data_array[5 *DW+:DW ]<< 6) + (data_array[5 *DW+:DW ]<< 5) + (data_array[5 *DW+:DW ]<< 4) + (data_array[5 *DW+:DW ]<< 3) + (data_array[5 *DW+:DW ]<< 2) + (data_array[5 *DW+:DW ]<< 1) + (data_array[5 *DW+:DW ]<< 0 ); 
                    gauss_result[ 6 * 32 +: 32 ] <= (data_array[6 *DW+:DW ]<< 6) + (data_array[6 *DW+:DW ]<< 3) + (data_array[6 *DW+:DW ]<< 2) + (data_array[6 *DW+:DW ]<< 0 ); 
                    gauss_result[ 7 * 32 +: 32 ] <= (data_array[7 *DW+:DW ]<< 6) + (data_array[7 *DW+:DW ]<< 5) + (data_array[7 *DW+:DW ]<< 4) + (data_array[7 *DW+:DW ]<< 3) + (data_array[7 *DW+:DW ]<< 2) + (data_array[7 *DW+:DW ]<< 1) + (data_array[7 *DW+:DW ]<< 0 ); 
                    gauss_result[ 8 * 32 +: 32 ] <= (data_array[8 *DW+:DW ]<< 6) + (data_array[8 *DW+:DW ]<< 3) + (data_array[8 *DW+:DW ]<< 2) + (data_array[8 *DW+:DW ]<< 0 ); 
                end
            end
        end
        if (K_SIZE == 3 && STD == 1 && SCALER == 65536) begin : g_std1_win3_65536
            always @(posedge i_Sys_clk) begin
                if (~i_Rst_n) begin
                    gauss_result <= 'd0;
                end else begin
                    gauss_result[ 0 * 32 +: 32 ] = data_array[ 0 * 32 +: 32 ] <<14 + data_array[ 0 * 32 +: 32 ] <<12 + data_array[ 0 * 32 +: 32 ] <<11 + data_array[ 0 * 32 +: 32 ] <<10 + data_array[ 0 * 32 +: 32 ] <<9 + data_array[ 0 * 32 +: 32 ] <<5 + data_array[ 0 * 32 +: 32 ] <<3 + data_array[ 0 * 32 +: 32 ] <<2 + data_array[ 0 * 32 +: 32 ] <<0 ;
                    gauss_result[ 1 * 32 +: 32 ] = data_array[ 1 * 32 +: 32 ] <<15 + data_array[ 1 * 32 +: 32 ] <<12 + data_array[ 1 * 32 +: 32 ] <<11 + data_array[ 1 * 32 +: 32 ] <<9 + data_array[ 1 * 32 +: 32 ] <<8 + data_array[ 1 * 32 +: 32 ] <<6 + data_array[ 1 * 32 +: 32 ] <<2 + data_array[ 1 * 32 +: 32 ] <<0 ;
                    gauss_result[ 2 * 32 +: 32 ] = data_array[ 2 * 32 +: 32 ] <<14 + data_array[ 2 * 32 +: 32 ] <<12 + data_array[ 2 * 32 +: 32 ] <<11 + data_array[ 2 * 32 +: 32 ] <<10 + data_array[ 2 * 32 +: 32 ] <<9 + data_array[ 2 * 32 +: 32 ] <<5 + data_array[ 2 * 32 +: 32 ] <<3 + data_array[ 2 * 32 +: 32 ] <<2 + data_array[ 2 * 32 +: 32 ] <<0 ;
                    gauss_result[ 3 * 32 +: 32 ] = data_array[ 3 * 32 +: 32 ] <<15 + data_array[ 3 * 32 +: 32 ] <<12 + data_array[ 3 * 32 +: 32 ] <<11 + data_array[ 3 * 32 +: 32 ] <<9 + data_array[ 3 * 32 +: 32 ] <<8 + data_array[ 3 * 32 +: 32 ] <<6 + data_array[ 3 * 32 +: 32 ] <<2 + data_array[ 3 * 32 +: 32 ] <<0 ;
                    gauss_result[ 4 * 32 +: 32 ] = data_array[ 4 * 32 +: 32 ] <<16 ;
                    gauss_result[ 5 * 32 +: 32 ] = data_array[ 5 * 32 +: 32 ] <<15 + data_array[ 5 * 32 +: 32 ] <<12 + data_array[ 5 * 32 +: 32 ] <<11 + data_array[ 5 * 32 +: 32 ] <<9 + data_array[ 5 * 32 +: 32 ] <<8 + data_array[ 5 * 32 +: 32 ] <<6 + data_array[ 5 * 32 +: 32 ] <<2 + data_array[ 5 * 32 +: 32 ] <<0 ;
                    gauss_result[ 6 * 32 +: 32 ] = data_array[ 6 * 32 +: 32 ] <<14 + data_array[ 6 * 32 +: 32 ] <<12 + data_array[ 6 * 32 +: 32 ] <<11 + data_array[ 6 * 32 +: 32 ] <<10 + data_array[ 6 * 32 +: 32 ] <<9 + data_array[ 6 * 32 +: 32 ] <<5 + data_array[ 6 * 32 +: 32 ] <<3 + data_array[ 6 * 32 +: 32 ] <<2 + data_array[ 6 * 32 +: 32 ] <<0 ;
                    gauss_result[ 7 * 32 +: 32 ] = data_array[ 7 * 32 +: 32 ] <<15 + data_array[ 7 * 32 +: 32 ] <<12 + data_array[ 7 * 32 +: 32 ] <<11 + data_array[ 7 * 32 +: 32 ] <<9 + data_array[ 7 * 32 +: 32 ] <<8 + data_array[ 7 * 32 +: 32 ] <<6 + data_array[ 7 * 32 +: 32 ] <<2 + data_array[ 7 * 32 +: 32 ] <<0 ;
                    gauss_result[ 8 * 32 +: 32 ] = data_array[ 8 * 32 +: 32 ] <<14 + data_array[ 8 * 32 +: 32 ] <<12 + data_array[ 8 * 32 +: 32 ] <<11 + data_array[ 8 * 32 +: 32 ] <<10 + data_array[ 8 * 32 +: 32 ] <<9 + data_array[ 8 * 32 +: 32 ] <<5 + data_array[ 8 * 32 +: 32 ] <<3 + data_array[ 8 * 32 +: 32 ] <<2 + data_array[ 8 * 32 +: 32 ] <<0 ;
                end
            end
        end
        if (K_SIZE == 3 && STD == 5 && SCALER == 1024) begin : g_std5_win3_1024
            // assign kernel_sum = 1024;
            always @(posedge i_Sys_clk) begin
                if (~i_Rst_n) begin
                    gauss_result <= 'd0;
                end else begin
                    gauss_result[ 0 * 32 +: 32 ] <= (data_array[0 *DW+:DW ]<< 6) + (data_array[0 *DW+:DW ]<< 5) + (data_array[0 *DW+:DW ]<< 4 );
                    gauss_result[ 1 * 32 +: 32 ] <= (data_array[1 *DW+:DW ]<< 6) + (data_array[1 *DW+:DW ]<< 5) + (data_array[1 *DW+:DW ]<< 4) + (data_array[1 *DW+:DW ]<< 1) + (data_array[1 *DW+:DW ]<< 0 );
                    gauss_result[ 2 * 32 +: 32 ] <= (data_array[2 *DW+:DW ]<< 6) + (data_array[2 *DW+:DW ]<< 5) + (data_array[2 *DW+:DW ]<< 4 );
                    gauss_result[ 3 * 32 +: 32 ] <= (data_array[3 *DW+:DW ]<< 6) + (data_array[3 *DW+:DW ]<< 5) + (data_array[3 *DW+:DW ]<< 4) + (data_array[3 *DW+:DW ]<< 1) + (data_array[3 *DW+:DW ]<< 0 );
                    gauss_result[ 4 * 32 +: 32 ] <= (data_array[4 *DW+:DW ]<< 6) + (data_array[4 *DW+:DW ]<< 5) + (data_array[4 *DW+:DW ]<< 4) + (data_array[4 *DW+:DW ]<< 2 );
                    gauss_result[ 5 * 32 +: 32 ] <= (data_array[5 *DW+:DW ]<< 6) + (data_array[5 *DW+:DW ]<< 5) + (data_array[5 *DW+:DW ]<< 4) + (data_array[5 *DW+:DW ]<< 1) + (data_array[5 *DW+:DW ]<< 0 );
                    gauss_result[ 6 * 32 +: 32 ] <= (data_array[6 *DW+:DW ]<< 6) + (data_array[6 *DW+:DW ]<< 5) + (data_array[6 *DW+:DW ]<< 4 );
                    gauss_result[ 7 * 32 +: 32 ] <= (data_array[7 *DW+:DW ]<< 6) + (data_array[7 *DW+:DW ]<< 5) + (data_array[7 *DW+:DW ]<< 4) + (data_array[7 *DW+:DW ]<< 1) + (data_array[7 *DW+:DW ]<< 0 );
                    gauss_result[ 8 * 32 +: 32 ] <= (data_array[8 *DW+:DW ]<< 6) + (data_array[8 *DW+:DW ]<< 5) + (data_array[8 *DW+:DW ]<< 4 );                
                end
            end
        end
        if (K_SIZE == 3 && STD == 5 && SCALER == 4096) begin : g_std5_win3_4096
            always @(posedge i_Sys_clk) begin
                if (~i_Rst_n) begin
                    gauss_result <= 'd0;
                end else begin
                    gauss_result[ 0 * 32 +: 32 ] <= (data_array[0 *DW+:DW ]<< 8) + (data_array[0 *DW+:DW ]<< 7) + (data_array[0 *DW+:DW ]<< 6) + (data_array[0 *DW+:DW ]<< 0 ); 
                    gauss_result[ 1 * 32 +: 32 ] <= (data_array[1 *DW+:DW ]<< 8) + (data_array[1 *DW+:DW ]<< 7) + (data_array[1 *DW+:DW ]<< 6) + (data_array[1 *DW+:DW ]<< 3) + (data_array[1 *DW+:DW ]<< 1 ); 
                    gauss_result[ 2 * 32 +: 32 ] <= (data_array[2 *DW+:DW ]<< 8) + (data_array[2 *DW+:DW ]<< 7) + (data_array[2 *DW+:DW ]<< 6) + (data_array[2 *DW+:DW ]<< 0 ); 
                    gauss_result[ 3 * 32 +: 32 ] <= (data_array[3 *DW+:DW ]<< 8) + (data_array[3 *DW+:DW ]<< 7) + (data_array[3 *DW+:DW ]<< 6) + (data_array[3 *DW+:DW ]<< 3) + (data_array[3 *DW+:DW ]<< 1 ); 
                    gauss_result[ 4 * 32 +: 32 ] <= (data_array[4 *DW+:DW ]<< 8) + (data_array[4 *DW+:DW ]<< 7) + (data_array[4 *DW+:DW ]<< 6) + (data_array[4 *DW+:DW ]<< 4) + (data_array[4 *DW+:DW ]<< 2 ); 
                    gauss_result[ 5 * 32 +: 32 ] <= (data_array[5 *DW+:DW ]<< 8) + (data_array[5 *DW+:DW ]<< 7) + (data_array[5 *DW+:DW ]<< 6) + (data_array[5 *DW+:DW ]<< 3) + (data_array[5 *DW+:DW ]<< 1 ); 
                    gauss_result[ 6 * 32 +: 32 ] <= (data_array[6 *DW+:DW ]<< 8) + (data_array[6 *DW+:DW ]<< 7) + (data_array[6 *DW+:DW ]<< 6) + (data_array[6 *DW+:DW ]<< 0 ); 
                    gauss_result[ 7 * 32 +: 32 ] <= (data_array[7 *DW+:DW ]<< 8) + (data_array[7 *DW+:DW ]<< 7) + (data_array[7 *DW+:DW ]<< 6) + (data_array[7 *DW+:DW ]<< 3) + (data_array[7 *DW+:DW ]<< 1 ); 
                    gauss_result[ 8 * 32 +: 32 ] <= (data_array[8 *DW+:DW ]<< 8) + (data_array[8 *DW+:DW ]<< 7) + (data_array[8 *DW+:DW ]<< 6) + (data_array[8 *DW+:DW ]<< 0 );                
                end
            end
        end
        if (K_SIZE == 3 && STD == 10 && SCALER == 4096) begin : g_std10_win3_4096
            always @(posedge i_Sys_clk) begin
                if (~i_Rst_n) begin
                    gauss_result <= 'd0;
                end else begin
                    gauss_result[ 0 * 32 +: 32 ] = data_array[ 0 * 32 +: 32 ] <<11 + data_array[ 0 * 32 +: 32 ] <<10 + data_array[ 0 * 32 +: 32 ] <<9 + data_array[ 0 * 32 +: 32 ] <<8 + data_array[ 0 * 32 +: 32 ] <<7 + data_array[ 0 * 32 +: 32 ] <<6 + data_array[ 0 * 32 +: 32 ] <<5 + data_array[ 0 * 32 +: 32 ] <<4 + data_array[ 0 * 32 +: 32 ] <<3 + data_array[ 0 * 32 +: 32 ] <<1 + data_array[ 0 * 32 +: 32 ] <<0 ;
                    gauss_result[ 1 * 32 +: 32 ] = data_array[ 1 * 32 +: 32 ] <<11 + data_array[ 1 * 32 +: 32 ] <<10 + data_array[ 1 * 32 +: 32 ] <<9 + data_array[ 1 * 32 +: 32 ] <<8 + data_array[ 1 * 32 +: 32 ] <<7 + data_array[ 1 * 32 +: 32 ] <<6 + data_array[ 1 * 32 +: 32 ] <<5 + data_array[ 1 * 32 +: 32 ] <<4 + data_array[ 1 * 32 +: 32 ] <<3 + data_array[ 1 * 32 +: 32 ] <<2 + data_array[ 1 * 32 +: 32 ] <<0 ;
                    gauss_result[ 2 * 32 +: 32 ] = data_array[ 2 * 32 +: 32 ] <<11 + data_array[ 2 * 32 +: 32 ] <<10 + data_array[ 2 * 32 +: 32 ] <<9 + data_array[ 2 * 32 +: 32 ] <<8 + data_array[ 2 * 32 +: 32 ] <<7 + data_array[ 2 * 32 +: 32 ] <<6 + data_array[ 2 * 32 +: 32 ] <<5 + data_array[ 2 * 32 +: 32 ] <<4 + data_array[ 2 * 32 +: 32 ] <<3 + data_array[ 2 * 32 +: 32 ] <<1 + data_array[ 2 * 32 +: 32 ] <<0 ;
                    gauss_result[ 3 * 32 +: 32 ] = data_array[ 3 * 32 +: 32 ] <<11 + data_array[ 3 * 32 +: 32 ] <<10 + data_array[ 3 * 32 +: 32 ] <<9 + data_array[ 3 * 32 +: 32 ] <<8 + data_array[ 3 * 32 +: 32 ] <<7 + data_array[ 3 * 32 +: 32 ] <<6 + data_array[ 3 * 32 +: 32 ] <<5 + data_array[ 3 * 32 +: 32 ] <<4 + data_array[ 3 * 32 +: 32 ] <<3 + data_array[ 3 * 32 +: 32 ] <<2 + data_array[ 3 * 32 +: 32 ] <<0 ;
                    gauss_result[ 4 * 32 +: 32 ] = data_array[ 4 * 32 +: 32 ] <<12 ;
                    gauss_result[ 5 * 32 +: 32 ] = data_array[ 5 * 32 +: 32 ] <<11 + data_array[ 5 * 32 +: 32 ] <<10 + data_array[ 5 * 32 +: 32 ] <<9 + data_array[ 5 * 32 +: 32 ] <<8 + data_array[ 5 * 32 +: 32 ] <<7 + data_array[ 5 * 32 +: 32 ] <<6 + data_array[ 5 * 32 +: 32 ] <<5 + data_array[ 5 * 32 +: 32 ] <<4 + data_array[ 5 * 32 +: 32 ] <<3 + data_array[ 5 * 32 +: 32 ] <<2 + data_array[ 5 * 32 +: 32 ] <<0 ;
                    gauss_result[ 6 * 32 +: 32 ] = data_array[ 6 * 32 +: 32 ] <<11 + data_array[ 6 * 32 +: 32 ] <<10 + data_array[ 6 * 32 +: 32 ] <<9 + data_array[ 6 * 32 +: 32 ] <<8 + data_array[ 6 * 32 +: 32 ] <<7 + data_array[ 6 * 32 +: 32 ] <<6 + data_array[ 6 * 32 +: 32 ] <<5 + data_array[ 6 * 32 +: 32 ] <<4 + data_array[ 6 * 32 +: 32 ] <<3 + data_array[ 6 * 32 +: 32 ] <<1 + data_array[ 6 * 32 +: 32 ] <<0 ;
                    gauss_result[ 7 * 32 +: 32 ] = data_array[ 7 * 32 +: 32 ] <<11 + data_array[ 7 * 32 +: 32 ] <<10 + data_array[ 7 * 32 +: 32 ] <<9 + data_array[ 7 * 32 +: 32 ] <<8 + data_array[ 7 * 32 +: 32 ] <<7 + data_array[ 7 * 32 +: 32 ] <<6 + data_array[ 7 * 32 +: 32 ] <<5 + data_array[ 7 * 32 +: 32 ] <<4 + data_array[ 7 * 32 +: 32 ] <<3 + data_array[ 7 * 32 +: 32 ] <<2 + data_array[ 7 * 32 +: 32 ] <<0 ;
                    gauss_result[ 8 * 32 +: 32 ] = data_array[ 8 * 32 +: 32 ] <<11 + data_array[ 8 * 32 +: 32 ] <<10 + data_array[ 8 * 32 +: 32 ] <<9 + data_array[ 8 * 32 +: 32 ] <<8 + data_array[ 8 * 32 +: 32 ] <<7 + data_array[ 8 * 32 +: 32 ] <<6 + data_array[ 8 * 32 +: 32 ] <<5 + data_array[ 8 * 32 +: 32 ] <<4 + data_array[ 8 * 32 +: 32 ] <<3 + data_array[ 8 * 32 +: 32 ] <<1 + data_array[ 8 * 32 +: 32 ] <<0 ;
                end
            end
        end
        if (K_SIZE == 3 && STD == 30 && SCALER == 4096) begin : g_std10_win30_4096
            always @(posedge i_Sys_clk) begin
                if (~i_Rst_n) begin
                    gauss_result <= 'd0;
                end else begin
                    gauss_result[0*32+:32] <= (data_array[0*DW+:DW] << 8) + (data_array[0*DW+:DW] << 7) + (data_array[0*DW+:DW] << 6) + (data_array[0*DW+:DW] << 2) + (data_array[0*DW+:DW] << 1);
                    gauss_result[1*32+:32] <= (data_array[1*DW+:DW] << 8) + (data_array[1*DW+:DW] << 7) + (data_array[1*DW+:DW] << 6) + (data_array[1*DW+:DW] << 3);
                    gauss_result[2*32+:32] <= (data_array[2*DW+:DW] << 8) + (data_array[2*DW+:DW] << 7) + (data_array[2*DW+:DW] << 6) + (data_array[2*DW+:DW] << 2) + (data_array[2*DW+:DW] << 1);
                    gauss_result[3*32+:32] <= (data_array[3*DW+:DW] << 8) + (data_array[3*DW+:DW] << 7) + (data_array[3*DW+:DW] << 6) + (data_array[3*DW+:DW] << 3);
                    gauss_result[4*32+:32] <= (data_array[4*DW+:DW] << 8) + (data_array[4*DW+:DW] << 7) + (data_array[4*DW+:DW] << 6) + (data_array[4*DW+:DW] << 3) + (data_array[4*DW+:DW] << 1);
                    gauss_result[5*32+:32] <= (data_array[5*DW+:DW] << 8) + (data_array[5*DW+:DW] << 7) + (data_array[5*DW+:DW] << 6) + (data_array[5*DW+:DW] << 3);
                    gauss_result[6*32+:32] <= (data_array[6*DW+:DW] << 8) + (data_array[6*DW+:DW] << 7) + (data_array[6*DW+:DW] << 6) + (data_array[6*DW+:DW] << 2) + (data_array[6*DW+:DW] << 1);
                    gauss_result[7*32+:32] <= (data_array[7*DW+:DW] << 8) + (data_array[7*DW+:DW] << 7) + (data_array[7*DW+:DW] << 6) + (data_array[7*DW+:DW] << 3);
                    gauss_result[8*32+:32] <= (data_array[8*DW+:DW] << 8) + (data_array[8*DW+:DW] << 7) + (data_array[8*DW+:DW] << 6) + (data_array[8*DW+:DW] << 2) + (data_array[8*DW+:DW] << 1);
                end
            end
        end
        if (K_SIZE == 5 && STD == 10 && SCALER == 4096) begin : g_std10_win5_4096
            always @(posedge i_Sys_clk) begin
                if (~i_Rst_n) begin
                    gauss_result <= 'd0;
                end else begin
                    gauss_result[0*32+:32]  = (data_array[0*DW+:DW] << 7) + (data_array[0*DW+:DW] << 5) + (data_array[0*DW+:DW] << 0);
                    gauss_result[1*32+:32]  = (data_array[1*DW+:DW] << 7) + (data_array[1*DW+:DW] << 5) + (data_array[1*DW+:DW] << 1) + (data_array[1*DW+:DW] << 0);
                    gauss_result[2*32+:32]  = (data_array[2*DW+:DW] << 7) + (data_array[2*DW+:DW] << 5) + (data_array[2*DW+:DW] << 2);
                    gauss_result[3*32+:32]  = (data_array[3*DW+:DW] << 7) + (data_array[3*DW+:DW] << 5) + (data_array[3*DW+:DW] << 1) + (data_array[3*DW+:DW] << 0);
                    gauss_result[4*32+:32]  = (data_array[4*DW+:DW] << 7) + (data_array[4*DW+:DW] << 5) + (data_array[4*DW+:DW] << 0);
                    gauss_result[5*32+:32]  = (data_array[5*DW+:DW] << 7) + (data_array[5*DW+:DW] << 5) + (data_array[5*DW+:DW] << 1) + (data_array[5*DW+:DW] << 0);
                    gauss_result[6*32+:32]  = (data_array[6*DW+:DW] << 7) + (data_array[6*DW+:DW] << 5) + (data_array[6*DW+:DW] << 2) + (data_array[6*DW+:DW] << 0);
                    gauss_result[7*32+:32]  = (data_array[7*DW+:DW] << 7) + (data_array[7*DW+:DW] << 5) + (data_array[7*DW+:DW] << 2) + (data_array[7*DW+:DW] << 1);
                    gauss_result[8*32+:32]  = (data_array[8*DW+:DW] << 7) + (data_array[8*DW+:DW] << 5) + (data_array[8*DW+:DW] << 2) + (data_array[8*DW+:DW] << 0);
                    gauss_result[9*32+:32]  = (data_array[9*DW+:DW] << 7) + (data_array[9*DW+:DW] << 5) + (data_array[9*DW+:DW] << 1) + (data_array[9*DW+:DW] << 0);
                    gauss_result[10*32+:32] = (data_array[10*DW+:DW] << 7) + (data_array[10*DW+:DW] << 5) + (data_array[10*DW+:DW] << 2);
                    gauss_result[11*32+:32] = (data_array[11*DW+:DW] << 7) + (data_array[11*DW+:DW] << 5) + (data_array[11*DW+:DW] << 2) + (data_array[11*DW+:DW] << 1);
                    gauss_result[12*32+:32] = (data_array[12*DW+:DW] << 7) + (data_array[12*DW+:DW] << 5) + (data_array[12*DW+:DW] << 2) + (data_array[12*DW+:DW] << 1) + (data_array[12*DW+:DW] << 0);
                    gauss_result[13*32+:32] = (data_array[13*DW+:DW] << 7) + (data_array[13*DW+:DW] << 5) + (data_array[13*DW+:DW] << 2) + (data_array[13*DW+:DW] << 1);
                    gauss_result[14*32+:32] = (data_array[14*DW+:DW] << 7) + (data_array[14*DW+:DW] << 5) + (data_array[14*DW+:DW] << 2);
                    gauss_result[15*32+:32] = (data_array[15*DW+:DW] << 7) + (data_array[15*DW+:DW] << 5) + (data_array[15*DW+:DW] << 1) + (data_array[15*DW+:DW] << 0);
                    gauss_result[16*32+:32] = (data_array[16*DW+:DW] << 7) + (data_array[16*DW+:DW] << 5) + (data_array[16*DW+:DW] << 2) + (data_array[16*DW+:DW] << 0);
                    gauss_result[17*32+:32] = (data_array[17*DW+:DW] << 7) + (data_array[17*DW+:DW] << 5) + (data_array[17*DW+:DW] << 2) + (data_array[17*DW+:DW] << 1);
                    gauss_result[18*32+:32] = (data_array[18*DW+:DW] << 7) + (data_array[18*DW+:DW] << 5) + (data_array[18*DW+:DW] << 2) + (data_array[18*DW+:DW] << 0);
                    gauss_result[19*32+:32] = (data_array[19*DW+:DW] << 7) + (data_array[19*DW+:DW] << 5) + (data_array[19*DW+:DW] << 1) + (data_array[19*DW+:DW] << 0);
                    gauss_result[20*32+:32] = (data_array[20*DW+:DW] << 7) + (data_array[20*DW+:DW] << 5) + (data_array[20*DW+:DW] << 0);
                    gauss_result[21*32+:32] = (data_array[21*DW+:DW] << 7) + (data_array[21*DW+:DW] << 5) + (data_array[21*DW+:DW] << 1) + (data_array[21*DW+:DW] << 0);
                    gauss_result[22*32+:32] = (data_array[22*DW+:DW] << 7) + (data_array[22*DW+:DW] << 5) + (data_array[22*DW+:DW] << 2);
                    gauss_result[23*32+:32] = (data_array[23*DW+:DW] << 7) + (data_array[23*DW+:DW] << 5) + (data_array[23*DW+:DW] << 1) + (data_array[23*DW+:DW] << 0);
                    gauss_result[24*32+:32] = (data_array[24*DW+:DW] << 7) + (data_array[24*DW+:DW] << 5) + (data_array[24*DW+:DW] << 0);
                end
            end
        end
    endgenerate
    parallel_adder #(
        .SIZE                               (WIN_SIZE                  ),
        .WIDTH                              (32                        ),
        .WIDTHR                             (32                        ),
        .REPRESENTATION                     ("UNSIGNED"                ) 
    ) parallel_adder_inst (
        .i_clk                              (i_Sys_clk                 ),
        .i_rst_n                            (i_Rst_n                   ),
        .i_clk_en                           (1'b1                      ),
        .i_data                             (gauss_result              ),//delay 1 clock
        .o_result                           (gauss_sum                 ) //delay 2 clock
    );
    data_avl_delay #(
        .DW                                 (1                         ),
        .DELAY_NUM                          (2                         ) 
    ) data_avl_delay_inst (
        .i_clk                              (i_Sys_clk                 ),
        .i_rst_n                            (i_Rst_n                   ),
        .i_pixel_vld                        (1'b1                      ),
        .i_data                             (field_vld_array           ),
        .o_data                             (o_Dout_valid              ) 
    );

    assign o_Dout = gauss_sum >>> KERNEL_SUM_W;
    //**********************************************************************************************
    assign o_Align_valid = o_Dout_valid;
    // assign o_Align_dout = win_cen_data;
    data_avl_delay #(
        .DW                                 (DW                        ),
        .DELAY_NUM                          (2                         ) 
    ) align_delay_inst (
        .i_clk                              (i_Sys_clk                 ),
        .i_rst_n                            (i_Rst_n                   ),
        .i_pixel_vld                        (1'b1                      ),
        .i_data                             (win_cen_data              ),
        .o_data                             (o_Align_dout              ) 
    );
    //**********************************************************************************************
endmodule
