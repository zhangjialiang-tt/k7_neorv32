// ------------------------------------------------------------------------------------------------
// Company                      : Wuhan Guide Sensmart Tech Co., Ltd
// Create Date                  : 20240723
// Author Name                  : zhangjl
// Module Name                  : data_avl_delay
// Project Name                 : zu16a
// Tarject Device               : Titanium-ti180
// Tool Versions                : Efinix Efinity-2023.2.307.1.14
// Description                  : 该文件设计思路是
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
module data_avl_delay #(
    parameter DW = 16,
    parameter DELAY_NUM = 12
) (
    //global input interface
    input  wire [1       - 1 : 0] i_clk,
    input  wire [1       - 1 : 0] i_rst_n,
    input  wire [1       - 1 : 0] i_pixel_vld,
    input  wire [DW      - 1 : 0] i_data,
    output wire [DW      - 1 : 0] o_data
);  //data_avl_delay
    //**********************************************************************************************
    //parameter and regs defination
    //**********************************************************************************************
    (* syn_srlstyle = "srl" *) reg [DW*DELAY_NUM-1:0] data;

    genvar i;
    generate
        begin
            if (DELAY_NUM == 0) begin
                assign o_data = i_data;
            end else if (DELAY_NUM == 1) begin
                always @(posedge i_clk) begin
                    if (~i_rst_n) data <= 0;
                    else data <= i_data;
                end
                assign o_data = data;
            end else begin
                for (i = 0; i <= DW - 1; i = i + 1) begin : g_padding_col
                    always @(posedge i_clk) begin
                        if (~i_rst_n) data[(i*DELAY_NUM)+:DELAY_NUM] <= 0;
                        else data[(i*DELAY_NUM)+:DELAY_NUM] <= {data[((i+1)*DELAY_NUM-2):(i*DELAY_NUM)], i_data[i]};
                    end
                    assign o_data[i] = data[(i+1)*DELAY_NUM-1];
                end
            end
        end
    endgenerate
endmodule
