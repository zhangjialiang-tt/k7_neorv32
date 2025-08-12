// ------------------------------------------------------------------------------------------------
// Company                      : Wuhan Guide Sensmart Tech Co., Ltd
// Create Date                  : 20240902
// Author Name                  : zhangjl
// Module Name                  : divider_wrapper
// Project Name                 : zp44b
// Tarject Device               : Titanium-ti180
// Tool Versions                : Efinix Efinity-2023.2.307.1.14
// Description                  : 
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
module divider_wrapper #(
    parameter LPM_REPRESENTATION = "UNSIGNED",
    parameter LPM_WIDTHD = 16,
    parameter LPM_WIDTHN = 16
) (
    //global input interface
    input  wire        [1          - 1 : 0]clock      ,
    input  wire        [1          - 1 : 0]clken      ,
    input  wire        [1          - 1 : 0]din_en     ,
    input  wire        [LPM_WIDTHD - 1 : 0]denom      ,//分母
    input  wire        [LPM_WIDTHN - 1 : 0]numer      ,//分子
    output reg         [1          - 1 : 0]quotient_en,
    output reg         [LPM_WIDTHN - 1 : 0]quotient   
);  //divider_wrapper
    //**********************************************************************************************
    //parameter and regs defination
    //**********************************************************************************************

    wire               [1          - 1 : 0]denom_is_positive  ;
    wire               [1          - 1 : 0]numer_is_positive  ;
    wire               [1          - 1 : 0]result_is_positive ;
    wire               [LPM_WIDTHN - 1 : 0]un_denom           ;
    wire               [LPM_WIDTHN - 1 : 0]un_numer           ;
    wire               [LPM_WIDTHN - 1 : 0]un_quotient        ;
    reg                [1          - 1 : 0]div_done_d1        ;
    reg                [1          - 1 : 0]div_done_d2        ;
    wire               [1          - 1 : 0]vld_pos            ;
    generate
    if (LPM_REPRESENTATION == "UNSIGNED") begin : g_is_unsigned
        assign denom_is_positive = 1'b1;
        assign numer_is_positive = 1'b1;
        assign result_is_positive = 1'b1;
        assign un_denom = {{{LPM_WIDTHN-LPM_WIDTHD}{1'b0}},denom};
        assign un_numer = numer;
        // assign quotient = un_quotient;
        always @ ( posedge clock ) begin
            if(vld_pos)begin
                quotient_en <= 1'b1;
                quotient <= un_quotient;
            end else begin
                quotient_en <= 1'b0;
                quotient <= quotient;
            end
        end
    end else if (LPM_REPRESENTATION == "SIGNED") begin : g_is_signed
        assign denom_is_positive = $signed(denom)>$signed(0);//din_en==1'b1 && $signed(denom)>$signed(0) ? 1'b1 : 1'b0;
        assign numer_is_positive = $signed(numer)>$signed(0);//din_en==1'b1 && $signed(numer)>$signed(0) ? 1'b1 : 1'b0;
        assign un_denom = denom_is_positive ? denom : ~denom + 1'b1;
        assign un_numer = numer_is_positive ? numer : ~numer + 1'b1;

        assign result_is_positive = (denom_is_positive==1'b1&&numer_is_positive==1'b1) || (denom_is_positive==1'b0&&numer_is_positive==1'b0);
        always @ ( posedge clock ) begin
            if(vld_pos)begin
                quotient_en <= 1'b1;
                quotient <= result_is_positive ? un_quotient : ~un_quotient + 1'b1;
            end else begin
                quotient_en <= 1'b0;
                quotient <= quotient;
            end
        end
    end
endgenerate

    divider_guideir #(
        .WIDTH                              (LPM_WIDTHN                ),
        .CACHING                            (0                         ),
        .INIT_VLD                           (1                         ) 
    ) div_gray_mean_inst (
        .clk                                (clock                     ),
        .rst                                (1'b0                      ),
        .start                              (din_en                    ),
        .dividend                           (un_numer                  ),
        .divisor                            (un_denom                  ),
        .quotient                           (un_quotient               ),
        .remainder                          (                          ),
        .zeroErr                            (                          ),
        .valid                              (div_done                  ) 
    );
    always @(posedge clock) begin
        div_done_d1 <= div_done;
        div_done_d2 <= div_done_d1;
    end
    assign vld_pos = ~div_done_d2 & div_done_d1;
endmodule
