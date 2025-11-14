# NEORV32 串口终端工具使用说明

## 概述

`terminal.py` 是一个专为 NEORV32 处理器设计的串口调试终端工具。该工具提供了串口通信、交互式终端操作以及 bootloader 自动上传功能，大大简化了 NEORV32 开发和调试过程。

## 主要功能

- **串口通信**: 支持多种波特率和串口参数配置
- **交互式终端**: 提供实时串口数据交互界面
- **Bootloader 自动模式**: 自动检测并上传程序到 NEORV32
- **文件传输**: 支持 NEORV32 exe 格式文件的上传
- **多平台支持**: 兼容 Windows、Linux 和 macOS 系统

## 安装和依赖

### 系统要求

- Python 3.6 或更高版本
- 串口驱动程序（根据您的硬件和操作系统）

### 依赖安装

在使用前，请确保安装了必要的 Python 依赖包：

```bash
pip install pyserial
```

或者在 requirements.txt 文件中添加：
```
pyserial>=3.5
```

然后执行：
```bash
pip install -r requirements.txt
```

## 基本使用方法

### 命令行语法

```bash
python terminal.py [选项]
```

### 命令行参数

| 参数 | 长参数 | 描述 | 默认值 |
|------|--------|------|--------|
| `-p` | `--port` | 串口端口 (如: COM1, /dev/ttyUSB0) | 无 |
| `-b` | `--baudrate` | 波特率 | 115200 |
| `-f` | `--file` | NEORV32 exe文件路径 | 无 |
| `-i` | `--interactive` | 交互模式 | False |
| `-a` | `--auto-interactive` | 发送文件后自动进入交互模式 | False |
| `-h` | `--help` | 显示帮助信息 | - |
| | `--list-ports` | 列出可用串口 | - |

## 使用示例

### 1. 列出可用串口

```bash
python terminal.py --list-ports
```

输出示例：
```
可用串口列表:
  [0] COM3 - USB Serial Port (COM3)
  [1] COM4 - USB Serial Port (COM4)
```

### 2. 交互式终端模式

连接到指定串口并进入交互模式：

```bash
python terminal.py -p COM3 -i
```

或使用完整参数：
```bash
python terminal.py --port COM3 --interactive
```

### 3. 自动上传程序

上传程序到 NEORV32 并自动执行：

```bash
python terminal.py -p COM3 -f program.exe
```

### 4. 上传后进入交互模式

上传程序完成后自动进入交互模式：

```bash
python terminal.py -p COM3 -f program.exe -a
```

### 5. 指定波特率

使用非默认波特率连接：

```bash
python terminal.py -p COM3 -b 9600 -i
```

## 工作模式详解

### 交互模式

交互模式提供了一个实时的串口终端界面，允许您：

- 实时查看从 NEORV32 接收的数据
- 向 NEORV32 发送命令和数据
- 使用 Ctrl+C 退出程序

**启动方式**:
```bash
python terminal.py -p COM3 -i
```

### Bootloader 自动模式

此模式专门用于 NEORV32 程序的自动上传，包括以下步骤：

1. **检测 Bootloader**: 自动检测 NEORV32 bootloader 启动信息
2. **中断自动启动**: 发送空格键中断 bootloader 的自动启动
3. **进入上传模式**: 发送 'u' 命令进入文件上传模式
4. **文件传输**: 自动上传指定的 exe 文件
5. **执行程序**: 发送 'e' 命令执行上传的程序

**启动方式**:
```bash
python scripts/terminal.py -p COM4 -b 19200 -f sw/example/demo_spi_flash/neorv32_exe.bin
```

### 自动交互模式

结合了 bootloader 自动模式和交互模式的优势：

1. 自动完成程序上传
2. 上传成功后自动进入交互模式
3. 可以立即与运行的程序交互

**启动方式**:
```bash
python terminal.py -p COM3 -f program.exe -a
```

## Bootloader 交互流程

当使用 bootloader 模式时，工具会自动执行以下流程：

```
[Bootloader] 启动自动模式，等待bootloader启动信息...
[Bootloader] 请重启MCU或按复位键...
[Bootloader] 超时时间: 30秒

[Bootloader] 检测到bootloader，发送任意键中断自动启动...

[Bootloader] 检测到命令菜单，发送'u'命令上传文件...

[Bootloader] 检测到文件传输请求，开始发送文件: program.exe
发送进度: 100.0% (1024/1024 字节)
文件发送完成!

[Bootloader] 文件发送完成，发送'e'命令执行...
[Bootloader] 自动交互完成!
```

## 故障排除

### 常见问题

#### 1. 找不到串口

**问题**: `未找到可用的串口`

**解决方案**:
- 检查硬件连接是否正确
- 确认串口驱动程序已安装
- 使用 `--list-ports` 参数查看可用串口
- 在 Windows 上检查设备管理器中的串口设备

#### 2. 连接失败

**问题**: `连接失败: [Errno 2] could not open port 'COM3': [Errno 2] No such file or directory (2)`

**解决方案**:
- 确认串口名称正确
- 检查串口是否被其他程序占用
- 尝试以管理员权限运行程序

#### 3. Bootloader 超时

**问题**: `[Bootloader] 超时 (30秒)，请检查连接和MCU状态`

**解决方案**:
- 确认 NEORV32 已正确启动并进入 bootloader 模式
- 检查串口连接和波特率设置
- 重启 MCU 并确保在 bootloader 启动时间内运行工具

#### 4. 文件上传失败

**问题**: `文件发送失败: [错误信息]`

**解决方案**:
- 确认文件路径正确且文件存在
- 检查文件格式是否为 NEORV32 exe 格式
- 尝试降低波特率
- 检查串口连接稳定性

#### 5. 编码问题

**问题**: 接收到的数据显示乱码

**解决方案**:
- 检查波特率设置是否正确
- 确认 NEORV32 的串口配置与工具配置一致
- 检查硬件连接是否稳定

### 调试技巧

1. **使用低波特率**: 如果遇到传输问题，尝试使用较低的波特率（如 9600）
2. **检查硬件**: 确认串口线连接正确，特别是 TX/RX 线路
3. **单独测试**: 先使用交互模式测试基本串口通信
4. **查看日志**: 注意工具输出的状态信息和错误提示

## 高级用法

### 自定义超时时间

可以通过修改 `terminal.py` 中的 `bootloader_timeout` 参数来调整 bootloader 超时时间：

```python
self.bootloader_timeout = 60  # 设置为60秒
```

### 批量操作

可以编写脚本批量处理多个文件：

```bash
#!/bin/bash
for file in *.exe; do
    echo "上传 $file..."
    python terminal.py -p COM3 -f "$file"
    sleep 5
done
```

### 集成到开发流程

可以将工具集成到 Makefile 或其他构建系统中：

```makefile
upload: program.exe
	python terminal.py -p COM3 -f $< -a
```

## 技术细节

### 串口配置

工具使用以下默认串口配置：
- 数据位: 8
- 停止位: 1
- 校验位: 无
- 流控制: 无

### 文件传输协议

文件传输使用简单的二进制流传输，每次发送 1KB 数据块，并在块之间添加小延迟以避免缓冲区溢出。

### 线程安全

工具使用多线程处理串口数据接收，确保实时性和响应性。接收到的数据会被安全地存储在缓冲区中。

## 许可证

本工具遵循项目的整体许可证。

## 贡献

欢迎提交问题报告和功能请求。如果您想贡献代码，请遵循项目的贡献指南。

## 更新日志

### v1.0.0
- 初始版本
- 支持基本串口通信
- 实现 bootloader 自动上传功能
- 添加交互式终端模式