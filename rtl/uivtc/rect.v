// ------------------------------------------------------------------------------------------------
// Company                      : Wuhan Guide Sensmart Tech Co., Ltd
// Create Date                  : 20230719
// Author Name                  : zhangjl
// Module Name                  : rect
// Project Name                 : Image Crop Module
// Tarject Device               : Titanium-ti60f100
// Tool Versions                : Efinity-2022.2.322.5.7
// Description                  : 实现图像中心区域裁剪功能，支持多种输出模式：
//                              0-原始图像输出
//                              1-按行渐变输出
//                              2-按列渐变输出
//                              3-固定棋盘格输出
//                              4-移动棋盘格输出
//                              裁剪范围由i_Rect_start_x/y和i_Rect_post_w/h确定
//                              支持双缓冲乒乓切换
// Revision                     : 1.00.0000
// Modified by                  :
// Modified Data                :20250405
// Additional Comments          :
// Standard Syndoc              :
// ------------------------------------------------------------------------------------------------
module rect #(
    parameter CW = 10,
    parameter DW = 16,
    parameter IMAGE_WIDTH = 'd640,
    parameter IMAGE_HEIGHT = 'd480
) (
    //global input interface
    input  wire [1                   - 1 : 0] i_Sys_clk,       //
    input  wire [1                   - 1 : 0] i_Rst_n,
    input  wire [32                  - 1 : 0] i_Buffer_addr_0,
    input  wire [32                  - 1 : 0] i_Buffer_addr_1,
    input  wire [CW                  - 1 : 0] i_Rect_start_x,
    input  wire [CW                  - 1 : 0] i_Rect_start_y,
    input  wire [CW                  - 1 : 0] i_Rect_post_w,
    input  wire [CW                  - 1 : 0] i_Rect_post_h,
    input  wire [3                   - 1 : 0] i_Output_mode,   // 输出模式控制: 0-原始数据, 1-行渐变, 2-列渐变, 3-棋盘格, 4-移动棋盘格
    input  wire [1                   - 1 : 0] i_Image_vs,
    input  wire [1                   - 1 : 0] i_Image_de,
    input  wire [DW                  - 1 : 0] i_Image_data,
    output wire [1                   - 1 : 0] o_Field_rst,
    output reg  [32                  - 1 : 0] o_Base_addr,
    output wire [1                   - 1 : 0] o_Image_vs,
    output reg  [1                   - 1 : 0] o_Image_de,
    output reg  [DW                  - 1 : 0] o_Image_data
);  //rect

    //************************parameter defination***********************
    localparam RE_RI = IMAGE_WIDTH / 4;  //裁剪后图像起始点x坐标
    localparam RE_RJ = IMAGE_HEIGHT / 4;  //裁剪后图像起始点y坐标
    localparam RECT_WIDTH = IMAGE_WIDTH / 2;  //裁剪后图像宽度
    localparam RECT_HEIGHT = IMAGE_HEIGHT / 2;  //裁剪后图像高度
    localparam X_MOVE = 'd50;  //上一帧图像相比当前帧图像前后左右扩展的像素点数
    localparam Y_MOVE = 'd50;  //上一帧图像相比当前帧图像前后左右扩展的像素点数
    
    // 棋盘格参数
    localparam CHECKER_SIZE = 'd32;  // 棋盘格大小
    localparam MOVE_SPEED = 'd2;     // 移动速度(每帧移动像素数)
    localparam CHECKER_SIZE_WIDTH = 6; // 2*CHECKER_SIZE需要的位宽
    //************************wire signal defination***********************

    reg [1                   - 1 : 0] image_vs_d1;
    reg [1                   - 1 : 0] image_de_d1;
    reg [DW                  - 1 : 0] image_data_d1;
    reg [CW                  - 1 : 0] hcnt;
    reg [CW                  - 1 : 0] vcnt;
    
    // 移动棋盘格相关寄存器
    reg [CHECKER_SIZE_WIDTH - 1 : 0] move_offset_x;
    reg [CHECKER_SIZE_WIDTH - 1 : 0] move_offset_y;
    
    //**********************************************************************************************
    always @(posedge i_Sys_clk) begin
        if (~i_Rst_n) begin
            image_vs_d1   <= 'd0;
            image_de_d1   <= 'd0;
            image_data_d1 <= 'd0;
        end else begin
            image_vs_d1   <= i_Image_vs;
            image_de_d1   <= i_Image_de;
            image_data_d1 <= i_Image_data;
        end
    end
    
    //**********************************************************************************************
    always @(posedge i_Sys_clk) begin  //delay 0 clock
        if (~i_Rst_n) begin
            hcnt <= 'd0;
            vcnt <= 'd0;
        end else if (i_Image_vs) begin
            if (i_Image_de && hcnt == IMAGE_WIDTH - 'd1) begin
                hcnt <= 'd0;
                vcnt <= vcnt + 'd1;
            end else if (i_Image_de) begin
                hcnt <= hcnt + 'd1;
                vcnt <= vcnt;
            end else begin
                hcnt <= 'd0;
                vcnt <= vcnt;
            end
        end else begin
            hcnt <= 'd0;
            vcnt <= 'd0;
        end
    end
    
    //**********************************************************************************************
    // 移动棋盘格偏移量更新
    wire [5:0] h_checker_index;
    wire [5:0] v_checker_index;
    wire [5:0] h_checker_index_static;
    wire [5:0] v_checker_index_static;
    reg                [CW   - 1 : 0]    out_hcnt                   ;
    reg                [CW   - 1 : 0]    out_vcnt                   ;
    wire                [DW   - 1 : 0]    temp_data                   ;
    wire                [DW   - 1 : 0]    temp_data2                   ;
    assign temp_data = ((h_checker_index ^ v_checker_index) == 1'b1) ? {DW{1'b1}} : 'd0;
    assign temp_data2 = h_checker_index ^ v_checker_index;
    always @(posedge i_Sys_clk) begin
        if (~i_Rst_n) begin
            move_offset_x <= 'd0;
            move_offset_y <= 'd0;
        end else if (o_Field_rst) begin  // 场结束时更新偏移量
            // 更新X方向偏移量
            if ((move_offset_x + MOVE_SPEED) >= (CHECKER_SIZE * 2)) begin
                move_offset_x <= (move_offset_x + MOVE_SPEED) - (CHECKER_SIZE * 2);
            end else begin
                move_offset_x <= move_offset_x + MOVE_SPEED;
            end
            
            // 更新Y方向偏移量
            if ((move_offset_y + MOVE_SPEED) >= (CHECKER_SIZE * 2)) begin
                move_offset_y <= (move_offset_y + MOVE_SPEED) - (CHECKER_SIZE * 2);
            end else begin
                move_offset_y <= move_offset_y + MOVE_SPEED;
            end
        end else begin
            move_offset_x <= move_offset_x;
            move_offset_y <= move_offset_y;
        end
    end
    
    assign h_checker_index = (out_hcnt + move_offset_x) >> $clog2(CHECKER_SIZE);
    assign v_checker_index = (out_vcnt + move_offset_y) >> $clog2(CHECKER_SIZE);
    assign h_checker_index_static = (out_hcnt) >> $clog2(CHECKER_SIZE);
    assign v_checker_index_static = (out_vcnt) >> $clog2(CHECKER_SIZE);
    //**********************************************************************************************
    reg  [1                    - 1 : 0] rect_flag;
    wire [1                    - 1 : 0] rect_enable;
    always @(posedge i_Sys_clk) begin
        if (~i_Rst_n) begin
            rect_flag <= 'd0;
        end else if (i_Image_vs) begin
            if (rect_enable) begin
                rect_flag <= 'd1;
            end else begin
                rect_flag <= 'd0;
            end
        end else begin
            rect_flag <= 'd0;
        end
    end
    
    assign rect_enable  = i_Image_de && (hcnt >= i_Rect_start_x && hcnt < i_Rect_start_x + i_Rect_post_w) && 
                         (vcnt >= i_Rect_start_y && vcnt < i_Rect_start_y + i_Rect_post_h);  //delay 0 clock
                         
    //**********************************************************************************************
    // output
    assign o_Image_vs   = i_Image_vs && (vcnt >= 1 && vcnt < IMAGE_HEIGHT-1);
    always @ ( posedge i_Sys_clk ) begin
        if(~i_Rst_n) o_Image_de <= 'd0;
        else o_Image_de   <=rect_enable;
    end
    always @ ( posedge i_Sys_clk ) begin
        if(~i_Rst_n) out_hcnt <= 'd0;
        else if(o_Field_rst) out_hcnt <= 'd0;
         else if(rect_enable)out_hcnt <= out_hcnt + 'd1;
         else out_hcnt <= 'd0;
    end
    always @ ( posedge i_Sys_clk ) begin
        if(~i_Rst_n) out_vcnt <= 'd0;
        else if(o_Field_rst) out_vcnt <= 'd0;
         else if(out_hcnt==i_Rect_post_w-1)out_vcnt <= out_vcnt + 'd1;
         else out_vcnt <= out_vcnt;
    end
    reg           [ 8  - 1 : 0 ]          grad               ;
    reg           [ 8  - 1 : 0 ]          grad_temp               ;
    wire           [ 8  - 1 : 0 ]          grad_temp2               ;
    wire           [ 8  - 1 : 0 ]          grad_temp3               ;
    wire           [ 8  - 1 : 0 ]          grad_temp4               ;
    assign grad_temp2 = out_hcnt >> $clog2(CHECKER_SIZE);
    assign grad_temp3 = out_vcnt >> $clog2(CHECKER_SIZE);
    assign grad_temp4 = grad_temp2^grad_temp3;
    always @ ( posedge i_Sys_clk ) begin
        if(~i_Rst_n) grad_temp <= 'd0;
        else 
        // 用全局坐标，保持和移动棋盘格一致的 32×32 块
        // grad_temp <= ((^((out_hcnt >> $clog2(CHECKER_SIZE)) ^ (out_vcnt >> $clog2(CHECKER_SIZE)))) == 1'b1)
        grad_temp <= (grad_temp2[0]^grad_temp3[0]) == 1'b1
                ? 8'd0
                : 8'hFF;
    end
    always @ ( posedge i_Sys_clk ) begin
        if(~i_Rst_n) begin
            grad <= 'b0;
        end else if(out_vcnt[$clog2(CHECKER_SIZE)]==0)begin
            if(out_hcnt[$clog2(CHECKER_SIZE)] == 0)    grad <= 'd1;
            else                grad <= 'd255;
        end else if(out_vcnt[$clog2(CHECKER_SIZE)] == 1)begin
            if(out_hcnt[$clog2(CHECKER_SIZE)] == 0)    grad <= 'd255;
            else                grad <= 'd1;
        end
    end
    // 根据模式选择输出数据
    always @(posedge i_Sys_clk) begin
        if (~i_Rst_n) begin
            o_Image_data <= 'd0;
        end else if (rect_enable) begin
            case (i_Output_mode)
                3'd0: begin  // 原始图像数据
                    o_Image_data <= i_Image_data;
                end
                3'd1: begin  // 行渐变数据 (使用行计数vcnt作为数据)
                    o_Image_data <= {{(DW-CW){1'b0}}, out_vcnt};
                end
                3'd2: begin  // 列渐变数据 (使用列计数hcnt作为数据)
                    o_Image_data <= {{(DW-CW){1'b0}}, out_hcnt};
                end
                3'd3: begin  // 静止棋盘格
                    o_Image_data <= ((h_checker_index_static[0] ^ v_checker_index_static[0]) == 1'b1) ? {DW{1'b1}} : 'd0;
                    // o_Image_data <= {8'd0,grad[7:0]};//((hcnt[4:0] ^ vcnt[4:0]) == 1'b1) ? {DW{1'b1}} : 'd0;
                    // o_Image_data <= ((out_hcnt[4:0] ^ out_vcnt[4:0]) == 1'b1) ? {DW{1'b1}} : 'd0;
                end
                3'd4: begin  // 移动棋盘格 - 参考静态棋盘格方式
                    o_Image_data <= ((h_checker_index[0] ^ v_checker_index[0]) == 1'b1) ? {DW{1'b1}} : 'd0;
                end
                default: begin
                    o_Image_data <= i_Image_data;
                end
            endcase
        end else begin
            o_Image_data <= 'd0;
        end
    end
    
    //**********************************************************************************************
    reg pingpang_flag;
    always @(posedge i_Sys_clk) begin
        if (~i_Rst_n) begin
            pingpang_flag <= 'd0;
            o_Base_addr <= i_Buffer_addr_0;
        end else if (i_Image_vs && (hcnt == IMAGE_WIDTH-2 && vcnt == IMAGE_HEIGHT-1)) begin
            pingpang_flag <= ~pingpang_flag;
            o_Base_addr <= pingpang_flag ? i_Buffer_addr_0 : i_Buffer_addr_1;
        end else begin
            pingpang_flag <= pingpang_flag;
            o_Base_addr <= o_Base_addr;
        end
    end
    
    assign o_Field_rst = i_Image_vs && (hcnt == IMAGE_WIDTH-1 && vcnt == IMAGE_HEIGHT-1);
    //**********************************************************************************************
    
endmodule
