import numpy as np
from jinja2 import Template


amp_scale = 4096
table_len = 512
gray_std = 30
rom_file = "gray_weigh_table.inithex"
verilog_file = "gray.v"


def replace_verilog(file, table_len, amp_scale):
    addr_w = int(np.log2(table_len))
    data_w = int(np.log2(amp_scale))
    t = Template(
        """
    // auto genetated by cal_gray_weigh_table.py
    single_port_rom #(
        .DATA_WIDTH                         ({{data_w}}                        ),
        .ADDR_WIDTH                         ({{addr_w}}                        ),
        .OUTPUT_REG                         ("FALSE"                   ),
        .RAM_INIT_FILE                      (RAM_INIT_FILE1            ) 
    ) angle_rom_inst (
        .clk                                (i_Sys_clk                 ),
        .addr                               (index_addr                ),
        .data                               (angle_index               )
    );
    // auto genetated done
"""
    )

    temp = t.render(data_w=data_w, addr_w=addr_w)
    # 读取文件并处理每一行
    start_pattern = "// auto genetated by cal_gray_weigh_table.py"
    end_pattern = "// auto genetated done"
    modified_content = []
    collecting = False  # 标记是否正在收集要替换的内容
    with open(file, "r", encoding="utf-8") as f:
        for line in f:
            if start_pattern in line:
                collecting = True
                # modified_content.append(line)  # 保留开始模式所在行
            elif end_pattern in line:
                collecting = False
                modified_content.append(temp + "\n")  # 插入替换内容
                # modified_content.append(line)  # 保留结束模式所在行
            else:
                if not collecting:
                    modified_content.append(line)  # 如果不在收集状态，直接添加行
                else:
                    # 在收集状态，跳过行，因为它们会被替换
                    pass
    with open(file, "w", encoding="utf-8") as f:
        f.writelines(modified_content)
        f.flush()

    #     temp = t.render(data_w=data_w, addr_w=addr_w)
    #     f.write(t.render(data_w=data_w, addr_w=addr_w))
    #     f.flush()


def save_2_file(file, table):
    with open(file, "w") as f:
        for i in table:
            f.write(i + "\n")
    print("save to file: " + file)


def GetGaussGrayWeightTable(len, std):
    weigh = np.zeros(len)
    for i in range(len):
        arg = -(i * i) / (2 * std * std + 0.0001)
        weigh[i] = int(np.exp(arg) * amp_scale + 0.5)
    return weigh.astype(np.uint16)


def int16_2_hex(table):
    hex_table = [hex(int(i)) for i in table]
    hex_table = [i[2:] for i in hex_table]
    return hex_table


def main():
    print("cal gray weigh table...")
    weigh = GetGaussGrayWeightTable(table_len, gray_std)
    efinix_rom = int16_2_hex(weigh)
    save_2_file(rom_file, efinix_rom)
    # print(efinix_rom)
    replace_verilog(verilog_file, table_len, amp_scale)


if __name__ == "__main__":
    main()
