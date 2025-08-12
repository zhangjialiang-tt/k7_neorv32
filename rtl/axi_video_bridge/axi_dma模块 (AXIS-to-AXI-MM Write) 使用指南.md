### `axi_dma` 模块 (AXIS-to-AXI-MM Write) 使用指南 (已修正)

#### 模块概述

该模块的核心功能是将一个 AXI-Stream (AXIS) 数据流，通过内部的 AXI-Master 接口，写入到 AXI Memory-Mapped (AXI-MM) 总线所连接的下游设备中（通常是 DDR 内存或 BRAM）。它扮演着一个“数据搬运工”的角色，将流式数据转化为存储器中的块数据。

操作的核心思想是**基于描述符 (Descriptor-based)**。您不能直接向模块发送数据，而是必须先发送一个“指令”（描述符），告诉 DMA 您**将要**发送多少数据以及要存放到哪里。

#### 关键接口与参数

-   **参数化接口**: 本模块是高度参数化的。所有接口的位宽（如 `tdata`, `tkeep`）都由模块实例化时的参数（如 `AXIS_DATA_WIDTH`）决定。本指南将使用 `[WIDTH-1:0]` 的形式表示，请根据您的实际参数进行替换。
-   **主要接口**: 您主要会与以下三个 AXI-Stream 接口和一个控制信号交互：
    1.  **`write_enable` (Input)**: **全局写使能**。此信号必须为高，写功能才会计活。
    2.  **`s_axis_write_desc_*` (Slave/Input)**: 写操作描述符输入接口。用于接收您的“指令”。
    3.  **`s_axis_write_data_*` (Slave/Input)**: 写数据输入接口。用于接收您要写入内存的实际数据。
    4.  **`m_axis_write_desc_status_*` (Master/Output)**: 写操作状态输出接口。DMA 通过此接口向您报告“指令”的执行情况。

#### 标准使用流程 (Step-by-Step)

一个完整的 DMA 写操作包含以下四个步骤：

##### **步骤 0：使能模块**

-   将模块顶层的 `write_enable` 输入信号置为高电平 (`1'b1`)。如果此信号为低，DMA将忽略所有后续操作。

##### **步骤 1：准备并发送写描述符 (指令)**

这是所有操作的第一步。您需要通过 `s_axis_write_desc_*` 接口告诉 DMA 接下来要执行一个什么样的写任务。

1.  **准备描述符内容**:
    *   `s_axis_write_desc_addr [AXI_ADDR_WIDTH-1:0]`: 设置目标内存**起始地址**。
    *   `s_axis_write_desc_len [LEN_WIDTH-1:0]`: 设置本次传输的**总字节数**。
    *   `s_axis_write_desc_tag [TAG_WIDTH-1:0]`: 设置一个**唯一的事务标签 (Tag)**。这个 Tag 至关重要，它就像这个任务的“订单号”。后续的状态会使用这个 Tag 来关联。**请注意，此 Tag 是 DMA 内部管理信号，与 AXI-Stream 的 `tid` 无关。**

2.  **发送描述符**:
    *   将上述准备好的 `addr`, `len`, `tag` 信号驱动到接口上。
    *   拉高 `s_axis_write_desc_valid` 信号。
    *   等待（或检查）`s_axis_write_desc_ready` 信号变为高。
    *   当 `valid` 和 `ready` 在时钟上升沿同时为高时，描述符被 DMA 成功接收。您可以撤销 `valid` 信号了。

##### **步骤 2：准备并发送数据流**

在描述符被接收后，您就可以通过 `s_axis_write_data_*` 接口发送实际的数据了。

1.  **准备数据流**:
    *   `s_axis_write_data_tdata [AXIS_DATA_WIDTH-1:0]`: 您要写入的数据。
    *   `s_axis_write_data_tkeep [AXIS_KEEP_WIDTH-1:0]`: 字节使能。如果传输完整的数据字，此值应全为 `1`。
    *   `s_axis_write_data_tlast`: **默认保持为低**。只在发送整个数据包的**最后一个数据字 (beat)** 时，才拉高此信号。
    *   `s_axis_write_data_tid [AXIS_ID_WIDTH-1:0]`: AXI-Stream 的标识符。这是一个可选的、透传的信号，用于数据流本身的管理，**与描述符的 `tag` 无关**。

2.  **发送数据流**:
    *   计算需要传输的次数 (beats)：`beats = ceil(总字节数 / (AXIS_DATA_WIDTH/8))`。
    *   循环发送数据：
        *   驱动 `tdata`, `tkeep`, `tlast` 等信号。
        *   拉高 `s_axis_write_data_tvalid`。
        *   **处理反压**: 必须检查 `s_axis_write_data_tready`。只有当它为高时，数据才被真正接收，您才能准备发送下一个 beat。如果 `tready` 为低，您必须保持所有数据和 `tvalid` 信号不变，直到 `tready` 变高。
        *   在发送最后一个 beat 时，将 `s_axis_write_data_tlast` 拉高。

##### **步骤 3：异步接收并处理状态**

DMA 完成数据写入后，会通过 `m_axis_write_desc_status_*` 接口主动向您报告。您的设计中必须有一个模块来随时准备接收这些状态。

1.  **监听状态接口**: 时刻监控 `m_axis_write_desc_status_valid` 信号。
2.  **解析状态**: 当 `valid` 变高时，锁存状态信息：
    *   `m_axis_write_desc_status_tag [TAG_WIDTH-1:0]`: 这是已完成任务的“订单号”。用它来匹配您之前发送的请求。
    *   `m_axis_write_desc_status_len [LEN_WIDTH-1:0]`: 这是 **DMA 实际完成**的字节数。
    *   `m_axis_write_desc_status_error [3:0]`: 错误代码。`0` 表示无错误。

##### **步骤 4：核对与确认**

这是确保系统可靠性的关键一步。

1.  **核对 Tag**: 确认收到的状态 `tag` 是您正在等待的。
2.  **核对 Length**: **必须检查**返回的 `len`。正常情况下，它应与您请求的 `len` 一致。如果不一致，说明数据包被提前的 `tlast` 信号终止了。
3.  **检查错误**: 检查 `error` 字段，确保没有发生内部错误（如 AXI 总线错误）。

---

### 总结与最佳实践

-   **使能先行**: 确保 `write_enable` 信号在操作前已置位。
-   **Tag 是核心**: `Tag` 是连接指令和状态的唯一纽带。请务必管理好您的 Tag，不要在旧任务完成前复用同一个 Tag。
-   **永远相信 Status**: 不要假设您请求了多少数据，DMA 就一定成功写入了多少。**唯一可靠的信息来源是 DMA 返回的状态报告**。
-   **鲁棒的发送逻辑**: 您的数据发送逻辑必须能正确处理 `tready` 带来的反压，并能在正确的时机置位 `tlast`。
-   **异步处理**: 状态返回是异步的，您的主控逻辑需要有状态机来跟踪已发送但尚未收到最终状态的 DMA 任务。
