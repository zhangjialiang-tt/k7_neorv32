// camera_rstn 在复位后保持低电平约5ms，再保持低电平约1.3ms后释放。
module power_on_reset #(
    parameter CLK_FREQ_MHZ = 24,  // 假设时钟频率为24MHz
    parameter PWR_DELAY_MS = 5,   // 5ms上电延迟
    parameter RST_DELAY_MS = 2  // 1.3ms复位延迟
) (
    input  wire clk,             // 时钟输入
    input  wire reset_n,         // 系统复位（低有效）
    output reg  camera_rstn      // 摄像头复位输出（低有效）
);

// 计算计数器位宽和最大值
localparam PWR_CNT_WIDTH  = $clog2((PWR_DELAY_MS * CLK_FREQ_MHZ) * 1000);
localparam PWR_CNT_MAX    = (PWR_DELAY_MS * CLK_FREQ_MHZ) * 1000 - 1;
localparam RST_CNT_WIDTH  = $clog2((RST_DELAY_MS * CLK_FREQ_MHZ) * 1000);
localparam RST_CNT_MAX    = (RST_DELAY_MS * CLK_FREQ_MHZ) * 1000 - 1;

// 计数器寄存器
reg [PWR_CNT_WIDTH-1:0] pwr_cnt;
reg [RST_CNT_WIDTH-1:0] rst_cnt;

// 内部状态
reg pwr_delay_done = 1'b0;  // 上电延迟完成标志

// =============================================
// 上电延迟逻辑
// =============================================
always @(posedge clk) begin
    if (!reset_n) begin
        // 复位时，清零计数器和状态
        pwr_cnt <= {PWR_CNT_WIDTH{1'b0}};
        pwr_delay_done <= 1'b0;
        camera_rstn <= 1'b0;  // 复位期间保持摄像头复位
    end
    else if (!pwr_delay_done) begin
        // 上电延迟计数
        if (pwr_cnt < PWR_CNT_MAX) begin
            pwr_cnt <= pwr_cnt + 1'b1;
        end else begin
            pwr_delay_done <= 1'b1;  // 延迟完成
        end
    end
end

// =============================================
// 复位延迟逻辑
// =============================================
always @(posedge clk) begin
    if (!reset_n) begin
        // 复位时，清零复位计数器
        rst_cnt <= {RST_CNT_WIDTH{1'b0}};
    end
    else if (pwr_delay_done) begin
        // 上电延迟完成后，开始复位延迟计数
        if (rst_cnt < RST_CNT_MAX) begin
            rst_cnt <= rst_cnt + 1'b1;
            camera_rstn <= 1'b0;  // 保持复位
        end else begin
            camera_rstn <= 1'b1;  // 释放复位
        end
    end
end

endmodule
