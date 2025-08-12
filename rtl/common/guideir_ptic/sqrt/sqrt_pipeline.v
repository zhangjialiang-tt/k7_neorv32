// ------------------------------------------------------------------------------------------------
// Company                      : Wuhan Guide Sensmart Tech Co., Ltd
// Create Date                  : 20210329
// Author Name                  : ZJL
// Module Name                  :
// Project Name                 :
// Tarject Device               : Intel-Altera-EP5CEFA5
// Tool Versions                : Quartus-15.1
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
module sqrt_pipeline#(
    parameter DW = 8   //输入数据位宽
)(
//global input interface
    input         wire        [1-1:0]        i_Sys_clk      ,
    input         wire        [1-1:0]        i_Rst_n        ,
    input         wire        [1-1:0]        i_Din_valid    ,
    input         wire        [DW-1:0]       i_Din          
);//sqrt_pipeline
//**********************************************************************************************
localparam INTERATION = 16;
//计算log2
function integer clogb2;
    input integer depth;
        for (clogb2=0; depth>0; clogb2=clogb2+1)
            depth = depth >> 1;
endfunction
//**********************************************************************************************
reg           [ DW  - 1 : 0 ]          din_reg[0:15]               ;
reg           [ DW  - 1 : 0 ]          root[0:15]               ;
reg           [ DW  - 1 : 0 ]          remainder[0:15]          ;
//**********************************************************************************************
genvar i;
generate
    begin : sqrt_pipe_gen
        for (i = 0;i <= INTERATION-1;i = i +1)begin
            always @ ( posedge i_Sys_clk ) begin
                if(~i_Rst_n) begin
                    din_reg[i] <= 'd0;
                end
                else begin
                    din_reg[i] <= i_Din;
                end
            end
        end
    end
endgenerate
//**********************************************************************************************
endmodule