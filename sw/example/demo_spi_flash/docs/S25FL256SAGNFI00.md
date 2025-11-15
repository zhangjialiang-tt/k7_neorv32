---
created: 2025-11-15T09:57
updated: 2025-11-15T13:04
tags:
  - type/datasheet
  - type/doc
---

| 字段    | 值       | 对应含义                                                                                      | 详细解释                                                                                    |
| ----- | ------- | ----------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| S25FL | 128/256 | Device Family (器件家族)                                                                      | S25FL 系列 3-V 串行外设接口 (SPI) 闪存。                                                           |
| 256   | 256     | Density (密度)                                                                              | 存储容量为 256 Mb (兆位)。                                                                      |
| S     | S       | Technology (技术)                                                                           | 采用 65-nm MIRRORBIT™ 工艺技术。                                                               |
| AG    | AG      | Speed (速度)                                                                                | 最大频率为 133 MHz (非 DDR 模式)。                                                               |
| N     | N       | Package Type (封装类型)                                                                       | 8-contact WSON 6 x 8 mm 封装。                                                             |
| F     | F       | Package material (封装材料)                                                                   | Low-Halogen, Lead (Pb)-free (低卤素，无铅) 材料。                                                |
| I     | I       | Temperature range/grade (温度范围/等级)                                                         | Industrial (工业级) 温度范围：-40°C to +85°C。（注：图片中未明确列出 I 对应的工业级，但根据 E（军工级）的格式和行业惯例，I 通常指工业级。） |
| 0     | 0       | Model number (Latency type, package details, $\text{RESET\#}$ and $\text{V\_IO}$ support) | EHPLC, SO/WSON footprint。                                                               |
| 0     | 0       | Model number (sector type) (扇区类型)                                                         | Uniform 64-KB sectors (统一的 64-KB 扇区)。                                                   |
| 0     | 0       | Packing type (包装类型)                                                                       | Tray (托盘) 包装。                                                                           |

## Features

- 容量: 提供128Mb(16MB)-**S25FL128S**和256Mb(32MB)-**S25FL256S** 两种版本。
- 接口: 支持 SPI Multi-I/O，工作电压为 3.0V。
- 架构: 基于 CMOS 3.0-V 核心，具有灵活的 I/O。

### **主要特性 (Features)**

1. **SPI 接口**:
    - 兼容 SPI 协议，支持模式 0 和 3。
    - 支持双倍数据速率 (DDR) 选项。
    - 支持 24 位或 32 位扩展寻址。
    - 命令集和封装与 S25FL-A, S25FL-K, S25FL-P 系列兼容。
2. **读取命令 (READ commands)**:
    - 支持多种高速读取模式：Normal, Fast, Dual, Quad, Fast DDR, Dual DDR, Quad DDR。
    - 内置 **AutoBoot** 功能：上电或复位后，可自动在预设地址执行 Normal 或 Quad 读取命令。
    - 支持通过 **CFI (Common Flash Interface)** 获取配置信息。
3. **编程性能 (Programming)**:
    - 编程速度高达 **1.5 Mbps**。
    - 支持 256 字节或 512 字节页面编程（page programming）。
    - 提供 **QPP (Quad-input page programming)**，适用于低速时钟系统。
    - 内置 **ECC (Error Correction Code)** 硬件，可自动纠正单比特错误。
4. **擦除功能 (Erase)**:
    - 擦除速度为 **0.5 至 0.65 Mbps**。
    - 提供两种扇区结构选项：
        - **混合扇区大小**: 顶部或底部包含 30 个 4-KB 扇区，其余为 64-KB 扇区（兼容旧款 S25FL 设备）。
        - **统一扇区大小**: 所有扇区均为 256-KB 块（软件兼容性更好，适合高密度设备）。
5. **耐久性与数据保持**:
    - **循环寿命**: 100 次编程-擦除周期。
    - **数据保持**: >20 年。
6. **安全特性 (Security features)**:
    - **OTP (One-Time Programmable) 阵列**: 1024 字节，用于存储不可更改的信息。
    - **块保护 (Block protection)**: 通过状态寄存器位控制，防止对连续扇区范围进行编程或擦除。
    - **高级扇区保护 (ASP)**: 可通过引导代码或密码控制单个扇区的保护。

## 性能

### 读写速度

![[assets/Pasted image 20251115100526.png]]

### 擦除速度

![[assets/Pasted image 20251115100615.png]]

## Signal protocols

### spi clock mode

#### SDR

支持两种标准的SPI时钟模式（SDR），由主控制器（如微控制器）驱动。
设备支持以下两种SPI时钟模式：
- **模式 0 (Mode 0):** 时钟极性 `CPOL = 0`，时钟相位 `CPHA = 0`
- **模式 3 (Mode 3):** 时钟极性 `CPOL = 1`，时钟相位 `CPHA = 1`
在**这两种模式下**，数据传输规则是统一的：
- **输入数据 (SI):** 总是在SCK信号的**上升沿**被锁存。
- **输出数据 (SO):** 总是在SCK信号的**下降沿**可用。
两者的核心区别在于**空闲状态**（即总线主控器处于待机模式、不传输数据时）的时钟电平：
- 在 **模式 0** 下，SCK信号保持在**低电平**。
- 在 **模式 3** 下，SCK信号保持在**高电平**。
![[assets/Pasted image 20251115101336.png]]

#### DDR

![[assets/Pasted image 20251115101508.png]]

### Command Protocol

主机系统与 S25FL128S/S25FL256S 闪存设备之间的所有通信都以"命令"（Command）为单位进行。每个命令都包含一个指令（Instruction），用于指定要执行的操作类型。
好的，这是对文档 **4.2 Command Protocol** 部分的全面总结：

#### 命令结构与流程

1.  命令开始与结束：
    -   命令由主机将 片选信号 (CS#) 拉低开始；命令由主机将 CS# 拉高结束；在整个命令执行期间，CS# 必须保持低电平。

2.  时钟同步：
    -   串行时钟 (SCK) 用于标记每一位或每组数据在主机和设备间的传输时刻。

3.  指令 (Instruction)：
    -   每个命令都以一个 8位（1字节）的指令 开始。
    -   指令总是通过 SI 信号以单比特串行方式发送，每个比特在 SCK上升沿 被锁存。
    -   指令决定了后续操作的类型（如读、写、擦除等）和可能使用的地址空间。

4.  地址 (Address)：
    -   指令后可跟地址信息，用于选择设备内部的特定位置。
    -   地址长度可以是 24位 或 32位。
    -   在 SDR 模式下，地址在 SCK上升沿 传输；在 DDR 模式下，在 SCK的上升沿和下降沿 都传输。

5.  数据宽度 (Transfer Width)：
    -   指令决定了后续数据传输的宽度：
        -   单线 (Single I/O, SIO): 使用 SI 和 SO 信号，一次传输1位。
        -   双线 (Dual I/O, DIO): 使用 IO0 和 IO1 信号，一次传输2位（bit pair）。
        -   四线 (Quad I/O, QIO): 使用 IO0-IO3 信号，一次传输4位（nibble）。
    -   位序： 无论是单线还是多线，数据都是 MSB（最高有效位）优先 传输。在多线模式中，最低有效位（LSB）位于IO0，更高位依次放在IO1、IO2、IO3上。

6.  模式位 (Mode Bits)：
    -   某些指令后可跟随"模式位"，用于指示下一个命令将是同类型的，并且省略指令字节。
    -   这样可以节省重复发送相同指令的时间，提高效率。
    -   模式位的传输规则与地址/数据相同（SDR: 上升沿；DDR: 双边沿）。

7.  写入数据 (Write Data)：
    -   写入数据紧跟在地址或模式位之后。
    -   传输规则与地址相同（SDR: 上升沿；DDR: 双边沿）。

8.  读取延迟 (Read Latency / Dummy Cycles)：
    -   在读取命令中，地址后可能会有一段"读取延迟"周期。
    -   在此期间，SCK会持续振荡，但设备不输出有效数据。
    -   延迟结束后，第一个读取数据位会在最后一个延迟周期的SCK下降沿被驱动到输出引脚上。
    -   主机在下一个SCK上升沿认为该数据位已成功接收。
    -   后续数据位在接下来的SCK上升沿（SDR）或每个SCK边沿（DDR）继续传输。

9.  命令终止：
    -   对于读取命令： 设备会持续发送数据，直到主机将 CS# 拉高。主机可以在任意一个数据传输后拉高CS#来提前终止读取。
    -   对于非读取命令（如写入、擦除）： 主机必须在完成所有指令、地址或写入数据的传输后，于 精确的8个SCK周期边界 将CS#拉高。例如，如果传输了1个指令字节（8位）和2个数据字节（16位），则总共有24位，需要24个SCK周期，主机必须在第24个SCK周期结束时拉高CS#。否则，命令会被拒绝执行。

10. 数据组织：
    -   所有数据均按字节传输。
    -   数据传输顺序是从低地址字节到高地址字节（即，最低地址的字节最先发送）。

11. 并发操作限制：
    -   在执行编程、擦除或写入等"嵌入式操作"期间，任何试图读取存储阵列的请求都会被忽略，嵌入式操作会继续执行。
    -   此期间只有极少数特定命令（如查询状态）会被接受。

12. 命令执行时间与状态查询：
    -   不同命令的执行时间不同。
    -   可以通过专门的"读取状态寄存器"命令来查询当前操作是否完成以及是否成功。
![[assets/Pasted image 20251115101958.png]]

## Address space maps

为支持比旧款（legacy）SPI设备更高的存储密度，S25FL128S 和 S25FL256S 引入了 **32位地址**，寻址高达 **4 GB (32 Gb)** 的地址空间。旧款设备仅支持24位地址，最大寻址能力为 16 MB (128 Mb)。

### 启用32位地址的三种方式：

#### 1、Bank 地址寄存器 (Bank Address Register):

这是一个可通过软件（命令）加载的内部寄存器。当使用传统的24位地址时，该寄存器提供地址的高位部分，从而实现对超过16MB空间的访问。
**工作方式：**
    1. **Bank Address Register (BRAC):** 该寄存器是一个**易失性**寄存器，其值决定了当前访问的是哪个16MB的"Bank"。
    2. **地址构成：** 实际的32位地址由两部分组成：
        - **高8位 (Bank Address):** 来自 `BRAC[7:0]`。
        - **低24位 (Offset Address):** 来自命令中提供的3字节地址。
    3. **操作流程：**
        - 主机首先通过 `WRAR` 命令写入 `BRAC`，选择目标Bank。
        - 然后使用任何标准的3字节地址指令（如 `READ`, `PP`, `SE`）访问该银行内的特定位置。

#### 2、扩展地址模式 (Extended Address Mode):

这是Bank地址寄存器中的一个控制位。
当此模式被激活时，所有传统命令都会期望主机提供完整的32位地址，而不是24位。
**工作方式：**
    1. **默认状态 (Power-up):** `EXTADD = 0`，此时所有传统指令（如 `READ`, `PP`, `SE` 等）都使用24位（3字节）地址。
    2. **切换模式:** 主机通过写入 `WRAR` 命令将 `BRAC[7]` 设置为 `1`。
    3. **生效:** 一旦 `EXTADD = 1`，所有列出的传统指令都会自动期望接收一个**4字节地址**，而非3字节。
**优点：** 对现有软件改动最小，只需在初始化时设置一次寄存器位即可。
**主要指令示例：** `READ` (03h), `FAST_READ` (0Bh), `PP` (02h), `SE` (D8h) 等（与方案一中的指令功能相同，但指令码不同）。

#### 3、新命令 (New Commands):

- **核心思想：** 引入一套全新的、专门用于32位寻址的指令集。
- **优点：** 最直接、最清晰，无需依赖任何寄存器配置。
- **适用场景：** 新开发的软件或需要最高性能和明确性的应用。
- **主要指令示例：**
    - **读取类:** `4FAST_READ` (0Ch), `4READ` (13h), `4DOR` (3Ch), `4QOR` (6Ch), `4DIOR` (BCh), `4QIOR` (ECh), `4DDRFR` (0Eh), `4DDRDIOR` (BEh), `4DDRQIOR` (EEh)
    - **写入/擦除类:** `4PP` (12h), `4QPP` (34h), `4P4E` (21h), `4SE` (DCh)

> **注意：** 这些指令的名称通常以数字"4"开头，以区别于旧的3字节指令。

### 默认状态：

设备上电或复位后，默认状态为：
- Bank地址寄存器清零。
- 扩展地址模式设置为 **24位地址**。此设置确保了旧版软件可以无缝访问设备的前128Mb空间。

### Flash memory array

**main flash array**被划分为多个称为"**扇区-sectors**"（扇区是擦除操作的基本单位）。<font color=#F36208>这些扇区的组织方式有两种：一种是 4 KB 和 64 KB 规格的扇区混合排列；另一种则是全部为 256 KB 规格的扇区。</font>具体的扇区组织方式取决于所选择的设备型号，请参阅"订购信息"（Ordering information）以获取详细信息。

#### 扇区组织方式:混合扇区结构 (Hybrid Combination)

- 这是最常见的配置，结合了小扇区和大扇区。
- **底部 (Bottom) 4-KB 扇区:**
    - 包含 **32个** 4KB 大小的扇区（SA00 - SA31）。
    - 地址范围：`0x0000_0000` 至 `0x0001_FFFF`。
    - **用途:** 通常用于存放引导代码、配置参数等需要精细擦除的小数据块。
- **中部 (Middle) 64-KB 扇区:**
    - 包含 **510个** 64KB 大小的扇区（SA32 - SA541）。
    - 地址范围：`0x0002_0000` 至 `0x01FF_FFFF`。
    - **用途:** 用于存储应用程序代码或大量数据，平衡了擦除速度和灵活性。
- **顶部 (Top) 4-KB 扇区:**
    - 包含 **32个** 4KB 大小的扇区（SA510 - SA541）。
    - 地址范围：`0x01FE_0000` 至 `0x01FF_FFFF`。
    - **用途:** 与底部扇区类似，常用于存放关键的启动或安全数据。

#### 统一 256-KB 扇区结构 (Uniform 256-KB Sectors)

- 整个存储空间由 **128个** 256KB 大小的扇区组成（SA00 - SA127）。
- 地址范围：`0x0000_0000` 至 `0x1FFF_FFFF`。
- **用途:** 适用于对擦除粒度要求不高、追求最大擦除效率的应用场景。

#### **关键点总结**

- 擦除单位： 扇区是进行擦除操作的最小单位。**写入操作可以在字节级别进行，但擦除必须按整个扇区执行。**
- 地址映射： 表格清晰地列出了每种扇区大小对应的扇区数量、扇区编号（如SA00, SA32）以及其在内存中的起始和结束字节地址。
- 灵活性： 提供混合扇区和统一扇区两种配置，允许用户根据应用需求（如需要频繁更新的小区域 vs. 大容量程序存储）选择最合适的型号。
- 文档提示： 文档中多次提到"see Ordering information"，这表明具体的扇区布局是在产品订购时确定的，开发者在设计系统时需要确认所选器件的具体型号及其对应的扇区组织。

## Registers

### **核心概念**

寄存器（Registers）是用于配置 S25FL-S 系列闪存设备工作方式或报告其状态的一组小型内存单元。它们不能像主存储阵列那样通过地址直接访问，而是需要通过**特定的命令**（指令码）来读取或写入。

### **寄存器位的类型**

每个寄存器中的位（bit）都有其特定的属性，主要分为以下三类：

1.  **易失性 (Volatile):**
    -   这些位在**上电、硬件复位或软件复位**后会恢复到默认状态。
    -   默认值是在设备出厂时设定的。
    -   例如：`Status Register 1 (SR1)`, `Configuration Register 1 (CR1)`。

2.  **非易失性 (Non-volatile):**
    -   这些位的值在断电后不会丢失，具有与主闪存阵列相同的擦除/编程耐久性。
    -   它们的默认值是设备出厂时的初始值。
    -   例如：`AutoBoot Register (ABRD)`, `Password Register (PASS)`。

3.  **一次性可编程 (OTP - One Time Programmable):**
    -   这些位只能被编程一次，之后无法更改。
    -   通常用于设置永久性的安全或配置选项。
    -   例如：`ASP Register (ASPR[15:1])`。

4.  **保留 (RFU - Reserved for Future Use):**
    -   这些位目前未定义用途，应保持其默认值，不应进行写入操作。
    -   例如：`Status Register 2 (SR2)`。

5.  **只读 (Read only):**
    -   某些寄存器位只能被读取，不能被写入。
    -   例如：`PPB Lock Register (PPBL[0])`。

### **Table 28 寄存器描述摘要**

下表列出了 S25FL-S 设备中主要的寄存器及其关键信息：

| 寄存器名称 | 缩写 | 类型 | 位位置 |
| :--- | :--- | :--- | :--- |
| **状态寄存器 1** | SR1[7:0] | 易失性 | 7:0 |
| **配置寄存器 1** | CR1[7:0] | 易失性 | 7:0 |
| **状态寄存器 2** | SR2[7:0] | RFU (保留) | 7:0 |
| **自动启动寄存器** | ABRD[31:0] | 非易失性 | 31:0 |
| **Bank 地址寄存器** | BRAC[7:0] | 易失性 | 7:0 |
| **ECC 状态寄存器** | ECCSR[7:0] | 易失性 | 7:0 |
| **ASP 寄存器 (高位)** | ASPR[15:1] | OTP | 15:1 |
| **ASP 寄存器 (低位)** | ASPR[0] | RFU (保留) | 0 |
| **密码寄存器** | PASS[63:0] | 非易失性 OTP | 63:0 |
| **PPB 锁定寄存器 (高位)** | PPBL[7:1] | 易失性 | 7:1 |
| **PPB 锁定寄存器 (低位)** | PPBL[0] | 易失性 只读 | 0 |
| **PPB 访问寄存器** | PPBAR[7:0] | 非易失性 | 7:0 |
| **DYB 访问寄存器** | DYBAR[7:0] | 易失性 | 7:0 |
| **SPI DDR 数据学习寄存器 (高位)** | NVDLR[7:0] | 非易失性 | 7:0 |
| **SPI DDR 数据学习寄存器 (低位)** | VDLR[7:0] | 易失性 | 7:0 |

不同的寄存器负责不同的功能，例如：
- `SR1/CR1`: 控制设备行为和报告当前状态（如忙/空闲、写保护等）。
- `BRAC`: 用于扩展地址模式，提供24位地址的高字节。
- `PASS`: 用于安全功能，如密码保护。
- `PPB/DYB`: 用于扇区锁定和保护。
- `NVDLR/VDLR`: 用于优化DDR模式下的数据采样时序。

### 💾 Status Register 1 (SR1) 详解

|**Bits**|**Field name**|**Function**|**Type**|**Default state**|**Description**|
|---|---|---|---|---|---|
|**7**|**SRWD**|Status Register Write Disable|Non-volatile|0|**1** = 锁定 SRWD、BP 和配置寄存器位的状态 (当 $\text{WP\#}$ 为低时)，通过忽略 $\text{WRR}$ 命令。**0** = 无保护，即使 $\text{WP\#}$ 为低。|
|**6**|**P_ERR**|Programming Error Occurred|Volatile, Read only|0|**1** = 发生编程错误。**0** = 未发生错误。|
|**5**|**E_ERR**|Erase Error Occurred|Volatile, Read only|0|**1** = 发生擦除错误。**0** = 未发生错误。|
|**4**|**BP2**|Block Protection|Volatile if $\text{CR1}[3]=1$, Non-volatile if $\text{CR1}[3]=0$|$1$ if $\text{CR1}[3]=1$, $0$ when shipped from Infineon|保护选定范围的扇区 (块) 免受编程或擦除操作。|
|**3**|**BP1**|Block Protection|Volatile if $\text{CR1}[3]=1$, Non-volatile if $\text{CR1}[3]=0$|$1$ if $\text{CR1}[3]=1$, $0$ when shipped from Infineon|保护选定范围的扇区 (块) 免受编程或擦除操作。|
|**2**|**BP0**|Block Protection|Volatile if $\text{CR1}[3]=1$, Non-volatile if $\text{CR1}[3]=0$|$1$ if $\text{CR1}[3]=1$, $0$ when shipped from Infineon|保护选定范围的扇区 (块) 免受编程或擦除操作。|
|**1**|**WEL**|Write Enable Latch|Volatile|0|**1** = 器件接受 $\text{WRR}$、编程或擦除命令。**0** = 器件忽略 $\text{WRR}$、编程或擦除命令。此位不受 $\text{WRR}$ 影响，仅受 $\text{WREN}$ 和 $\text{WRDI}$ 命令影响。|
|**0**|**WIP**|Write in Progress|Volatile, Read only|0|**1** = 器件正忙，正在进行 $\text{WRR}$、编程、擦除或其他操作。**0** = 就绪，器件处于待机模式，可接受命令。|

### ⚙️ Configuration Register 1 (CR1) 详解

|**Bits**|**Field name**|**Function**|**Type**|**Default state**|**Description**|
|---|---|---|---|---|---|
|**7**|**LC1**|Latency Code|Non-volatile|0|选择初始读取**潜伏期周期**的数量。详情请参考**潜伏期代码表**。|
|**6**|**RFU**|RFU|OTP|0|Reserved for Future Use (保留供将来使用)|
|**5**|**TBPROT**|Configures Start of Block Protection|OTP|0|**1** = 块保护 (BP) 从底部 (低地址) 开始。**0** = 块保护 (BP) 从顶部 (高地址) 开始。|
|**4**|**RFU**|RFU|OTP|0|Reserved for Future Use (保留供将来使用)|
|**3**|**BPNV**|Configures BP2-0 in Status Register|OTP|0|**1** = 状态寄存器中的 $\text{BP2-0}$ **可变** (Volatile)。**0** = 状态寄存器中的 $\text{BP2-0}$ **非可变** (Non-volatile)。|
|**2**|**TBPARM**|Configures Parameter Sectors location|OTP|0|**1** = 4 KB 物理扇区位于**顶部 (高地址)**。**0** = 4 KB 物理扇区位于**底部 (低地址)**。在统一扇区设备中为 RFU。|
|**1**|**QUAD**|Puts the device into Quad I/O operation|Non-volatile|0|**1** = **四线 I/O** (Quad) 操作。**0** = **双线或串行** (Dual or Serial) 操作。|
|**0**|**FREEZE**|Lock current state of BP2-0 bits in Status Register, TBPROT and TBPARM in Configuration Register, and OTP regions|Volatile|0|**1** = **锁定**块保护 ($\text{BP2-0}$) 和 OTP 区域的当前状态。**0** = **解锁**块保护和 OTP 区域。|

### 🏦 Bank Address Register (BAR) 详解

|**Bits**|**Field name**|**Function**|**Type**|**Default state**|**Description**|
|---|---|---|---|---|---|
|**7**|**EXTADD**|Extended Address Enable|Volatile|0 b|**1** = 命令需要使用 **4 字节 (32 位) 地址**。**0** = 命令使用 **3 字节 (24 位) 地址** $\text{+}$ **Bank 地址**。|
|**6 to 2**|**RFU**|Reserved|Volatile|00000 b|Reserved for Future Use (保留供将来使用)。|
|**1**|**BA25**|Bank Address|Volatile|0|Bank 地址位 $\text{A25}$。对于低密度器件为 RFU。|
|**0**|**BA24**|Bank Address|Volatile|0|Bank 地址位 $\text{A24}$。对于 256-Mb 器件为 $\text{A24}$，对于低密度器件为 RFU。|

## Data protection

### 10.2 写使能命令 (Write Enable Command)

这是一个至关重要的安全前置步骤。

-   **必要性：**
    -   在执行任何会修改非易失性数据的命令（如编程、擦除、写入寄存器等）之前，**必须先执行 `WREN` 命令**。
    -   `WREN` 命令会设置状态寄存器1 (SR1) 中的 **写使能锁存位 (WEL)**。
-   **WEL位的清除：**
    -   WEL位会在以下情况下被自动清零（即禁止写入）：
        1.  上电 (Power-up)
        2.  硬件复位 (Hardware Reset)
        3.  执行完以下命令后：
            -   `Reset`
            -   `Page Program (PP)`
            -   `Sector Erase (SE)`
            -   `Bulk Erase (BE)`
            -   `Write Disable (WRDI)`
            -   `Write Registers (WRR)`
            -   `Quad-input Page Programming (QPP)`
            -   `OTP Byte Programming (OTPP)`

## Command

### Command Table summary

| **Instruction (Hex)** | **Command name** | **Command description**                                                 | **Maximum frequency (MHz)** |
| --------------------- | ---------------- | ----------------------------------------------------------------------- | --------------------------- |
| **01**                | WRR              | Write Register (Status-1, Configuration-1)                              | 133                         |
| **02**                | PP               | Page Program (3or 4-byte address)                                       | 133                         |
| **03**                | READ             | Read (3or 4-byte address)                                               | 50                          |
| **04**                | WRDI             | Write Disable                                                           | 133                         |
| **05**                | RDSR1            | Read Status Register-1                                                  | 133                         |
| **06**                | WREN             | Write Enable                                                            | 133                         |
| **07**                | RDSR2            | Read Status Register-2                                                  | 133                         |
| **0B**                | FAST_READ        | Fast Read (3or 4-byte address)                                          | 133                         |
| **0C**                | 4FAST_READ       | Fast Read (4-byte address)                                              | 133                         |
| **0D**                | DDRFR            | DDR Fast Read (3or 4-byte address)                                      | 80                          |
| **0E**                | 4DDRFR           | DDR Fast Read (4-byte address)                                          | 80                          |
| **12**                | 4PP              | Page Program (4-byte address)                                           | 133                         |
| **13**                | 4READ            | Read (4-byte address)                                                   | 50                          |
| **14**                | ABRD             | AutoBoot Register Read                                                  | 133                         |
| **15**                | ABWR             | AutoBoot Register Write                                                 | 133                         |
| **16**                | BRRD             | Bank Register Read                                                      | 133                         |
| **17**                | BRWR             | Bank Register Write                                                     | 133                         |
| **18**                | ECCRD            | ECC Read                                                                | 133                         |
| **20**                | P4E              | Parameter 4 KB-sector Erase (3or 4-byte address)                        | 133                         |
| **21**                | 4P4E             | Parameter 4 KB-sector Erase (4-byte address)                            | 133                         |
| **2B**                | ASPRD            | ASP Read                                                                | 133                         |
| **2F**                | ASPP             | ASP Program                                                             | 133                         |
| **30**                | CLSR             | Clear Status Register - Erase/Program Fail Reset                        | 133                         |
| **32**                | QPP              | Quad Page Program (3or 4-byte address)                                  | 80                          |
| **34**                | 4QPP             | Quad Page Program (4-byte address)                                      | 80                          |
| **35**                | RDCR             | Read Configuration Register-1                                           | 133                         |
| **38**                | QPP              | Quad Page Program (3or 4-byte address)                                  | 80                          |
| **3B**                | DOR              | Read Dual Out (3or 4-byte address)                                      | 104                         |
| **3C**                | 4DOR             | Read Dual Out (4-byte address)                                          | 104                         |
| **41**                | DLPRD            | Data Learning Pattern Read                                              | 133                         |
| **42**                | OTPP             | OTP Program                                                             | 133                         |
| **43**                | PNVDLR           | Program NV Data Learning Register                                       | 133                         |
| **4A**                | WVDLR            | Write Volatile Data Learning Register                                   | 133                         |
| **4B**                | OTPR             | OTP Read                                                                | 133                         |
| **60**                | BE               | Bulk Erase                                                              | 133                         |
| **6B**                | QOR              | Read Quad Out (3or 4-byte address)                                      | 104                         |
| **6C**                | 4QOR             | Read Quad Out (4-byte address)                                          | 104                         |
| **75**                | ERSP             | Erase Suspend                                                           | 133                         |
| **7A**                | ERRS             | Erase Resume                                                            | 133                         |
| **85**                | PGSP             | Program Suspend                                                         | 133                         |
| **8A**                | PGRS             | Program Resume                                                          | 133                         |
| **90**                | READ_ID (REMS)   | Read Electronic Manufacturer Signature                                  | 133                         |
| **9F**                | RDID             | Read ID (JEDEC Manufacturer ID and JEDEC CFI)                           | 133                         |
| **A3**                | MPM              | Reserved for Multi-I/O-High Perf Mode (MPM)                             | 133                         |
| **A6**                | PLBWR            | PPB Lock Bit Write                                                      | 133                         |
| **A7**                | PLBRD            | PPB Lock Bit Read                                                       | 133                         |
| **AB**                | RES              | Read Electronic Signature                                               | 50                          |
| **B9**                | BRAC             | Bank Register Access (Legacy Command formerly used for Deep Power Down) | 133                         |
| **BB**                | DIOR             | Dual I/O Read (3or 4-byte address)                                      | 104                         |
| **BC**                | 4DIOR            | Dual I/O Read (4-byte address)                                          | 104                         |
| **BD**                | DDRDIOR          | DDR Dual I/O Read (3or 4-byte address)                                  | 80                          |
| **BE**                | 4DDRDIOR         | DDR Dual I/O Read (4-byte address)                                      | 80                          |
| **C7**                | BE               | Bulk Erase (alternate command)                                          | 133                         |
| **D8**                | SE               | Erase 64 KB or 256 KB (3or 4-byte address)                              | 133                         |
| **DC**                | 4SE              | Erase 64 KB or 256 KB (4-byte address)                                  | 133                         |
| **E0**                | DYBRD            | DYB Read                                                                | 133                         |
| **E1**                | DYBWR            | DYB Write                                                               | 133                         |
| **E2**                | PPBRD            | PPB Read                                                                | 133                         |
| **E3**                | PPBP             | PPB Program                                                             | 133                         |
| **E4**                | PPBE             | PPB Erase                                                               | 133                         |
| **E5**                | Reserved-E5      | Reserved                                                                |                             |
| **E6**                | Reserved-E6      | Reserved                                                                |                             |
| **E7**                | PASSRD           | Password Read                                                           | 133                         |
| **E8**                | PASSP            | Password Program                                                        | 133                         |
| **E9**                | PASSU            | Password Unlock                                                         | 133                         |
| **EB**                | QIOR             | Quad I/O Read (3or 4-byte address)                                      | 104                         |
| **EC**                | 4QIOR            | Quad I/O Read (4-byte address)                                          | 104                         |
| **ED**                | DDRQIOR          | DDR Quad I/O Read (3or 4-byte address)                                  | 80                          |
| **EE**                | 4DDRQIOR         | DDR Quad I/O Read (4-byte address)                                      | 80                          |
| **F0**                | RESET            | Software Reset                                                          | 133                         |
| **FF**                | MBR              | Mode Bit Reset                                                          | 133                         |
|                       |                  |                                                                         |                             |

### Command Table(按功能分组)

| **Function**                   | **Command name**        | **Command description**                                                 | **Instruction value (Hex)** | **Maximum frequency (MHz)**                 |
| ------------------------------ | ----------------------- | ----------------------------------------------------------------------- | --------------------------- | ------------------------------------------- |
| **Read Device Identification** | READ_ID ($\text{REMS}$) | Read Electronic Manufacturer Signature                                  | **90**                      | 133                                         |
|                                | RDID                    | Read ID (JEDEC Manufacturer ID and JEDEC CFI)                           | **9F**                      | 133                                         |
|                                | RES                     | Read Electronic Signature                                               | **AB**                      | 50                                          |
| **Register Access**            | RDSR1                   | Read Status Register-1                                                  | **05**                      | 133                                         |
|                                | RDSR2                   | Read Status Register-2                                                  | **07**                      | 133                                         |
|                                | RDCR                    | Read Configuration Register-1                                           | **35**                      | 133                                         |
|                                | WRR                     | Write Register (Status-1, Configuration-1)                              | **01**                      | 133                                         |
|                                | WRDI                    | Write Disable                                                           | **04**                      | 133                                         |
|                                | WREN                    | Write Enable                                                            | **06**                      | 133                                         |
|                                | CLSR                    | Clear Status Register-1 - Erase/Prog. Fail Reset                        | **30**                      | 133                                         |
|                                | ECCRD                   | ECC Read (4-byte address)                                               | **18**                      | 133                                         |
|                                | ABRD                    | AutoBoot Register Read                                                  | **14**                      | 133 ($\text{QUAD}=0$)/104 ($\text{QUAD}=1$) |
|                                | ABWR                    | AutoBoot Register Write                                                 | **15**                      | 133                                         |
|                                | BRRD                    | Bank Register Read                                                      | **16**                      | 133                                         |
|                                | BRWR                    | Bank Register Write                                                     | **17**                      | 133                                         |
|                                | BRAC                    | Bank Register Access (Legacy Command formerly used for Deep Power Down) | **B9**                      | 133                                         |
|                                | DLPRD                   | Data Learning Pattern Read                                              | **41**                      | 133                                         |
|                                | PNVDLR                  | Program NV Data Learning Register                                       | **43**                      | 133                                         |
|                                | WVDLR                   | Write Volatile Data Learning Register                                   | **4A**                      | 133                                         |
| **Read Flash Array**           | READ                    | Read (3or 4-byte address)                                               | **03**                      | 50                                          |
|                                | 4READ                   | Read (4-byte address)                                                   | **13**                      | 50                                          |
|                                | FAST_READ               | Fast Read (3or 4-byte address)                                          | **0B**                      | 133                                         |
|                                | 4FAST_READ              | Fast Read (4-byte address)                                              | **0C**                      | 133                                         |
|                                | DDRFR                   | DDR Fast Read (3or 4-byte address)                                      | **0D**                      | 80                                          |
|                                | 4DDRFR                  | DDR Fast Read (4-byte address)                                          | **0E**                      | 80                                          |
|                                | DOR                     | Read Dual Out (3or 4-byte address)                                      | **3B**                      | 104                                         |
|                                | 4DOR                    | Read Dual Out (4-byte address)                                          | **3C**                      | 104                                         |
|                                | QOR                     | Read Quad Out (3or 4-byte address)                                      | **6B**                      | 104                                         |
|                                | 4QOR                    | Read Quad Out (4-byte address)                                          | **6C**                      | 104                                         |
|                                | DIOR                    | Dual I/O Read (3or 4-byte address)                                      | **BB**                      | 104                                         |
|                                | 4DIOR                   | Dual I/O Read (4-byte address)                                          | **BC**                      | 104                                         |
|                                | DDRDIOR                 | DDR Dual I/O Read (3or 4-byte address)                                  | **BD**                      | 80                                          |
|                                | 4DDRDIOR                | DDR Dual I/O Read (4-byte address)                                      | **BE**                      | 80                                          |
|                                | QIOR                    | Quad I/O Read (3or 4-byte address)                                      | **EB**                      | 104                                         |
|                                | 4QIOR                   | Quad I/O Read (4-byte address)                                          | **EC**                      | 104                                         |
|                                | DDRQIOR                 | DDR Quad I/O Read (3or 4-byte address)                                  | **ED**                      | 80                                          |
|                                | 4DDRQIOR                | DDR Quad I/O Read (4-byte address)                                      | **EE**                      | 80                                          |
| **Program Flash Array**        | PP                      | Page Program (3or 4-byte address)                                       | **02**                      | 133                                         |
|                                | 4PP                     | Page Program (4-byte address)                                           | **12**                      | 133                                         |
|                                | QPP                     | Quad Page Program (3or 4-byte address)                                  | **32**                      | 80                                          |
|                                | QPP                     | Quad Page Program - Alternate instruction (3or 4-byte address)          | **38**                      | 80                                          |
|                                | 4QPP                    | Quad Page Program (4-byte address)                                      | **34**                      | 80                                          |
|                                | PGSP                    | Program Suspend                                                         | **85**                      | 133                                         |
|                                | PGRS                    | Program Resume                                                          | **8A**                      | 133                                         |
| **Erase Flash Array**          | P4E                     | Parameter 4-KB, sector Erase (3or 4-byte address)                       | **20**                      | 133                                         |
|                                | 4P4E                    | Parameter 4-KB, sector Erase (4-byte address)                           | **21**                      | 133                                         |
|                                | BE                      | Bulk Erase                                                              | **60**                      | 133                                         |
|                                | BE                      | Bulk Erase (alternate command)                                          | **C7**                      | 133                                         |
|                                | SE                      | Erase 64 KB or 256 KB (3or 4-byte address)                              | **D8**                      | 133                                         |
|                                | 4SE                     | Erase 64 KB or 256 KB (4-byte address)                                  | **DC**                      | 133                                         |
|                                | ERSP                    | Erase Suspend                                                           | **75**                      | 133                                         |
|                                | ERRS                    | Erase Resume                                                            | **7A**                      | 133                                         |
| **One Time Program Array**     | OTPP                    | OTP Program                                                             | **42**                      | 133                                         |
|                                | OTPR                    | OTP Read                                                                | **4B**                      | 133                                         |
| **Advanced Sector Protection** | DYBRD                   | DYB Read                                                                | **E0**                      | 133                                         |
|                                | DYBWR                   | DYB Write                                                               | **E1**                      | 133                                         |
|                                | PPBRD                   | PPB Read                                                                | **E2**                      | 133                                         |
|                                | PPBP                    | PPB Program                                                             | **E3**                      | 133                                         |
|                                | PPBE                    | PPB Erase                                                               | **E4**                      | 133                                         |
|                                | ASPRD                   | ASP Read                                                                | **2B**                      | 133                                         |
|                                | ASPP                    | ASP Program                                                             | **2F**                      | 133                                         |
|                                | PLBRD                   | PPB Lock Bit Read                                                       | **A7**                      | 133                                         |
|                                | PLBWR                   | PPB Lock Bit Write                                                      | **A6**                      | 133                                         |
|                                | PASSRD                  | Password Read                                                           | **E7**                      | 133                                         |
|                                | PASSP                   | Password Program                                                        | **E8**                      | 133                                         |
|                                | PASSU                   | Password Unlock                                                         | **E9**                      | 133                                         |
| **Reset**                      | RESET                   | Software Reset                                                          | **F0**                      | 133                                         |
|                                | MBR                     | Mode Bit Reset                                                          | **FF**                      | 133                                         |
| **Reserved for Future Use**    | MPM                     | Reserved for Multi-I/O-High Perf Mode (MPM)                             | **A3**                      | 133                                         |
|                                | RFU (Reserved-18)       | Reserved                                                                | **18**                      |                                             |
|                                | RFU (Reserved-E5)       | Reserved                                                                | **E5**                      |                                             |
|                                | RFU (Reserved-E6)       | Reserved                                                                | **E6**                      |                                             |

### 分类

#### 支持 4 字节地址的新型指令集

这些指令通过使用 4 字节地址（而非传统的 3 字节地址）来寻址超过 128 Mb (16 MB) 的存储空间，最高可达 32 Gb。

| **Instruction name** | **Description**                       | **Code (Hex)** |
| -------------------- | ------------------------------------- | -------------- |
| **4FAST_READ**       | Read Fast (4-byte address)            | **0C**         |
| **4READ**            | Read (4-byte address)                 | **13**         |
| **4DOR**             | Read Dual Out (4-byte address)        | **3C**         |
| **4QOR**             | Read Quad Out (4-byte address)        | **6C**         |
| **4DIOR**            | Dual I/O Read (4-byte address)        | **BC**         |
| **4QIOR**            | Quad I/O Read (4-byte address)        | **EC**         |
| **4DDRFR**           | Read DDR Fast (4-byte address)        | **0E**         |
| **4DDRDIOR**         | DDR Dual I/O Read (4-byte address)    | **BE**         |
| **4DDRQIOR**         | DDR Quad I/O Read (4-byte address)    | **EE**         |
| **4PP**              | Page Program (4-byte address)         | **12**         |
| **4QPP**             | Quad Page Program (4-byte address)    | **34**         |
| **4P4E**             | Parameter 4-KB Erase (4-byte address) | **21**         |
| **4SE**              | Erase 64/256 KB (4-byte address)      | **DC**         |

#### 兼容 4 字节地址的传统指令集

这些指令**默认**使用 **3 字节 (24 位) 地址**。当 Bank Address Register 的 $\text{EXTADD}$ 位 (**$\text{BAR[7]}$**) 被设置为 **'1'** 时，这些指令将要求 **4 字节 (32 位) 地址**，以实现向后兼容性，并允许访问更大的存储空间。

|**Instruction name**|**Description**|**Code (Hex)**|
|---|---|---|
|**READ**|Read (3-byte address)|**03**|
|**FAST_READ**|Read Fast (3-byte address)|**0B**|
|**DOR**|Read Dual Out (3-byte address)|**3B**|
|**QOR**|Read Quad Out (3-byte address)|**6B**|
|**DIOR**|Dual I/O Read (3-byte address)|**BB**|
|**QIOR**|Quad I/O Read (3-byte address)|**EB**|
|**DDRFR**|Read DDR Fast (3-byte address)|**0D**|
|**DDRDIOR**|DDR Dual I/O Read (3-byte address)|**BD**|
|**DDRQIOR**|DDR Quad I/O Read (3-byte address)|**ED**|
|**PP**|Page Program (3-byte address)|**02**|
|**QPP**|Quad Page Program (3-byte address)|**32**|
|**P4E**|Parameter 4-KB Erase (3-byte address)|**20**|
|**SE**|Erase 64/256 KB (3-byte address)|**D8**|

#### EXTADD 位如何实现兼容性

这个机制的核心在于 **Bank Address Register** 的第 7 位 **$\text{EXTADD}$**：

- **默认状态 ($\text{BAR[7]} = 0$):**
    - 上电或硬件复位后，$\text{BAR[7]}$ 默认为 **'0'**。
    - 此时，上述所有传统指令只接收 **3 字节 (24 位) 地址**。
- **扩展地址状态 ($\text{BAR[7]} = 1$):**
    - 当 $\text{BAR[7]}$ 通过 $\text{BRWR}$ 等命令设置为 **'1'** 时。
    - 上述所有相同的传统指令将**自动要求 4 字节 (32 位) 地址**，从而允许使用相同的指令代码访问大于 16 MB 的存储空间。

这个设计确保了软件可以复用现有的指令代码，而无需切换到带有 '4' 前缀的新指令 (如 $\text{4READ}$)，仅需修改 $\text{BAR[7]}$ 寄存器位即可切换寻址模式。

### Command格式

主机与 S25FL128S/S25FL256S 设备之间的所有通信都以"命令"（Command）为基本单位。每个命令都是一个结构化的数据包，包含指令、地址、数据和控制信息，通过串行接口进行传输。

#### **命令的基本结构**

1.  **起始：**
    -   每个命令都以一个 **8位（1字节）的指令码 (Instruction)** 开始。
    -   主机在发送第一个SCK上升沿前，必须先将 **片选信号 (CS#) 拉低** 以选中设备。
    -   CS# 在整个命令执行期间保持低电平，命令结束时拉高。

2.  **内容组成：**
    -   **指令 (Instruction):** 决定命令类型（如读、写、擦除、配置等）。
    -   **地址 (Address):** 可选，用于指定操作的目标位置。地址可以是24位或32位。
    -   **模式位 (Mode Bits):** 可选，用于指示下一个命令是同一类型的"隐式指令"，从而省略重复发送指令字节，提高效率。
    -   **数据 (Data):** 可选，用于写入设备或从设备读取。
    -   **延迟周期 (Latency / Dummy Cycles):** 在读取命令中，地址后可能有一段等待时间，用于内部准备数据。

3.  **数据传输宽度：**
    -   传输宽度由指令决定，支持三种模式：
        -   **单线 (Single I/O, SIO):** 使用 SI 和 SO 信号，一次传输1位。
        -   **双线 (Dual I/O, DIO):** 使用 IO0 和 IO1 信号，一次传输2位。
        -   **四线 (Quad I/O, QIO):** 使用 IO0-IO3 信号，一次传输4位。
    -   **目的:** 在引脚数量（成本）和数据传输速度之间取得平衡。更宽的总线能显著提升性能。

4.  **数据格式与顺序：**
    -   所有数据（指令、地址、模式位、数据）均按**字节**传输。
    -   **位序：** 无论是单线还是多线，数据总是 **MSB（最高有效位）优先** 传输。
    -   **字节序：**
        -   地址：**MSB（最高有效字节）优先**。
        -   数据：**LSB（最低有效字节）优先**，即从低地址字节开始发送，然后依次递增到高地址字节。

#### **关键操作规则**

1.  **并发操作限制：**
    -   在执行编程、擦除或写入等"嵌入式操作"期间，任何试图读取主存储阵列的请求都会被**忽略**。
    -   此期间只有极少数特定命令（如查询状态寄存器）会被接受。
    -   **最佳实践：** 在发送新命令前，应先检查状态寄存器中的 **WIP (Write-In Progress) 位** 是否为 `0`，以确保设备已准备好接收新命令。

2.  **命令执行时间：**
    -   不同命令的执行时间不同。
    -   可通过专门的"读取状态"命令来监控当前操作的进度和结果。

3.  **CS# 释放时机：**
    -   对于不返回数据的命令（如写入），主机必须在完成所有数据传输后，在**精确的8个SCK周期倍数**处将CS#拉高。例如，如果传输了1个指令字节和2个数据字节，则需要24个SCK周期，必须在第24个周期结束时释放CS#。否则，命令会被拒绝执行。

#### 监控操作状态 (Monitoring operation status)

-   **核心机制：** 主机通过监控 **状态寄存器1 (SR1)** 中的 **WIP (Write in Progress) 位** 来判断编程、擦除等嵌入式操作是否完成。
-   **错误指示：**
    -   `P_ERR` 位：指示最近一次编程操作失败。
    -   `E_ERR` 位：指示最近一次擦除操作失败。
    -   当 `P_ERR` 或 `E_ERR` 为 `1` 时，`WIP` 位也会保持为 `1`，表示设备仍处于忙状态。
-   **异常处理：**
    -   在出现错误或设备忙碌时，**仅允许** 发送以下命令：
        -   `CLSR` (Clear Status Register)
        -   `WRDI` (Write Disable)
        -   `RDSR1`, `RDSR2` (Read Status Register)
        -   `RESET` (Software Reset)
    -   **恢复到待机状态的方法：**
        1.  发送 `CLSR` 命令：清除 `WIP`, `P_ERR`, `E_ERR` 位。
        2.  紧接着发送 `WRDI` 命令：清除 `WEL` (Write Enable Latch) 位。
    -   或者，直接发送 **硬件复位 (Hardware Reset)** 或 **软件复位 (RESET)** 命令来强制设备回到默认待机状态。

### 读取芯片ID Command

| 命令 | 指令码 | 功能 | 推荐度 | 关键特点 |
| :--- | :--- | :--- | :--- | :--- |
| **REMS (Read_ID)** | `90h` | 读取制造商ID和设备ID | ❌ 不推荐 (旧版) | 需要发送地址，支持地址切换读取，速度较快 (133MHz) |
| **RDID** | `9Fh` | 读取制造商ID、设备ID及完整的CFI信息 | ✅ **强烈推荐** | 无需地址，数据最全面，支持标准化驱动，是行业标准 |
| **RES** | `ABh` | 读取单字节电子签名 | ❌ 不推荐 (旧版) | 需要发送3个虚拟字节，速度慢 (50MHz)，功能单一 |

#### 读取标识 (RDID, 指令码 9Fh)**

-   **功能：** 提供最全面的身份和功能信息，包括：
    -   制造商ID (JEDEC分配)
    -   设备ID (Infineon分配)
    -   **CFI (Common Flash Interface) 信息** (Infineon分配)
-   **状态：** **强烈推荐用于所有新软件设计**。
-   **重要性与优势：**
    -   **标准化：** CFI 是 JEDEC 标准，定义了一个统一的设备信息结构。
    -   **设备无关性：** 软件驱动程序可以基于 CFI 信息进行配置，从而实现"一次编写，多设备通用"。
    -   **长期兼容性：** 系统厂商可以标准化其闪存驱动，确保未来产品与现有软件的长期兼容性。
-   **操作流程：**
    1.  主机通过 `SI` 发送指令码 `9Fh`。
    2.  无需发送地址或任何额外字节。
    3.  设备随后通过 `SO` 依次输出完整的 **ID-CFI** 数据块（包含制造商ID、设备ID、扩展设备ID和CFI信息），**MSB优先**。
-   **并发操作：** 在执行编程、擦除或写入操作期间，任何 `RDID` 命令都会被忽略，不会影响正在进行的操作。
![[assets/Pasted image 20251115113627.png]]

### 寄存器访问 Command

#### 11.3.1 - 11.3.4: 寄存器读取命令 (Read Commands)

这些命令允许主机在任何时刻（包括编程/擦除操作期间）读取寄存器内容，以监控设备状态或获取配置信息。

-   **RDSR1 (05h) - 读取状态寄存器1：**
    -   读取 `SR1`，包含关键的状态位如 `WIP` (写入中), `P_ERR` (编程错误), `E_ERR` (擦除错误)。
    -   最大频率：**133 MHz**。
    -   可通过连续提供8个SCK周期来持续读取。
-   **RDSR2 (07h) - 读取状态寄存器2：**
    -   读取 `SR2`，目前为保留位 (RFU)。
    -   最大频率：**133 MHz**。
    -   同样支持连续读取。
-   **RDCR (35h) - 读取配置寄存器：**
    -   读取 `CR1`，用于配置接口宽度、时序等。
    -   支持在任何状态下读取，包括嵌入式操作期间。
    -   支持连续读取。
-   **BRRD (16h) - 读取Bank地址寄存器：**
    -   读取 `BRAC` 的内容，该寄存器用于管理超过128Mb地址空间的访问。
    -   最大频率：**133 MHz**。
    -   支持连续读取。

#### 11.3.5 & 11.3.6: Bank地址寄存器写入命令 (Write to Bank Address Register)

这两条命令提供了两种方式来写入 `BRAC`，其中一条是为了兼容旧系统而设计的"技巧"。

-   **BRWR (17h) - 直接写入Bank地址寄存器：**
    -   **功能：** 直接写入 `BRAC`，用于设置高地址位或 `EXTADD` 位 (BAR[7])。
    -   **特点：**
        -   **无需 WREN！** 因为它不修改主闪存数据，所以不需要先执行 `WREN` 命令。
        -   写入一个字节的数据。
        -   不影响 `P_ERR`, `E_ERR`, `WIP` 等状态位。
        -   保留位应写为 `0`。
-   **BRAC (B9h) + WRR (01h) - 兼容性写入方案：**
    -   **背景：** 为了让不支持新命令（如 `BRWR`）的旧版SPI控制器也能访问 `BRAC`，Infineon 将 `BRAC` 命令码 `B9h` 赋予了旧的 `DPD` (Deep Power Down) 指令码。
    -   **操作流程：**
        1.  主机发送 `BRAC` (`B9h`) 命令。
        2.  紧接着发送 `WRR` (`01h`) 命令（**注意：中间不能插入 `WREN`**）。
        3.  `WRR` 命令后跟随的数据字节，其**低2位**会被写入 `BRAC[1:0]`，其余位被忽略。
        4.  完成后，设备自动关闭对 `BRAC` 的访问，返回待机状态。
    -   **限制：**
        -   此序列只能在设备处于**待机、程序挂起或擦除挂起**状态时使用。
        -   不能在执行嵌入式算法或 `P_ERR`/`E_ERR` 为 `1` 时使用。
        -   此序列**不影响** `EXTADD` 位 (BAR[7])。
        -   如果在 `BRAC` 后发送了其他命令或 `CS#` 被拉高，访问会立即关闭，后续的 `WRR` 将恢复其默认功能（写入 `SR1` 和 `CR1`）。

#### 11.3.7: 写入寄存器 (WRR, 01h)

这是最核心的配置命令，用于同时写入 `SR1` 和 `CR1`。

-   **前提条件：** **必须先执行 `WREN` 命令**，将 `WEL` 位设为 `1`。
-   **操作流程：**
    1.  发送指令码 `01h`。
    2.  发送一个或两个数据字节：
        -   发送**第一个字节**：仅写入 `SR1`。
        -   发送**两个字节**：第一个字节写入 `SR1`，第二个字节写入 `CR1`。
        -   **例外：** 如果 `CR1[1]` (QUAD bit) 为 `1`，则必须发送两个字节。
    3.  必须在第8位或第16位数据锁存后，立即将 `CS#` 拉高，否则命令无效。
-   **执行过程：**
    -   命令发出后，设备启动自定时写入操作。
    -   在此期间，可以通过 `RDSR1` 读取 `WIP` 位来监控进度。
    -   写入完成后，`WEL` 位会自动清零。
-   **错误处理：** 写入失败会导致 `P_ERR` 或 `E_ERR` 位被置位。
-   **最大频率：** **133 MHz**。
-   **保留位：** 所有保留位都必须写为 `0`。

#### 11.3.8: 写使能 (WREN, 06h)

-   **功能：** 设置 `SR1[1]` (WEL) 位为 `1`，授权后续的写入、编程和擦除操作。
-   **必要性：** 几乎所有修改非易失性数据的命令（`PP`, `SE`, `BE`, `WRR`, `OTPP` 等）都必须在 `WREN` 之后执行。
-   **操作：** 发送指令码 `06h`，并在第8位数据锁存后立即拉高 `CS#`。
-   **清除时机：** `WEL` 位会在上电、复位、执行完写入/擦除命令或 `WRDI` 命令后自动清零。

#### 11.3.9: 写禁用 (WRDI, 04h)

-   **功能：** 将 `SR1[1]` (WEL) 位清零，禁止所有需要写使能的操作。
-   **用途：** 作为安全机制，防止意外写入或擦除，保护内存内容。
-   **操作：** 发送指令码 `04h`，并在第8位数据锁存后立即拉高 `CS#`。
-   **限制：** 在嵌入式操作期间（`WIP=1`），`WRDI` 命令会被忽略。

#### 11.3.10: 清除状态寄存器 (CLSR, 30h)

-   **功能：** 清除 `SR1[5]` (Erase Fail Flag) 和 `SR1[6]` (Program Fail Flag)。
-   **特点：**
    -   **无需 WREN！** 即使设备处于忙碌状态（`WIP=1`），只要是因为错误标志导致的忙碌，该命令依然有效。
    -   执行后，`WEL` 位保持不变。
-   **用途：** 在发生编程或擦除错误后，用于清除错误标志，以便进行后续操作。

#### **总结**

寄存器访问是控制 S25FL-S 设备的灵魂。理解并熟练运用这些命令至关重要：

1.  **状态监控：** `RDSR1`, `RDSR2`, `RDCR` 是实时了解设备运行状况的窗口。
2.  **安全与保护：** `WREN` 和 `WRDI` 是操作权限的开关；`CLSR` 是错误恢复的关键；`SRWD` 和 `WP#` 结合可实现硬件级保护。
3.  **高级功能：** `BRWR` 和 `BRAC+WRR` 提供了灵活的地址空间管理能力。
4.  **配置中心：** `WRR` 是唯一能同时修改 `SR1` 和 `CR1` 的命令，是实现性能调优和功能配置的核心。

开发者必须严格遵守各命令的前置条件（如 `WREN`）、时序要求（如 `CS#` 释放时机）和限制条件（如并发操作），才能确保系统的稳定性和可靠性。

### Read memory array commands

#### **地址空间管理**

由于设备容量可能超过128Mb，传统的3字节地址无法覆盖全部空间，因此提供了两种解决方案：

1.  **Bank地址寄存器 (BRAC):**
    -   通过 `BRWR` 或 `BRAC+WRR` 命令设置 `BRAC` 寄存器。
    -   `BRAC` 提供高8位地址，与主机发送的3字节地址组合成完整的32位地址。
    -   默认值为 Bank 0。

2.  **扩展地址模式 (EXTADD Bit):**
    -   将 `BRAC[7]` 设置为 `1`。
    -   此后，所有传统的3字节地址指令（如 `READ`, `FAST_READ`）都会自动期望接收一个4字节地址。
    -   对于 S25FL128S 设备，由于其容量仅为128Mb，高地址位会被忽略。

#### **操作注意事项**

-   **命令终止：** 任何读取命令都可以在数据传输过程中的任意时刻，通过拉高 `CS#` 来提前终止。
-   **禁止过早释放CS#：** **绝对不能**在模式位或虚拟周期期间拉高 `CS#`，否则会导致模式位捕获错误，使设备是否处于高性能模式变得不确定。

### Program granularity

> 写flash的最小粒度-本章节详细解释了 S25FL-S 系列闪存设备在编程操作中的最小单位（粒度）以及内置的自动纠错码（ECC）机制。其目的是在保证数据完整性的同时，兼顾灵活性和向后兼容性。

#### **11.5.1.2 页编程 (Page Programming)**

这是标准的、高效的编程方式。

-   **基本流程：**
    1.  主机将最多一个"页"的数据加载到设备内部的"页缓冲区"（Page Buffer）中。
    2.  发送 `PP` 或 `QPP` 命令，将缓冲区中的数据写入主存储阵列。

-   **页大小 (Page Size)：**
    -   由产品型号（Ordering Part Number, OPN）决定，分为 **256字节（hybrid）** 或 **512字节（Uniform）** 两种。
    -   页必须从页大小的地址边界开始。
-   **灵活性：**
    -   单次页编程操作可以写入1字节到整个页大小之间的任意数量的数据。
    -   **推荐做法：** 为了获得最佳性能和数据完整性，建议：
        -   以 **16字节对齐** 的方式进行写入。
        -   尽量写满整个页（256或512字节）。
        -   每个页只编程一次。

#### **11.5.1.3 单字节编程 (Single Byte Programming)**

-   **目的：** 提供对传统SPI编程命令的完全向后兼容性。
-   **功能：** 允许主机在内存阵列的任意位置写入单个字节。
-   **代价：**
    -   写入任何一个字节，都会导致其所在的**16字节ECC单元**的自动ECC功能被**禁用**。
    -   这会牺牲该区域的数据可靠性。
-   **适用场景：** 仅在需要精确修改单个字节且不关心ECC保护的特殊情况下使用。

### Page Program (PP 02h or 4PP 12h)

`Page Program` 命令用于将数据写入闪存阵列，其本质是将存储单元中的位从 `1` 编程为 `0`。这是实现数据存储的核心操作。

#### **前提条件**

-   **必须先执行 `WREN` 命令：** 在发送任何 `PP` 或 `4PP` 命令之前，主机必须先发送 `WREN` 命令，成功后设备会设置状态寄存器1 (SR1) 中的 `WEL` 位，从而授权后续的编程操作。

#### **命令格式与地址模式**

根据所选的地址模式，有两种主要的指令码：

| 指令码 | 地址长度 | 适用场景 |
| :--- | :--- | :--- |
| **`02h`** | 3字节 (A23-A0) | 当 `EXTADD=0` 时使用，适用于访问前128Mb空间或通过Bank Register进行分页访问。 |
| **`12h`** | 4字节 (A31-A0) | 用于直接访问超过128Mb的完整地址空间，或当 `EXTADD=1` 时激活旧指令的4字节模式。 |

-   **数据传输：** 指令和地址之后，主机通过 `SI` 信号发送至少一个数据字节。

#### **页大小与数据组织**

-   **页大小 (Page Size)：** 由产品型号（OPN）决定，分为 **256字节** 或 **512字节**。
-   **页边界：** 页必须从其大小的地址边界开始（例如，对于256字节页，起始地址的低8位必须为0；对于512字节页，起始地址的低9位必须为0）。
-   **地址回绕 (Address Wrap):**
    -   如果提供的起始地址不是页边界（即最低9位 `A8-A0` 不全为0），那么所有超出当前页末尾的数据，都会自动"回绕"到该页的起始地址处继续写入。
    -   这意味着，用户只需提供一个地址，即可覆盖整个页的范围，简化了编程操作。
-   **部分页编程：**
    -   主机可以发送少于一页的数据。
    -   数据将从指定的起始地址开始顺序写入，不会影响同一页内其他未被写入的字节。

#### **性能优化建议**

-   **最佳实践：** 为了获得最优的编程时间，应尽可能**一次性写满整个页**（256或512字节）。
-   **原因：** 写入一个完整的页比写入部分页能更有效地利用内部缓冲区和控制逻辑，从而节省整体编程时间。

#### **编程过程与状态监控**

-   **内部控制：** 编程操作由设备内部的控制逻辑管理，是一个自定时的过程。
-   **状态查询：**
    -   编程命令发出后，主机可以通过读取 **状态寄存器1 (SR1)** 来监控进度。
    -   **`WIP` 位 (SR1[0]):** 为 `1` 表示编程正在进行中，为 `0` 表示编程已完成。
    -   **`P_ERR` 位 (SR1[6]):** 为 `1` 表示编程过程中发生了错误，导致操作失败。

#### **总结**

`Page Program` 是S25FL-S系列闪存最基础、最重要的写入命令。开发者在使用时需牢记以下关键点：

1.  **权限先行：** 务必在编程前执行 `WREN` 命令。
2.  **地址模式：** 根据应用需求选择正确的指令码 (`02h` 或 `12h`) 和地址长度。
3.  **页边界：** 理解并利用地址回绕特性，简化编程流程。
4.  **性能考量：** 尽量按整页写入，以获得最佳性能。
5.  **状态监控：** 编程后务必检查 `WIP` 和 `P_ERR` 位，确保操作成功完成。

### Erase flash array commands

S25FL-S 系列闪存设备支持的三种擦除命令：参数扇区擦除、普通扇区擦除和整片擦除。这些命令用于将存储单元中的位从 `0` 重置为 `1`，是进行编程操作前的必要步骤。

#### **通用规则**

所有擦除命令都遵循以下基本前提和流程：

1.  **必须先执行 `WREN` 命令：** 擦除操作前，主机必须先发送 `WREN` 命令，成功后设备会设置状态寄存器1 (SR1) 中的 `WEL` 位，授权擦除操作。
2.  **CS# 释放时机：**
    -   在发送完指令和地址后，主机必须在**精确的时序点**将 `CS#` 拉高，以启动内部擦除周期。
    -   如果 `CS#` 未在正确时刻拉高，擦除操作将被忽略，不会执行。
3.  **状态监控：**
    -   擦除命令发出后，主机可以通过读取 **状态寄存器1 (SR1)** 来监控进度。
    -   **`WIP` 位 (SR1[0]):** 为 `1` 表示擦除正在进行中，为 `0` 表示擦除已完成。
    -   **`E_ERR` 位 (SR1[5]):** 为 `1` 表示擦除过程中发生了错误（通常是由于保护机制）。
4.  **擦除原理：** 擦除操作是一个自定时过程，通常包括一个"预编程"阶段，然后才是真正的擦除。

#### **11.6.1 参数 4-KB 扇区擦除 (P4E, 20h 或 4P4E, 21h)**

-   **适用范围：** 仅适用于 **S25FL128S 和 S25FL256S** 设备，并且设备必须配置为**混合扇区结构**（即包含4KB扇区）。如果设备配置为统一的256KB扇区，则此命令会被忽略。
-   **功能：** 将指定的一个 **4KB 参数扇区** 中的所有位擦除为 `1`。
-   **指令码与地址：**
    -   `20h`: 用于3字节地址（需配合 `EXTADD=0` 或 `EXTADD=1`）。
    -   `21h`: 用于4字节地址。
-   **保护机制：**
    -   如果目标扇区已被 **块保护 (BP)** 或 **高级扇区保护 (ASP)** 锁定，则擦除操作**不会执行**，并会设置 `E_ERR` 位。
    -   如果对一个大于4KB的扇区（如64KB或256KB）执行 `P4E`，操作**不会执行**，但**不会设置 `E_ERR`** 位。

#### **11.6.2 扇区擦除 (SE, D8h 或 4SE, DCh)**

-   **功能：** 将指定的一个扇区中的所有位擦除为 `1`。
-   **扇区大小：** 由产品订购选项决定，可以是 **64KB** 或 **256KB**。
    -   选择256KB模式是为了与更高密度的未来设备保持软件兼容性。
-   **指令码与地址：**
    -   `D8h`: 用于3字节地址（需配合 `EXTADD=0` 或 `EXTADD=1`）。
    -   `DCh`: 用于4字节地址。
-   **保护机制：**
    -   如果目标扇区（或其包含的任何子扇区）被 **块保护 (BP)** 或 **ASP** 锁定，则擦除操作**不会执行**，并会设置 `E_ERR` 位。
    -   ASP 的保护粒度非常精细，它为每个扇区（包括4KB扇区）都设有独立的保护位。因此，如果一个64KB或256KB的擦除命令试图覆盖一个受保护的4KB区域，整个擦除操作都会失败。

#### **11.6.3 整片擦除 (BE, 60h 或 C7h)**

-   **功能：** 将**整个闪存阵列**中的所有位擦除为 `1`。
-   **指令码：** `60h` 或 `C7h`（两者功能相同）。
-   **前提条件：**
    -   必须先执行 `WREN` 命令。
    -   **关键限制：** 只有当 **块保护位 (BP2, BP1, BP0)** 全部为 `0` 时，整片擦除才能执行。
-   **保护机制：**
    -   如果 `BP` 位不全为 `0`，则 `BE` 命令**不会执行**，并且**不会设置 `E_ERR`** 位。
    -   如果存在由 **DYB** 或 **PPB** 保护的扇区，`BE` 命令会**跳过**这些扇区，只擦除未受保护的部分，同样**不会设置 `E_ERR`** 位。

#### **总结**

S25FL-S 设备提供了灵活的擦除层级，开发者应根据需求选择合适的命令：

-   **精细控制：** 使用 `P4E` 擦除小的4KB参数扇区。
-   **常规操作：** 使用 `SE` 擦除标准的64KB或256KB扇区。
-   **彻底重置：** 使用 `BE` 擦除整个芯片（需确保无全局保护）。

无论使用哪种命令，都必须严格遵守 `WREN` 和 `CS#` 释放时机的要求。同时，务必注意各种保护机制（BP, ASP, DYB, PPB）的存在，它们会阻止对受保护区域的擦除操作，有时还会通过设置 `E_ERR` 位来通知用户。理解这些保护机制对于安全可靠地管理设备至关重要。

----

![[assets/Pasted image 20251115105606.png]]

> [!NOTE] Notes
> EHPLC = Enhanced High Performance Latency Code table.
> 2.Uniform 64-KB sectors = A hybrid of 32 x 4-KB sectors with all remaining sectors being 64 KB, with a 256B programming buffer.
> 3.Uniform 256-KB sectors = All sectors are uniform 256-KB with a 512B programming buffer.
