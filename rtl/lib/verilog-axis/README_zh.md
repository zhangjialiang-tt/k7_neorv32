# Verilog AXI Stream 组件 Readme

[![构建状态](https://github.com/alexforencich/verilog-axis/workflows/Regression%20Tests/badge.svg?branch=master)](https://github.com/alexforencich/verilog-axis/actions/)

更多信息和更新请访问：http://alexforencich.com/wiki/en/verilog/axis/start

GitHub 仓库：https://github.com/alexforencich/verilog-axis

## 弃用通知

此仓库已被 https://github.com/fpganinja/taxi 取代。所有新功能和错误修复将在那里进行，并且还提供商业支持。因此，此仓库已被弃用，未来将不会收到任何维护或支持。

## 简介

AXI Stream 总线组件的集合。大多数组件的接口宽度都是完全可参数化的。包含完整的 cocotb 测试平台，这些测试平台利用了 [cocotbext-axi](https://github.com/alexforencich/cocotbext-axi)。

## 文档

### `arbiter` 模块

通用的可参数化仲裁器。支持优先级和轮询仲裁。支持阻塞直到请求释放或确认。

### `axis_adapter` 模块

`axis_adapter` 模块桥接不同宽度的 AXI stream 总线。该模块是可参数化的，但存在某些限制。首先，总线字宽必须相同（例如，一个 8 位通道和八个 8 位通道，但不能是一个 16 位通道和一个 32 位通道）。其次，总线宽度必须是整数倍关系（例如，2 个字和 6 个字，但不能是 4 个字和 6 个字）。必要时，将在较宽的总线侧插入等待状态。

### `axis_arb_mux` 模块

帧感知的 AXI stream 仲裁复用器，具有可参数化的数据宽度和端口数。支持优先级和轮询仲裁。

可以使用 `axis_arb_mux_wrap.py` 生成包装器。

### `axis_async_fifo` 模块

可配置的基于字或帧的异步 FIFO，具有可参数化的数据宽度、深度、类型和坏帧检测。仅支持 2 的幂次深度。

### `axis_async_fifo_adapter` 模块

可配置的基于字或帧的异步 FIFO，具有可参数化的数据宽度、深度、类型和坏帧检测。支持不同的输入和输出数据宽度，并适当地插入 axis_adapter 实例。仅支持 2 的幂次深度。

### `axis_broadcast` 模块

AXI stream 广播器。将一个输入流复制到多个输出流。

### `axis_cobs_decode`

一致性开销字节填充（COBS）解码器。固定 8 位宽度。

### `axis_cobs_encode`

一致性开销字节填充（COBS）编码器。固定 8 位宽度。可配置零插入。

### `axis_crosspoint` 模块

基本的交叉点开关。不支持 `tready` 信号。可参数化的数据宽度。

可以使用 `axis_crosspoint_wrap.py` 生成包装器。

### `axis_demux` 模块

帧感知的 AXI stream 解复用器，具有可参数化的数据宽度和端口数。

### `axis_fifo` 模块

可配置的基于字或帧的同步 FIFO，具有可参数化的数据宽度、深度、类型和坏帧检测。仅支持 2 的幂次深度。

### `axis_fifo_adapter` 模块

可配置的基于字或帧的同步 FIFO，具有可参数化的数据宽度、深度、类型和坏帧检测。支持不同的输入和输出数据宽度，并适当地插入 axis_adapter 实例。仅支持 2 的幂次深度。

### `axis_frame_join` 模块

帧连接器，带有可选标签和可参数化的端口数。仅支持 8 位数据路径。

可以使用 `axis_frame_join_wrap.py` 生成包装器。

### `axis_frame_length_adjust` 模块

帧长度调整模块。根据需要截断或填充帧，以满足指定的最小和最大长度。报告原始长度和当前长度，以及数据包是否被截断或填充。长度限制可在运行时配置。

### `axis_frame_length_adjust_fifo` 模块

带 FIFO 的帧长度调整模块。根据需要截断或填充帧，以满足指定的最小和最大长度。报告原始长度和当前长度，以及数据包是否被截断或填充。使用 FIFO 是为了可以在读取数据包本身之前读取状态信息。长度限制可在运行时配置。

### `axis_ll_bridge` 模块

AXI stream 到 LocalLink 桥。

### `axis_mux` 模块

帧感知的 AXI stream 复用器，具有可参数化的数据宽度和端口数。

可以使用 `axis_mux_wrap.py` 生成包装器。

### `axis_pipeline_fifo` 模块

可参数化的带输出 FIFO 的寄存器流水线。`LENGTH` 参数决定了寄存器级的数量。对于足够的流水线长度和总线宽度，与 `axis_pipeline_register` 相比，它消耗的资源更少，同时提供完整的吞吐量。

### `axis_pipeline_register` 模块

可参数化的寄存器流水线。`LENGTH` 参数决定了寄存器级的数量（`axis_register` 的实例数）。

### `axis_ram_switch` 模块

帧感知的 AXI stream RAM 开关，具有可参数化的数据宽度、端口数和 FIFO 大小。使用块 RAM 存储传输中的数据包，在端口之间分时共享 RAM 接口。功能上等同于每个端口的帧 FIFO 和宽度转换器连接到 AXI stream 开关的组合。

### `axis_rate_limit` 模块

小数速率限制器，支持字模式和帧模式。插入等待状态以将数据速率限制为指定的比率。帧模式在帧末尾插入等待状态，字模式忽略帧并在任何点插入等待状态。可参数化的数据宽度。速率和模式可在运行时配置。

### `axis_register` 模块

数据路径寄存器，可通过参数选择 skid 缓冲、简单缓冲或旁路。用于改善长路径的时序。使用 `REG_TYPE` 参数选择寄存器的类型（旁路、简单或 skid 缓冲）。

### `axis_srl_fifo` 模块

基于 SRL 的 FIFO。适用于小型 FIFO。Xilinx FPGA 上的 SRL 具有非常快的输入建立时间，因此该模块可用于帮助时序收敛。

### `axis_srl_register` tmodule

基于 SRL 的寄存器。Xilinx FPGA 上的 SRL 具有非常快的输入建立时间，因此该模块可用于帮助时序收auen。

### `axis_stat_counter` 模块

统计计数器模块。计算通过受监控的 AXI stream 接口的字节数和帧数。触发信号用于重置和通过 AXI 接口转储计数以及标签值。与 `axis_frame_join` 一起使用，可以从具有相同触发的多个监控点形成单个整体帧。

### `axis_switch` 模块

帧感知的 AXI stream 开关，具有可参数化的数据宽度和端口数。

可以使用 `axis_switch_wrap.py` 生成包装器。

### `axis_tap` 模块

AXI stream tap 模块。用于复制 AXI stream 总线而不影响总线。输出上的反压会导致截断的帧，并设置 `tuser`。

### `ll_axis_bridge` 模块

LocalLink 到 AXI stream 桥。

### `priority_encoder` 模块

可参数化的优先级编码器。

### 通用信号

    tdata   : 数据（宽度通常为 DATA_WIDTH）
    tkeep   : 数据字有效（宽度通常为 KEEP_WIDTH）
    tvalid  : 数据有效
    tready  : 接收端就绪
    tlast   : 帧结束
    tid     : 标识符标签（宽度通常为 ID_WIDTH）
    tdest   : 目标标签（宽度通常为 DEST_WIDTH）
    tuser   : 用户边带信号（宽度通常为 USER_WIDTH）

### 通用参数

    DATA_WIDTH           : tdata 信号的宽度
    KEEP_ENABLE          : 启用 tkeep 信号（默认为 DATA_WIDTH>8）
    KEEP_WIDTH           : tkeep 信号的宽度（默认为 (DATA_WIDTH+7)/8）
    LAST_ENABLE          : 启用 tlast 信号
    ID_ENABLE            : 启用 tid 信号
    ID_WIDTH             : tid 信号的宽度
    DEST_ENABLE          : 启用 tdest 信号
    DEST_WIDTH           : tdest 信号的宽度
    USER_ENABLE          : 启用 tuser 信号
    USER_WIDTH           : tuser 信号的宽度
    USER_BAD_FRAME_VALUE : tuser 指示坏帧的值
    USER_BAD_FRAME_MASK  : tuser 坏帧指示的位掩码

### 源文件

    arbiter.v                          : 通用的可参数化仲裁器
    axis_adapter.v                     : 可参数化的总线宽度适配器
    axis_arb_mux.v                     : 可参数化的仲裁复用器
    axis_async_fifo.v                  : 可参数化的异步 FIFO
    axis_async_fifo_adapter.v          : FIFO/宽度适配器包装器
    axis_broadcast.v                   : AXI stream 广播器
    axis_cobs_decode.v                 : COBS 解码器
    axis_cobs_encode.v                 : COBS 编码器
    axis_crosspoint.v                  : 可参数化的交叉点开关
    axis_demux.v                       : 可参数化的解复用器
    axis_fifo.v                        : 可参数化的同步 FIFO
    axis_fifo_adapter.v                : FIFO/宽度适配器包装器
    axis_frame_join.v                  : 可参数化的帧连接器
    axis_frame_length_adjust.v         : 帧长度调整器
    axis_frame_length_adjust_fifo.v    : 带 FIFO 的帧长度调整器
    axis_ll_bridge.v                   : AXI stream 到 LocalLink 桥
    axis_mux.v                         : 复用器生成器
    axis_pipeline_fifo.v               : 带 FIFO 的 AXI stream 寄存器流水线
    axis_pipeline_register.v           : AXI stream 寄存器流水线
    axis_ram_switch.v                  : AXI stream RAM 开关
    axis_rate_limit.v                  : 小数速率限制器
    axis_register.v                    : AXI Stream 寄存器
    axis_srl_fifo.v                    : 基于 SRL 的 FIFO
    axis_srl_register.v                : 基于 SRL 的寄存器
    axis_switch.v                      : 可参数化的 AXI stream 开关
    axis_stat_counter.v                : 统计计数器
    axis_tap.v                         : AXI stream tap
    ll_axis_bridge.v                   : LocalLink 到 AXI stream 桥
    priority_encoder.v                 : 可参数化的优先级编码器

### AXI Stream 接口示例

两个字节传输，每个字节后接收端暂停

              __    __    __    __    __    __    __    __    __
    clk    __/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__
                    _____ _________________
    tdata  XXXXXXXXX_D0__X_D1______________XXXXXXXXXXXXXXXXXXXXXXXX
                    _____ _________________
    tkeep  XXXXXXXXX_K0__X_K1______________XXXXXXXXXXXXXXXXXXXXXXXX
                    _______________________
    tvalid ________/                       \_______________________
           ______________             _____             ___________
    tready               \___________/     \___________/
                          _________________
    tlast  ______________/                 \_______________________

    tuser  ________________________________________________________


两个背靠背的数据包，无暂停

              __    __    __    __    __    __    __    __    __
    clk    __/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__
                    _____ _____ _____ _____ _____ _____
    tdata  XXXXXXXXX_A0__X_A1__X_A2__X_B0__X_B1__X_B2__XXXXXXXXXXXX
                    _____ _____ _____ _____ _____ _____
    tkeep  XXXXXXXXX_K0__X_K1__X_K2__X_K0__X_K1__X_K2__XXXXXXXXXXXX
                    ___________________________________
    tvalid ________/                                   \___________
           ________________________________________________________
    tready
                                _____             _____
    tlast  ____________________/     \___________/     \___________

    tuser  ________________________________________________________


坏帧

              __    __    __    __    __    __
    clk    __/  \__/  \__/  \__/  \__/  \__/  \__
                    _____ _____ _____
    tdata  XXXXXXXXX_A0__X_A1__X_A2__XXXXXXXXXXXX
                    _____ _____ _____
    tkeep  XXXXXXXXX_K0__X_K1__X_K2__XXXXXXXXXXXX
                    _________________
    tvalid ________/                 \___________
           ______________________________________
    tready
                                _____
    tlast  ____________________/     \___________
                                _____
    tuser  ____________________/     \___________


## 测试

运行附带的测试平台需要 [cocotb](https://github.com/cocotb/cocotb)、[cocotbext-axi](https://github.com/alexforencich/cocotbext-axi) 和 [Icarus Verilog](http://iverilog.icarus.com/)。测试平台可以直接使用 pytest 运行（需要 [cocotb-test](https://github.com/themperek/cocotb-test)），通过 tox 使用 pytest 运行，或通过 cocotb makefiles 运行。
