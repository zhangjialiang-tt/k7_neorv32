/*******************************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________

--Module Name:
--Project Name:
--Chinese Description:
	
--English Description:
	
--Version:VERA.1.0.0
--Data modified:
--author:Young-ÎâÃ÷
--E-mail: wmy367@Gmail.com
--Data created:
________________________________________________________
********************************************************/
`timescale 1ns / 1ps
module tb_simple;

    wire [1  - 1 : 0] i_Sys_clk;
    wire [1  - 1 : 0] i_Rst_n;
    reg               clock = 0;
    reg               rst = 0;
    always #10 clock = ~clock;
    initial begin
        rst = 0;
        repeat (2) @(posedge clock);
        rst = 1;
        repeat (2) @(posedge clock);
        rst = 0;
    end

    parameter DW = 16;
    parameter WIDTH_N = 16;
    parameter WIDTH_D = 16;
    //*????????
    integer i;
    localparam N = 2**10;
    reg  [WIDTH_D  - 1 : 0] rand_data1;
    reg  [WIDTH_N  - 1 : 0] rand_data2;
    reg   [WIDTH_D  - 1 : 0] denom;
    reg   [WIDTH_N  - 1 : 0] numer;
    reg                i_wb4s_cyc;  // WB cyc, active/abort signal
    reg  [        1:0] i_wb4s_tgd;  // [1] 0=quotient, 1=rem; [0] 0=signed, 1=unsigned
    reg                i_wb4s_stb;  // WB stb, valid strobe
    wire [     32-1:0] i_wb4s_data_l;  // WB data, {divisor, dividend}
    wire [     32-1:0] i_wb4s_data_h;  // WB data, {divisor, dividend}
    wire [ (DW*2)+1:0] i_wb4s_data;  // WB data, {divisor, dividend}
    reg  [ 8  - 1 : 0] cnt_din;
    wire [ 1  - 1 : 0] data_en;
    assign i_Sys_clk = clock;
    assign i_Rst_n   = ~rst;
    assign data_en   = cnt_din == 8'hff ? 'd1 : 'd0;
    reg           [ 1  - 1 : 0 ]          data_en_d1               ;
    always @(posedge i_Sys_clk) begin
        if (~i_Rst_n) begin
            cnt_din <= 'd0;
            data_en_d1 <= 'd0;
        end else begin
            cnt_din <= cnt_din + 'd1;
            data_en_d1 <= data_en;
        end
    end
    always @(posedge i_Sys_clk) begin
        if (~i_Rst_n) begin
            rand_data1 <= 'd0;
            rand_data2 <= 'd0;
        end else if (data_en) begin
            rand_data1 <= {$random} % N;
            rand_data2 <= {$random} % N;
        end
    end
// assign denom = rand_data1*(-1);
// assign numer = rand_data2*(-1)+100000;
initial begin
    denom = 0;
    numer = 0;
    #10000
    denom = rand_data1*(-1);
    numer = (rand_data2+1000)*(-1);
    #10000
    denom = rand_data1;
    numer = (rand_data2+1000);
    #10000
    denom = rand_data1;
    numer = (rand_data2+1000)*(-1);

end



    divider_wrapper # (
        .LPM_REPRESENTATION("SIGNED"),
        .LPM_WIDTHD(WIDTH_D),
        .LPM_WIDTHN(WIDTH_N)
      )
      divider_wrapper_inst (
        .clock                              (i_Sys_clk                 ),
        .clken                              (1'b1                      ),
        .din_en                             (data_en_d1                   ),
        .denom                              (denom                     ),
        .numer                              (numer                     ),
        .quotient_en                        (),
        .quotient                           () 
      );
    divider_wrapper # (
        .LPM_REPRESENTATION("UNSIGNED"),
        .LPM_WIDTHD(WIDTH_D),
        .LPM_WIDTHN(WIDTH_N)
      )
      divider_wrapper2_inst (
        .clock                              (i_Sys_clk                 ),
        .clken                              (1'b1                      ),
        .din_en                             (data_en_d1                   ),
        .denom                              (denom                     ),
        .numer                              (numer                     ),
        .quotient_en                        (),
        .quotient                           () 
      );
endmodule
