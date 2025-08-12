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
 * 模块: arbiter
 * 描述:
 *   一个通用的、可参数化的仲裁器模块。
 *   该模块可以从多个请求源中选择一个进行授权。
 *   支持两种仲裁算法：
 *     1. 固定优先级 (Fixed Priority): 每个请求端口有固定的优先级。
 *     2. 轮询 (Round Robin): 优先级在各个请求端口之间循环，避免某个端口长时间得不到服务。
 *   同时，支持阻塞模式 (Blocking Mode)，在阻塞模式下，一个授权会一直保持，
 *   直到请求被撤销或收到相应的确认信号。
 * ============================================================================
 */
module arbiter #
(
    // --[ 参数定义 ]--
    // 总共的请求端口数量
    parameter PORTS = 4,
    // 仲裁类型选择: 1 = 轮询仲裁, 0 = 固定优先级仲裁
    parameter ARB_TYPE_ROUND_ROBIN = 0,
    // 阻塞模式使能: 1 = 阻塞模式, 0 = 非阻塞模式
    // 在阻塞模式下，当前授权会保持，直到满足释放条件
    parameter ARB_BLOCK = 0,
    // 阻塞模式下的释放条件 (当 ARB_BLOCK = 1 时有效)
    // 1 = 收到 acknowledge 信号时释放授权
    // 0 = 检测到 request 信号被撤销时释放授权
    parameter ARB_BLOCK_ACK = 1,
    // 优先级方向选择
    // 1 = LSB (最低位, port 0) 具有最高优先级
    // 0 = MSB (最高位, port N-1) 具有最高优先级
    parameter ARB_LSB_HIGH_PRIORITY = 0
)
(
    // --[ 端口定义 ]--
    input  wire                     clk,
    input  wire                     rst,

    // 输入端口
    // request: 每个端口的请求信号，位向量
    input  wire [PORTS-1:0]         request,
    // acknowledge: 每个端口的确认信号，用于阻塞模式
    input  wire [PORTS-1:0]         acknowledge,

    // 输出端口
    // grant: 授权信号，one-hot 编码，只有被授权的端口对应的位为1
    output wire [PORTS-1:0]         grant,
    // grant_valid: 授权有效信号，当有任何一个请求被授权时为1
    output wire                     grant_valid,
    // grant_encoded: 被授权端口的二进制编码
    output wire [$clog2(PORTS)-1:0] grant_encoded
);

// --[ 内部信号和寄存器 ]--
reg [PORTS-1:0] grant_reg = 0, grant_next;
reg grant_valid_reg = 0, grant_valid_next;
reg [$clog2(PORTS)-1:0] grant_encoded_reg = 0, grant_encoded_next;

// --[ 输出赋值 ]--
assign grant_valid = grant_valid_reg;
assign grant = grant_reg;
assign grant_encoded = grant_encoded_reg;

// --[ 逻辑实现 ]--

// 实例化一个优先级编码器，用于处理原始的请求信号
// 作用：
// 1. 在固定优先级模式下，直接找出优先级最高的请求。
// 2. 在轮询模式下，当一轮结束需要回环时，找出优先级最高的请求。
wire request_valid;
wire [$clog2(PORTS)-1:0] request_index;
wire [PORTS-1:0] request_mask;

priority_encoder #(
    .WIDTH(PORTS),
    .LSB_HIGH_PRIORITY(ARB_LSB_HIGH_PRIORITY)
)
priority_encoder_inst (
    .input_unencoded(request),
    .output_valid(request_valid),
    .output_encoded(request_index),
    .output_unencoded(request_mask)
);

// 轮询模式使用的掩码寄存器
reg [PORTS-1:0] mask_reg = 0, mask_next;

// 实例化第二个优先级编码器，用于处理被掩码（mask_reg）过滤后的请求信号
// 作用：在轮询模式下，根据掩码找出当前应该被优先处理的请求。
wire masked_request_valid;
wire [$clog2(PORTS)-1:0] masked_request_index;
wire [PORTS-1:0] masked_request_mask;

priority_encoder #(
    .WIDTH(PORTS),
    .LSB_HIGH_PRIORITY(ARB_LSB_HIGH_PRIORITY)
)
priority_encoder_masked (
    .input_unencoded(request & mask_reg),
    .output_valid(masked_request_valid),
    .output_encoded(masked_request_index),
    .output_unencoded(masked_request_mask)
);

// --[ 核心组合逻辑: 仲裁状态机 ]--
always @* begin
    // 默认情况下，不发出任何授权
    grant_next = 0;
    grant_valid_next = 0;
    grant_encoded_next = 0;
    mask_next = mask_reg; // 默认保持掩码不变

    // 1. 检查是否处于阻塞状态
    // 如果是阻塞模式，且释放条件是请求撤销，并且当前授权的请求仍然有效，则保持授权
    if (ARB_BLOCK && !ARB_BLOCK_ACK && (grant_reg & request)) begin
        // 保持当前授权不变
        grant_valid_next = grant_valid_reg;
        grant_next = grant_reg;
        grant_encoded_next = grant_encoded_reg;
    // 如果是阻塞模式，且释放条件是收到ack，并且当前有有效授权但尚未收到ack，则保持授权
    end else if (ARB_BLOCK && ARB_BLOCK_ACK && grant_valid_reg && !(grant_reg & acknowledge)) begin
        // 保持当前授权不变
        grant_valid_next = grant_valid_reg;
        grant_next = grant_reg;
        grant_encoded_next = grant_encoded_reg;
    // 2. 如果不处于阻塞状态，并且有新的请求进来
    end else if (request_valid) begin
        // 根据仲裁类型进行选择
        if (ARB_TYPE_ROUND_ROBIN) begin
            // -- 轮询模式 --
            // 首先检查经过掩码过滤后，是否还有请求
            if (masked_request_valid) begin
                // 如果有，则授权给掩码后的最高优先级请求
                grant_valid_next = 1;
                grant_next = masked_request_mask;
                grant_encoded_next = masked_request_index;
                // 更新掩码，使得下一次仲裁从当前授权的下一个端口开始
                if (ARB_LSB_HIGH_PRIORITY) begin
                    // LSB优先，掩码从低位向高位移动
                    // 将所有比当前授权端口优先级高（或相等）的端口屏蔽掉
                    mask_next = {PORTS{1'b1}} << (masked_request_index + 1);
                end else begin
                    // MSB优先，掩码从高位向低位移动
                    // 将所有比当前授权端口优先级高（或相等）的端口屏蔽掉
                    mask_next = {PORTS{1'b1}} >> (PORTS - masked_request_index);
                end
            end else begin
                // 如果掩码过滤后没有请求，说明一轮轮询结束，需要回环
                // 此时，我们对原始的请求进行授权（即回到优先级最高的请求）
                grant_valid_next = 1;
                grant_next = request_mask;
                grant_encoded_next = request_index;
                // 同时更新掩码，为下一轮轮询做准备
                if (ARB_LSB_HIGH_PRIORITY) begin
                    mask_next = {PORTS{1'b1}} << (request_index + 1);
                end else begin
                    mask_next = {PORTS{1'b1}} >> (PORTS - request_index);
                end
            end
        end else begin
            // -- 固定优先级模式 --
            // 直接授权给未经掩码处理的最高优先级请求
            grant_valid_next = 1;
            grant_next = request_mask;
            grant_encoded_next = request_index;
            // 在固定优先级模式下，掩码不改变
        end
    end
end

// --[ 时序逻辑: 寄存器更新 ]--
always @(posedge clk) begin
    if (rst) begin
        grant_reg <= 0;
        grant_valid_reg <= 0;
        grant_encoded_reg <= 0;
        mask_reg <= 0;
    end else begin
        grant_reg <= grant_next;
        grant_valid_reg <= grant_valid_next;
        grant_encoded_reg <= grant_encoded_next;
        mask_reg <= mask_next;
    end
end

endmodule

`resetall