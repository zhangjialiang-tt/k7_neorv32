/*

Copyright (c) 2014-2021 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * ============================================================================
 * 模块: priority_encoder
 * 描述:
 *   一个通用的、可参数化的优先级编码器。
 *   它接收一个N位的输入向量，找到第一个为'1'的位（根据优先级设置），
 *   并输出该位的索引（二进制编码）以及一个one-hot编码。
 *   该实现采用了树形结构，对于较宽的输入位宽也能高效地综合。
 * ============================================================================
 */
module priority_encoder #
(
    // --[ 参数定义 ]--
    // 输入向量的位宽
    parameter WIDTH = 4,
    // 优先级方向选择
    // 1 = LSB (最低位, bit 0) 具有最高优先级
    // 0 = MSB (最高位, bit N-1) 具有最高优先级
    parameter LSB_HIGH_PRIORITY = 0
)
(
    // --[ 端口定义 ]--
    // 输入的未编码向量
    input  wire [WIDTH-1:0]         input_unencoded,
    // 输出有效信号，当输入向量中至少有一个'1'时为高
    output wire                     output_valid,
    // 输出的二进制编码结果，表示最高优先级'1'的位置
    output wire [$clog2(WIDTH)-1:0] output_encoded,
    // 输出的one-hot编码结果，只有最高优先级的位为'1'
    output wire [WIDTH-1:0]         output_unencoded
);

// --[ 内部实现 ]--
// 计算编码所需的层级数(树的深度)
parameter LEVELS = WIDTH > 2 ? $clog2(WIDTH) : 1;
// 将宽度扩展到2的幂，方便处理
parameter W = 2**LEVELS;

// 将输入补零，扩展到W位
wire [W-1:0] input_padded = {{W-WIDTH{1'b0}}, input_unencoded};

// 存储树形结构每一层的有效位和编码位
wire [W/2-1:0] stage_valid[LEVELS-1:0];
wire [W/2-1:0] stage_enc[LEVELS-1:0];

generate
    genvar l, n; // 循环变量

    // 第一级处理：将输入两两分组进行比较
    for (n = 0; n < W/2; n = n + 1) begin : loop_in
        // 只要两个输入中有一个为1，该组的valid就为1
        assign stage_valid[0][n] = |input_padded[n*2+1:n*2];
        if (LSB_HIGH_PRIORITY) begin
            // LSB优先，如果bit 0为1，则编码为0；否则为1。
            // !input_padded[n*2+0] 在 input_padded[n*2+0]=1 时为 0，在 input_padded[n*2+1]=1 时为 1 (此时前者必为0)
            assign stage_enc[0][n] = !input_padded[n*2+0];
        end else begin
            // MSB优先，如果bit 1为1，则编码为1；否则为0。
            assign stage_enc[0][n] = input_padded[n*2+1];
        end
    end

    // 后续层级处理：将前一级的结果逐级压缩，直到得到最终结果
    for (l = 1; l < LEVELS; l = l + 1) begin : loop_levels
        for (n = 0; n < W/(2*2**l); n = n + 1) begin : loop_compress
            // 将前一级相邻的两个valid合并
            assign stage_valid[l][n] = |stage_valid[l-1][n*2+1:n*2];
            // 根据优先级和前一级的结果，构建当前层级的编码
            if (LSB_HIGH_PRIORITY) begin
                // LSB优先，优先选择索引较小（分组0）的结果
                // (n*2+1)*l-1:(n*2+0)*l 表示第 n*2 组的编码结果
                // (n*2+2)*l-1:(n*2+1)*l 表示第 n*2+1 组的编码结果
                assign stage_enc[l][(n+1)*(l+1)-1:n*(l+1)] = stage_valid[l-1][n*2+0] ? {1'b0, stage_enc[l-1][(n*2+1)*l-1:(n*2+0)*l]} : {1'b1, stage_enc[l-1][(n*2+2)*l-1:(n*2+1)*l]};
            end else begin
                // MSB优先，优先选择索引较大（分组1）的结果
                assign stage_enc[l][(n+1)*(l+1)-1:n*(l+1)] = stage_valid[l-1][n*2+1] ? {1'b1, stage_enc[l-1][(n*2+2)*l-1:(n*2+1)*l]} : {1'b0, stage_enc[l-1][(n*2+1)*l-1:(n*2+0)*l]};
            end
        end
    end
endgenerate

// --[ 输出赋值 ]--
// 最终的valid信号
assign output_valid = (W > 1) ? stage_valid[LEVELS-1] : input_padded[0];
// 最终的编码结果
assign output_encoded = (W > 1) ? stage_enc[LEVELS-1] : 0;
// 根据编码结果生成one-hot输出
assign output_unencoded = (output_valid) ? (1 << output_encoded) : 0;

endmodule

`resetall