// ------------------------------------------------------------------------------------------------
// Company                      : Wuhan Guide Sensmart Tech Co., Ltd
// Create Date                  : 20230719
// Author Name                  : ZJL
// Module Name                  :
// Project Name                 :
// Tarject Device               : Titanium-ti60f100
// Tool Versions                : Efinity-2022.2.322.5.7
// Description                  :
//
//
//
// Revision                     : 1.00.0000
// Modified by                  :
// Modified Data                :
// Additional Comments          :
// Standard Syndoc              :
// ------------------------------------------------------------------------------------------------
module win_nxn #(
    parameter K_SIZE = 3,
    parameter DW = 8,
    parameter CW = 10,
    parameter IMAGE_WIDTH = 10'd640,
    parameter IMAGE_HEIGHT = 10'd480,
    parameter WIN_ROW = K_SIZE,
    parameter WIN_COL = K_SIZE
) (
    //global input interface
    input  wire [1                   - 1 : 0] i_Sys_clk,     //50MHZ
    input  wire [1                   - 1 : 0] i_Rst_n,
    input  wire [1                   - 1 : 0] i_pixel_vld,
    input  wire [1                   - 1 : 0] i_field_vld,
    input  wire [DW                  - 1 : 0] i_image_data,
    output wire [1                   - 1 : 0] o_field_vld,
    output wire [DW*WIN_ROW*WIN_COL  - 1 : 0] o_image_data,
    output wire [1                   - 1 : 0] o_Cen_valid,
    output wire [DW                  - 1 : 0] o_Cen_data     //中心点像素
);  //dpc_dynamic_top
    //************************parameter defination***********************
    //************************wire signal defination***********************
    wire [1                      - 1 : 0] field_vld_row;
    wire [DW*WIN_ROW             - 1 : 0] data_row;
    wire [1                      - 1 : 0] field_vld_array;
    wire [DW*WIN_ROW*WIN_COL     - 1 : 0] data_array;

    //**********************************************************************************************

    // ===========generate array 3x3===========--
    // -----------generate line 3----------------
    line_1toN #(
        .N            (WIN_ROW),     //=> WIN_ROW,
        .DW           (DW),          //=> DW,
        .CW           (CW),          //=> CW,
        .WRITE_BACK_EN("FALSE"),     //=> "FALSE",
        .IMAGE_WIDTH  (IMAGE_WIDTH)  //=> IMAGE_WIDTH
    ) u_line_1toN (
        .i_clk         (i_Sys_clk),      // => i_clk,
        .i_rst_n       (i_Rst_n),        // => i_rst_n,
        .i_pixel_vld   (i_pixel_vld),    // => i_pixel_vld,
        .i_image_width (IMAGE_WIDTH),    // => i_image_width,
        .i_image_height(IMAGE_HEIGHT),   // => i_image_height,
        .i_field_vld   (i_field_vld),    // => i_field_vld,
        .i_image_data  (i_image_data),   // => i_image_data,
        .i_waddr       ({CW{1'd0}}),
        .i_wren        (1'b0),
        .i_wdata       ({DW{1'd0}}),
        .o_field_vld   (field_vld_row),  //=> field_vld_row,
        .o_image_data  (data_row)        //=> data_row
    );
    //**********************************************************************************************
    genvar i;
    generate
        begin : g_data_array_gen
            for (i = 0; i <= WIN_ROW - 1; i = i + 1) begin : g_padding_col
                if (i == 0) begin : g_data_first_row_gen
                    column1toN #(
                        .N (WIN_COL),
                        .CW(CW),
                        .DW(DW)
                    ) u1_column1toN (
                        .i_clk         (i_Sys_clk),
                        .i_rst_n       (i_Rst_n),
                        .i_pixel_vld   (i_pixel_vld),
                        .i_image_height(IMAGE_HEIGHT),
                        .i_image_width (IMAGE_WIDTH),
                        .i_field_vld   (field_vld_row),
                        .i_image_data  (data_row[DW*1-1:0]),
                        .o_field_vld   (field_vld_array),
                        .o_image_data  (data_array[DW*WIN_COL-1:0])
                    );
                end

                if (i > 0) begin : g_data_other_row_gen
                    column1toN #(
                        .N (WIN_COL),
                        .CW(CW),
                        .DW(DW)
                    ) u2_column1toN (
                        .i_clk         (i_Sys_clk),
                        .i_rst_n       (i_Rst_n),
                        .i_pixel_vld   (i_pixel_vld),
                        .i_image_height(IMAGE_HEIGHT),
                        .i_image_width (IMAGE_WIDTH),
                        .i_field_vld   (field_vld_row),
                        .i_image_data  (data_row[DW*(i+1)-1 : DW*i]),
                        .o_field_vld   (),
                        .o_image_data  (data_array[DW*WIN_COL*(i+1)-1 : DW*WIN_COL*i])
                    );
                end
            end
        end
    endgenerate
    //**********************************************************************************************
    assign o_field_vld  = field_vld_array;
    assign o_image_data = field_vld_array ? data_array : 'd0;
    assign o_Cen_valid  = field_vld_array;
    assign o_Cen_data   = field_vld_array ? data_array[(WIN_ROW*WIN_COL-1)*DW/2+:DW] : 'd0;  //
    //**********************************************************************************************
endmodule
