//----------------------------------------------------------------------------------------------------
// https://www.elitestek.com
// 版权所有：易灵思（深圳）科技有限公司
//---------------------------------------------------------------------------------------------------
// Module      : parallel_ppl_mult
// Author      : Bruce Chen
// Contact     : bruce.chen@elitestek.com
// Version     : V1.20
// Date        : 2021/01/10
// History     : 1. 2021/01/08 V1.00, Create initial version,only support unsigned multiplication
//             : 2. 2021/01/10 V1.11, Support signed multiplication
//             : 3. 2021/01/12 V1.20, Opitimazed signed multiplication performace for Efinix Trion
//             : 4. ......
//---------------------------------------------------------------------------------------------------
// Decription  : Pipeline parallel multiplier for Efinix TRION
//---------------------------------------------------------------------------------------------------

`timescale 100ps/10ps

module parallel_ppl_mult
#(
parameter MUL1_WIDTH = 36           ,//Multiplier1 width
parameter MUL2_WIDTH = 26           ,//multiplier2 width
parameter PPL_LEVEL  = 5            ,//pipeline levels
parameter SINED      = "SIGNED"        ,//NO = unsigned : YES = signed
parameter MUL_IREG   = "YES"        ,//multiplier block input register default="YES", It only works when PPL_LEVEL>=3
//internal parameters
parameter PROD_WIDTH = MUL1_WIDTH+MUL2_WIDTH
)
(
input                        clk    ,
input                        rst_n  ,
input     [MUL1_WIDTH-1:0]   mul1   ,
input     [MUL2_WIDTH-1:0]   mul2   ,
output    [PROD_WIDTH-1:0]   prod
);

localparam PROD_OREG  = PPL_LEVEL>=1 ? 1:0;//output register
localparam MUL_OREG   = PPL_LEVEL>=2 ? 1:0;//multiplier block output register
localparam iMUL_IREG  = PPL_LEVEL>=3 ? ((MUL_IREG=="YES")?1:0):0;//multiplier block input register

localparam uMUL_WIDTH = 18; // signed mult block input witdh of Efinix Trion

localparam cMUL_WIDTH = uMUL_WIDTH-1;//Caculate number of block mult input witdh
localparam cMUL1_WIDTH= SINED=="SIGNED" ? MUL1_WIDTH-1 : MUL1_WIDTH; //Caculate total number of mult input witdh
localparam cMUL2_WIDTH= SINED=="SIGNED" ? MUL2_WIDTH-1 : MUL2_WIDTH; //Caculate total number of mult input witdh

localparam uMUL_NUM1  = (cMUL1_WIDTH/cMUL_WIDTH)?
                        ((cMUL1_WIDTH%cMUL_WIDTH)?
                        (cMUL1_WIDTH/cMUL_WIDTH)+1:
                        (cMUL1_WIDTH/cMUL_WIDTH)):
                        1;

localparam uMUL_NUM2  = (cMUL2_WIDTH/cMUL_WIDTH)?
                        ((cMUL2_WIDTH%cMUL_WIDTH)?
                        (cMUL2_WIDTH/cMUL_WIDTH)+1:
                        (cMUL2_WIDTH/cMUL_WIDTH)):
                        1;
                        
localparam uMUL_NUM    = uMUL_NUM1*uMUL_NUM2; // Multiplier block number
localparam uPROD_WIDTH = uMUL_WIDTH*2;

localparam iMUL_WIDTH1 = SINED=="SIGNED" ? MUL1_WIDTH: MUL1_WIDTH+1;
localparam iMUL_WIDTH2 = SINED=="SIGNED" ? MUL2_WIDTH: MUL2_WIDTH+1;

//=========================================================================================================================
//                                                    Main Code
//=========================================================================================================================
//---------------------------------input register generate-------------------------------
reg [iMUL_WIDTH1-1:0] signed_mul1;
reg [iMUL_WIDTH2-1:0] signed_mul2;

wire [uMUL_WIDTH-1:0] i_mul1 [uMUL_NUM1-1:0];
wire [uMUL_WIDTH-1:0] i_mul2 [uMUL_NUM2-1:0];

generate
     if(iMUL_IREG==1)begin
          if(SINED=="SIGNED") begin
               always@(posedge clk or negedge rst_n ) begin
                    if (!rst_n) begin
                         signed_mul1 <= 'd0;
                         signed_mul2 <= 'd0;
                    end
                    else begin
                         signed_mul1 <= mul1;
                         signed_mul2 <= mul2;
                    end
               end
          end
          else begin
               always@(posedge clk or negedge rst_n ) begin
                    if (!rst_n) begin
                         signed_mul1 <= 'd0;
                         signed_mul2 <= 'd0;
                    end
                    else begin
                         signed_mul1 <= {1'b0,mul1};
                         signed_mul2 <= {1'b0,mul2};
                    end
               end
          end    
     end
     else begin
          if(SINED=="SIGNED") begin
               always@( * ) begin
                    signed_mul1 <= mul1;
                    signed_mul2 <= mul2;
               end
          end
          else begin
               always@( * ) begin
                    signed_mul1 <= {1'b0,mul1};
                    signed_mul2 <= {1'b0,mul2};
               end
          end
     end
endgenerate

generate
genvar i,j;

     for(i=0;i<=uMUL_NUM1-2;i=i+1)begin:IN_ALIGN1
          assign i_mul1[i] = {1'b0,signed_mul1[cMUL_WIDTH*(i+1)-1 -: cMUL_WIDTH]};
     end
     assign i_mul1[uMUL_NUM1-1]=
          {{uMUL_WIDTH*uMUL_NUM1-(iMUL_WIDTH1+uMUL_NUM1-1){signed_mul1[iMUL_WIDTH1-1]}},
                                 signed_mul1[iMUL_WIDTH1-1:cMUL_WIDTH*(uMUL_NUM1-1)]};
     
     for(j=0;j<=uMUL_NUM2-2;j=j+1)begin:IN_ALIGN2
          assign i_mul2[j] = {1'b0,signed_mul2[cMUL_WIDTH*(j+1)-1 -: cMUL_WIDTH]};
     end
     assign i_mul2[uMUL_NUM2-1]=
          {{uMUL_WIDTH*uMUL_NUM2-(iMUL_WIDTH2+uMUL_NUM2-1){signed_mul2[iMUL_WIDTH2-1]}},
                                 signed_mul2[iMUL_WIDTH2-1:cMUL_WIDTH*(uMUL_NUM2-1)]};
     
endgenerate

//-------------------------------multiplier unit generate------------------------------------------
localparam ePROD_WIDTH = cMUL_WIDTH*uMUL_NUM1+cMUL_WIDTH*uMUL_NUM2+2; // expand product width
wire [ePROD_WIDTH-1:0] i_prod_expand [uMUL_NUM-1:0];
reg [uPROD_WIDTH-1:0] i_prod [uMUL_NUM-1:0];

generate
genvar m,n;
     for (m=0;m<=uMUL_NUM1-1;m=m+1) begin:MUL_GEN1
          for (n=0;n<=uMUL_NUM2-1;n=n+1) begin:MUL_GEN2
               if(MUL_OREG==1)begin
                    always@(posedge clk or negedge rst_n) begin
                         if(!rst_n) begin
                              i_prod[m*uMUL_NUM2+n] <= 'd0;
                         end
                         else begin
                              i_prod[m*uMUL_NUM2+n] <= $signed(i_mul1[m]) * $signed(i_mul2[n]);
                         end
                    end
               end
               else begin
                    always@( * )begin
                              i_prod[m*uMUL_NUM2+n] <= $signed(i_mul1[m]) * $signed(i_mul2[n]);
                    end
               end
               assign i_prod_expand[m*uMUL_NUM2+n]=
                    {{ePROD_WIDTH-uPROD_WIDTH-(m+n)*cMUL_WIDTH{i_prod[m*uMUL_NUM2+n][uPROD_WIDTH-1]}},
                                                      i_prod[m*uMUL_NUM2+n],{(m+n)*cMUL_WIDTH{1'b0}}};
          end
     end
endgenerate

//-------------------------------------------pipeline adder generate--------------------------------------------------
localparam ADD_PPL_LEVEL = PPL_LEVEL-(PROD_OREG+MUL_OREG+iMUL_IREG);
localparam SUM_WIDTH= ePROD_WIDTH + $clog2(uMUL_NUM);
wire [ePROD_WIDTH*uMUL_NUM-1:0] addend;

wire [SUM_WIDTH-1:0] sum;

generate
genvar x;
     for (x=0;x<=uMUL_NUM-1;x=x+1)begin:ADDEND_GEN
          assign addend[ePROD_WIDTH*(x+1)-1 -: ePROD_WIDTH] = i_prod_expand[x];
     end
endgenerate

ppl_mult_adder
#(
.ADDEND_NUM  (uMUL_NUM      ),
.ADDEND_WITDH(ePROD_WIDTH   ),
.PPL_LEVEL   (ADD_PPL_LEVEL )
)
ppl_mult_adder_inst
(
.rst_n       (rst_n         ),
.clk         (clk           ),
.in          (addend        ),
.out         (sum           )
);
//---------------------------------------Prod Output generate--------------------------------------------------

reg [PROD_WIDTH-1:0] prod_reg;

generate
     if(PROD_OREG==1)begin
          always@(posedge clk or negedge rst_n) begin
               if(!rst_n)begin
                    prod_reg <= 'd0;
               end
               else begin
                    prod_reg <= sum[PROD_WIDTH-1:0];
               end
          end
     end
     else begin
           always@( * ) begin
                prod_reg <= sum[PROD_WIDTH-1:0];
           end
     end
endgenerate

assign prod = prod_reg;

endmodule


//=========================================================================================================================
//********************************Module: multi-port pipeline parallel adder **********************************************
//=========================================================================================================================

module ppl_mult_adder
#(
//External parameter
parameter ADDEND_NUM     = 16                                  ,
parameter ADDEND_WITDH   = 16                                  ,
parameter PPL_LEVEL      = 4                                   ,
//internal parameter
parameter IN_WITDH       = ADDEND_WITDH * ADDEND_NUM           ,
parameter OUT_WITDH      = ADDEND_WITDH + $clog2(ADDEND_NUM)
)
(
input                         rst_n,
input                         clk  ,
input     [IN_WITDH-1:0]      in   ,
output    [OUT_WITDH-1:0]     out
);

//============================================Pipeline insertion algorithm ================================================
function integer reg_insert;
input integer level;
input integer logic_level;
input integer ppl_level;
input integer precision;

integer ppl_int;
integer level_loc;

integer ppl_loc;
integer ppl_loc_temp;
integer ppl_logic_int;
integer ppl_logic_int_min;
integer i;

begin
     level_loc=level*precision;
     ppl_int=(logic_level*precision)/(ppl_level+1);
     ppl_logic_int_min=precision;
     ppl_loc=logic_level*precision-ppl_int;
     ppl_loc_temp=logic_level*precision-ppl_int;

     for(i=1;i<=ppl_level;i=i+1) begin
          ppl_loc_temp=logic_level*precision - i*ppl_int;
          ppl_logic_int=(ppl_loc_temp-level_loc>=0)?(ppl_loc_temp-level_loc):(level_loc-ppl_loc_temp);
          if(ppl_logic_int_min>=ppl_logic_int) begin
               ppl_logic_int_min=ppl_logic_int;
               ppl_loc=ppl_loc_temp;
          end
     end

     if (ppl_level<=0) begin
          reg_insert = 0;
     end
     else if (logic_level<ppl_level) begin
          reg_insert = 1;
     end
     else if(logic_level==ppl_level) begin
          reg_insert = (level==0)?0:1;
     end
     else if (((ppl_loc-level_loc< precision/2)&&(ppl_loc>level_loc))||
             ((level_loc-ppl_loc< precision/2)&&(level_loc>ppl_loc)) ||
             ((level_loc-ppl_loc==precision/2)&&(level_loc>ppl_loc)) ||
             (level_loc==ppl_loc)) begin
          reg_insert = 1;
     end
     else begin
          reg_insert = 0;
     end
end

endfunction

//=====================================Internal parameter and signal declare===============================================

localparam ADD_LEVEL = $clog2(ADDEND_NUM);
localparam EXPAND_ADDEND_NUM = 2**ADD_LEVEL;

wire [OUT_WITDH-1:0] temp_sum [EXPAND_ADDEND_NUM*2-2:0];
reg [OUT_WITDH-1:0] temp_sum_reg [EXPAND_ADDEND_NUM*2-2:0];

//=========================================================================================================================
//                                                    Main Code
//=========================================================================================================================


//==================================================Adders  generate===---==================================================
generate

genvar i,j,k,l;
for (i=0;i<=ADD_LEVEL;i=i+1) begin:ADD_GEN
//Expand input addends
     if (i==0) begin
          for (j=0;j<=ADDEND_NUM-1;j=j+1) begin:TEMP_SUM_GEN0
               assign temp_sum[j] = {{($clog2(ADDEND_NUM)){1'b0}},in[ADDEND_WITDH*(j+1)-1 -: ADDEND_WITDH]};
          end
          for (l=ADDEND_NUM;l<=EXPAND_ADDEND_NUM-1;l=l+1) begin:TEMP_SUM_GEN2
               assign temp_sum[l] = 'd0;
          end
     end
//Adders cascade
     else begin
          for (k=0;k<=EXPAND_ADDEND_NUM/(2**i)-1;k=k+1) begin:TEMP_SUM_GEN3
               assign temp_sum[2*EXPAND_ADDEND_NUM-2*EXPAND_ADDEND_NUM/(2**i)+k] =
                    temp_sum_reg[2*(EXPAND_ADDEND_NUM-2*EXPAND_ADDEND_NUM/(2**i)+k)]+
                    temp_sum_reg[2*(EXPAND_ADDEND_NUM-2*EXPAND_ADDEND_NUM/(2**i)+k)+1];
          end
     end
end

endgenerate

//=================================================pipeline generate=========================================================
generate
genvar x,m,n;

for (x=0;x<=ADD_LEVEL;x=x+1) begin:PPL_GEN
     if(reg_insert(x,ADD_LEVEL,PPL_LEVEL,1000)==1) begin
          for (m=0;m<=EXPAND_ADDEND_NUM/(2**x)-1;m=m+1) begin:TEMP_SUM_REG_GEN1
               always@(posedge clk or negedge rst_n) begin
                    if (!rst_n) begin
                         temp_sum_reg[2*EXPAND_ADDEND_NUM-(2*EXPAND_ADDEND_NUM)/(2**x)+m] <='d0;
                    end
                    else begin
                         temp_sum_reg[2*EXPAND_ADDEND_NUM-(2*EXPAND_ADDEND_NUM)/(2**x)+m] <=
                             temp_sum[2*EXPAND_ADDEND_NUM-(2*EXPAND_ADDEND_NUM)/(2**x)+m]  ;
                    end
               end
          end
     end
     else begin
          for (n=0;n<=EXPAND_ADDEND_NUM/(2**x)-1;n=n+1) begin:TEMP_SUM_REG_GEN2
               always@( * ) begin
                    temp_sum_reg[2*EXPAND_ADDEND_NUM-(2*EXPAND_ADDEND_NUM)/(2**x)+n] <=
                        temp_sum[2*EXPAND_ADDEND_NUM-(2*EXPAND_ADDEND_NUM)/(2**x)+n]  ;
               end
          end
     end
end

endgenerate

//======================================================Output generate=======================================================
generate
genvar y;

if (PPL_LEVEL>=ADD_LEVEL+2) begin
     reg [OUT_WITDH-1:0] temp_sum_reg_extra [PPL_LEVEL-ADD_LEVEL-2:0];
     always@(posedge clk or negedge rst_n) begin
          if (!rst_n) begin
               temp_sum_reg_extra[0] <= 'd0;
          end
          else begin
               temp_sum_reg_extra[0] <= temp_sum_reg[EXPAND_ADDEND_NUM*2-2];
          end
     end
     for (y=1;y<=PPL_LEVEL-ADD_LEVEL-2;y=y+1) begin:EXTRA_PPL_GEN
          always@(posedge clk or negedge rst_n) begin
               if (!rst_n) begin
                    temp_sum_reg_extra[y] <= 'd0;
               end
               else begin
                    temp_sum_reg_extra[y]<=temp_sum_reg_extra[y-1];
               end
          end
     end
     assign out = temp_sum_reg_extra[PPL_LEVEL-ADD_LEVEL-2];
end
else begin
     assign out = temp_sum_reg[EXPAND_ADDEND_NUM*2-2];
end

endgenerate

endmodule
