# 设计技巧: `DC_FIFO` 控制方法与实现指南 (已修正)

## 1. 概述

本指南根据 `rtl/common/DC_FIFO.v` 的实际代码，详细阐述如何在 `axi_video_bridge` 中正确使用和控制该异步FIFO。特别地，我们将基于 `FIFO_MODE = "ShowAhead"` 的特性来设计控制逻辑。

## 2. `DC_FIFO.v` 接口确认

在实例化时，必须确保连接到以下正确的端口：

-   **写侧接口**: `wclk`, `wrst_n`, `winc` (写使能/increment), `wdata`, `wfull` (写满状态)。
-   **读侧接口**: `rclk`, `rrst_n`, `rinc` (读使能/increment), `rdata`, `rempty` (读空状态)。

## 3. 理解 "ShowAhead" (FWFT) 模式

`FIFO_MODE = "ShowAhead"` 是本设计的核心前提。其关键特性是：

> 当一个数据被写入一个原本为空的FIFO后，该数据会**立即**出现在读数据输出端口 `rdata` 上，此时 `rempty` 信号会变为低。这一切都发生在第一个 `rinc` (读使能) 信号到来**之前**。

这意味着：
-   `rdata` 端口的数据在 `rempty` 为低时，**总是有效的**。
-   `rinc` 信号的作用是**“消费”**掉当前已在 `rdata` 上的数据，并让**下一个**数据（如果存在）呈现在 `rdata` 上。

这个特性极大地影响了读侧的控制逻辑。

## 4. 写路径 (`axis_wr_path`) FIFO 控制

在写路径中，数据从 `pclk` 域 (`wclk`) 流向 `axi_clk` 域 (`rclk`)。

### 4.1 FIFO 实例化

```verilog
// FIFO for AXI-Stream Data
DC_FIFO #(
    .DSIZE(AXI_DATA_WIDTH),
    .ASIZE(FIFO_ADDR_WIDTH),
    .FIFO_MODE("ShowAhead")
) wr_data_fifo (
    .wclk(pclk), .wrst_n(pclk_rst_n),
    .winc(fifo_wr_en), .wdata(packed_dvp_data),
    .wfull(wr_fifo_full),

    .rclk(axi_clk), .rrst_n(axi_rst_n),
    .rinc(fifo_rd_en_axi_clk),
    .rdata(s_axis_write_data_tdata),
    .rempty(wr_fifo_empty)
);

// 并行实例化 TLAST_FIFO，使用完全相同的控制信号和参数
// ...
```

### 4.2 写侧控制 (`pclk` 域)

这部分逻辑不受 `ShowAhead` 模式影响，与之前相同。

-   **控制条件**: 当一个数据字打包完成 (`pack_done`) 且FIFO未满 (`!wr_fifo_full`) 时，产生一个周期的 `fifo_wr_en` 脉冲，同时驱动 `winc`。

```verilog
// In pclk domain
assign fifo_wr_en = pack_done && !wr_fifo_full;
```

### 4.3 读侧控制 (`axi_clk` 域)

读侧生成标准的AXI-Stream接口，连接到`axi_dma`。

-   **`tvalid` 的生成**: `tvalid` 直接等同于 `!rempty`。只要FIFO不为空，就代表`rdata`上的数据是有效的。
    ```verilog
    // In axi_clk domain
    assign s_axis_write_data_tvalid = !wr_fifo_empty;
    ```

-   **`rinc` (读使能) 的生成**: `rinc` 用于“消费”数据。只有当 `rdata` 上的有效数据被下游的 `axi_dma` 接收后，我们才需要从FIFO中取下一个。因此，`rinc` 在 `tvalid` 和 `tready` 同时为高时有效。
    ```verilog
    // In axi_clk domain
    assign fifo_rd_en_axi_clk = s_axis_write_data_tvalid && s_axis_write_data_tready;
    ```

## 5. 读路径 (`axis_rd_path`) FIFO 控制

在读路径中，数据从 `axi_clk` 域 (`wclk`) 流向 `pclk` 域 (`rclk`)。

### 5.1 FIFO 实例化

```verilog
// FIFO for AXI-Stream Data
DC_FIFO #(
    .DSIZE(AXI_DATA_WIDTH),
    .ASIZE(FIFO_ADDR_WIDTH),
    .FIFO_MODE("ShowAhead")
) rd_data_fifo (
    .wclk(axi_clk), .wrst_n(axi_rst_n),
    .winc(fifo_wr_en_axi_clk), .wdata(m_axis_read_data_tdata),
    .wfull(rd_fifo_full),

    .rclk(pclk), .rrst_n(pclk_rst_n),
    .rinc(fifo_rd_en_pclk), .rdata(unpacked_axi_data),
    .rempty(rd_fifo_empty)
);

// ... similar instantiation for rd_tlast_fifo ...
```

### 5.2 写侧控制 (`axi_clk` 域)

此逻辑作为标准的AXI-Stream从设备，不受`ShowAhead`模式影响。

-   **`tready` 的生成**: 只要FIFO没满，就可以接收数据。
    ```verilog
    assign m_axis_read_data_tready = !rd_fifo_full;
    ```
-   **`winc` (写使能) 的生成**: 当上游`axi_dma`的数据有效且FIFO有空间时，写入FIFO。
    ```verilog
    assign fifo_wr_en_axi_clk = m_axis_read_data_tvalid && m_axis_read_data_tready;
    ```

### 5.3 读侧控制 (`pclk` 域) - **关键逻辑**

这里的FSM必须遵循`ShowAhead`模式的规则。

-   **FSM状态**: `IDLE`, `UNPACK_WORD`
-   **核心思想**: FSM不再需要一个单独的状态去“请求”数据。它只需要在空闲时检查FIFO是否为空。如果不为空，就可以立即开始处理 `rdata` 上的数据，并在处理的同时发出 `rinc` 信号去“消费”它。

**状态转移与操作:**

-   **`IDLE`**:
    -   **等待条件**: `frame_read_start` (来自顶层FSM的启动信号) 且 `!rd_fifo_empty` (FIFO中已有数据呈现)。
    -   **转移条件**: 当上述等待条件满足时。
    -   **动作**:
        -   **立即锁存**: `latched_data <= unpacked_axi_data;` (因为数据已经有效)。
        -   **立即消费**: `fifo_rd_en_pclk <= 1'b1;` (发出单周期`rinc`脉冲)。
        -   复位解包计数器 `unpack_cnt`。
        -   转移到 `UNPACK_WORD`。

-   **`UNPACK_WORD`**:
    -   **动作**:
        -   `fifo_rd_en_pclk <= 1'b0;` (撤销`rinc`)。
        -   根据 `unpack_cnt` 从 `latched_data` 中解包并输出像素。
        -   递增 `unpack_cnt`。
    -   **转移条件**: 当一个字解包完成时 (`unpack_cnt` 达到最大值)。
    -   **后续动作**:
        -   **如果不是帧的结尾**: 检查 `!rd_fifo_empty`。如果为真，则再次**立即锁存**新的`rdata`，**立即发出**`rinc`脉冲，并保持在`UNPACK_WORD`状态（或转移到一个中间状态再回来），开始新一轮解包。
        -   **如果是帧的结尾**: 转移到 `IDLE`。

## 6. 总结

`ShowAhead` 模式优化了读延迟，但要求读侧控制逻辑相应地调整。关键在于要认识到 **`rdata` 的有效性仅取决于 `!rempty`**，而 `rinc` 的作用是**消费当前数据并请求下一个**。本指南已根据此特性提供了修正后的控制方案，可作为RTL编码的可靠依据。