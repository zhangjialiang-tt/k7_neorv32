import os
def load_result(filename, output_name,image_mode):
    endian = "little"
    # 打印当前路径
    print(os.getcwd())
    # 加载result.txt文件，每行一个字节
    with open(filename, "r") as f:
        lines = f.readlines()
        print(len(lines))
    # 删除换行符
    lines = [line.strip() for line in lines]
    with open(output_name, "wb") as f:
        for line in lines:
            temp = int(line)
            if image_mode == "y8":
                f.write(temp.to_bytes(1, endian))
            elif image_mode == "y16":
                f.write(temp.to_bytes(2, endian))
            elif image_mode == "y32":
                f.write(temp.to_bytes(4, endian))
            elif image_mode == "y64":
                f.write(temp.to_bytes(8, endian))
            else:
                f.write(temp.to_bytes(2, endian))


def main():
    filename = "../sim/output/modelsim_12.result"
    output_name = "../sim/output/temp.raw"
    load_result(filename, output_name,"y8")
    print("Hello, world!")


if __name__ == "__main__":
    main()
