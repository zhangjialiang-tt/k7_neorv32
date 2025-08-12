// ------------------------------------------------------------------------------------------------
// Company                      : Wuhan Guide Sensmart Tech Co., Ltd
// Create Date                  : 20231110
// Author Name                  : zhangjl
// Module Name                  :
// Project Name                 :
// Tarject Device               : Titanium-ti180
// Tool Versions                : Efinity-2022.2.322.5.7
// Description                  : 该文件是
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
module save_image #(  //保存图像数据
    parameter PATTERN = "decimalism",  //"decimalism","hexadecimal","binary"
    parameter DW = 16,
    parameter FILENAME = "1.txt"
) (
    //global input interface
    input wire [1       - 1 : 0] i_Sys_clk,
    input wire [1       - 1 : 0] i_Din_valid,
    input wire [DW      - 1 : 0] i_Din
);  //save_image
    integer file_df;
    initial begin
        file_df = $fopen(FILENAME);
        if (!file_df) begin
            $display("could not open file!");
            $finish;
        end
    end
    generate
        if (PATTERN == "decimalism") begin : g_decimalism
            always @(posedge i_Sys_clk) begin
                if (i_Din_valid)  //一帧图像数据
                    $fdisplay(file_df, "%d", i_Din);  //以十进制保存
            end
        end else if (PATTERN == "hexadecimal") begin : g_hexadecimal
            always @(posedge i_Sys_clk) begin
                if (i_Din_valid)  //一帧图像数据
                    $fdisplay(file_df, "%h", i_Din);  //以十六进制保存
            end
        end else if (PATTERN == "binary") begin : g_binary
            always @(posedge i_Sys_clk) begin
                if (i_Din_valid)  //一帧图像数据
                    $fdisplay(file_df, "%b", i_Din);  //以二进制保存
            end
        end
    endgenerate
endmodule
