// ------------------------------------------------------------------------------------------------
// Company                      : Wuhan Guide Sensmart Tech Co., Ltd
// Create Date                  : 20231110
// Author Name                  : zhangjl
// Module Name                  :
// Project Name                 :
// Tarject Device               : Titanium-ti180
// Tool Versions                : Efinity-2022.2.322.5.7
// Description                  : ex:A/9 = A*(65536/9)/65536=(7282*A)>>16
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
module fix_div #(
    parameter LPM_REPRESENTATION = "UNSIGNED",
    parameter DW = 16,
    // parameter N = 32,
    parameter DENOM_IS_BIG = "FALSE",
    parameter DENOM = 9
) (
    //global input interface
    input  wire [1       - 1 : 0] i_Sys_clk,
    input  wire [1       - 1 : 0] i_Rst_n,
    input  wire [DW      - 1 : 0] i_Din,
    output reg  [DW      - 1 : 0] o_Dout
);  //div_9
    //**********************************************************************************************
    //parameter and regs defination
    //**********************************************************************************************
    // parameter N = DW;
    localparam    integer   DENOM_NO_BIG = (2**16)/DENOM;
    localparam    integer   DENOM_BIG = 32'd2147483648/DENOM;//(2**31)/DENOM;
    wire [16     - 1 : 0]    no_datab       ;
    wire [DW+16  - 1 : 0]    no_result_c    ;
    wire [32     - 1 : 0]    big_datab       ;
    wire [DW+32  - 1 : 0]    big_result_c    ;
    generate
        if (DENOM_IS_BIG == "FALSE") begin : g_no_big
            // wire [16     - 1 : 0]    datab       ;
            // wire [DW+16  - 1 : 0]    result_c    ;
            assign no_datab = DENOM_NO_BIG[16-1:0];
            multi_mxn #(
                .LPM_PIPELINE                       (3                         ),
                .LPM_WIDTHA                         (DW                        ),
                .LPM_WIDTHB                         (16                        ),
                .LPM_REPRESENTATION                 (LPM_REPRESENTATION        ) 
            ) shared_mult (
                .clken                              (1'b1                      ),
                .clock                              (i_Sys_clk                 ),
                .dataa                              (i_Din                     ),
                .datab                              (no_datab                  ),
                .result                             (no_result_c[DW+16-1:0]    ) 
            );
            always @ ( posedge i_Sys_clk ) begin
                if(~i_Rst_n)    o_Dout <= 'd0;
                else            o_Dout <= ($signed(no_result_c)>=$signed(0)) ? no_result_c>>>16 : (no_result_c>>>16) + $signed(1);
            end
        end else if (DENOM_IS_BIG == "TRUE") begin : g_big
            assign big_datab = DENOM_BIG[32-1:0];
            multi_mxn #(
                .LPM_PIPELINE                       (3                         ),
                .LPM_WIDTHA                         (DW                        ),
                .LPM_WIDTHB                         (32                        ),
                .LPM_REPRESENTATION                 (LPM_REPRESENTATION        ) 
            ) shared_mult (
                .clken                              (1'b1                      ),
                .clock                              (i_Sys_clk                 ),
                .dataa                              (i_Din                     ),
                .datab                              (big_datab                 ),
                .result                             (big_result_c              ) 
            );
            always @ ( posedge i_Sys_clk ) begin
                if(~i_Rst_n)    o_Dout <= 'd0;
                else            o_Dout <= ($signed(big_result_c)>=$signed(0)) ? big_result_c>>>31 : (big_result_c>>>31) + $signed(1);
            end
        end
    endgenerate

    
endmodule
