from InfaredProcess import *
import json
import os
import subprocess
import shutil
# from cal_grad import *
from cal_demo import *


def main():
    files = os.listdir(os.getcwd())
    json_files = [f for f in files if f.endswith(".json")]
    configuration_name = os.getcwd() + "/" + json_files[0]
    with open(configuration_name) as f:
        json_cfg = json.load(f)
    tb_cfg = json_cfg["tb"]
    modelsim_cfg = json_cfg["modelsim"]
    compare_cfg = json_cfg["compare"]

    compare_mode = compare_cfg["compare_mode"]
    compare_width = int(compare_cfg["width"])
    compare_height = int(compare_cfg["height"])
    compare_source_path = compare_cfg["compare_source_path"]
    compare_source_name = compare_cfg["compare_source_name"]
    compare_src = compare_source_path + compare_source_name
    compare_datatype = compare_cfg["image_mode"]

    tb_width = int(tb_cfg["width"])
    tb_height = int(tb_cfg["height"])
    post_sim_data_path = modelsim_cfg["post_sim_data_path"]
    post_sim_data_name = modelsim_cfg["post_sim_data_name"]
    filename_sim = post_sim_data_path + post_sim_data_name

    modelsim_datatype = modelsim_cfg["post_image_mode"]
    endian = "little"
    signed = "unsigned"

    # print(InfaredProcess.__name__)

    # 加载原始数据
    ip1 = InfaredProcess(compare_src, compare_datatype, compare_width, compare_height)
    image_num = ip1.get_file_size()
    img1 = ip1.loadraw_2mat(image_num, endian, signed)
    if compare_mode == "script":
        # img1_grad = cal_grad(img1[image_num - 1], tb_height, tb_width)
        img1_grad = cal_demo(img1[image_num - 1], tb_height, tb_width)
        # print("第一个元素的值是",img1[0][0])
        # print("第一个元素的值是",img1_grad[0][0])
        img1[image_num - 1] = img1_grad
    elif compare_mode == "raw":
        img1 = img1
        # print(compare_src)
        # print(img1[0][0])
        # print(img1[0][1])
    elif compare_mode == "exe":
        img1 = img1
    
    # 加载仿真后数据
    ip2 = InfaredProcess(filename_sim, modelsim_datatype, compare_width, compare_height)
    image_num2 = ip2.get_file_size()
    # print("image_num2", image_num2)
    img2 = ip2.loadraw_2mat(image_num2, endian, signed)
    # print("image_num2", img2[image_num2-1][0:10])

    diff = np.abs(img1[image_num-1] - (img2[image_num2-1]))

    num = 0
    # print(os.getcwd())
    log_file = "../output/diff.log"
    # 判断diff是否为全0矩阵
    if np.all(diff == 0):
        if os.path.exists(log_file):
            os.remove(log_file)
        print("************************************************************")
        print("*simulation passed!!!                                      *")
        print("************************************************************")
    else:
        print("************************************************************")
        print("*simulation failed!!!                                      *")
        print("*diff result is stored in sim/output/diff.log              *")
        print("************************************************************")
        if os.path.exists(log_file):
            os.remove(log_file)
        with open(log_file, "a") as f:
            f.write("(cord_x,cord_y)-->Algirhms - Modelsim = diff\n")
            for i in range(compare_height):
                for j in range(compare_width):
                    if diff[i, j] != 0:
                        num = num + 1
                        f.write(
                            "("
                            + str(i)
                            + ","
                            + str(j)
                            + ")"
                            + "-->"
                            + str(img1[image_num-1][i, j])
                            + "-"
                            + str(img2[image_num2-1][i, j])
                            + "="
                            + str(diff[i, j])
                            + "\n"
                        )
        print("the total number of diff is " + str(num))


def call_exe():
    files = os.listdir(os.getcwd())
    json_files = [f for f in files if f.endswith(".json")]
    configuration_name = os.getcwd() + "/" + json_files[0]
    with open(configuration_name) as f:
        json_cfg = json.load(f)
    tb_cfg = json_cfg["tb"]
    compare_cfg = json_cfg["compare"]
    exe_path = compare_cfg["exe_path"]
    exe_name = compare_cfg["exe_name"]
    image_source_path = compare_cfg["image_source_path"]
    image_source_name = compare_cfg["image_source_name"]
    temp_path = compare_cfg["temp_path"]

    # 使用python将文件复制到另一个文件夹内
    # shutil.copyfile(image_source_path + image_source_name, temp_path + "image.raw")
    shutil.copy(image_source_path + image_source_name, temp_path)

    instruction = exe_path + exe_name + " " + temp_path + image_source_name
    # print(type(instruction))
    # print(instruction)
    process = subprocess.Popen(instruction, stdout=subprocess.PIPE)
    # stdout, stderr = process.communicate()
    # print(stdout.decode())  # 输出 EXE 文件的标准输出


if __name__ == "__main__":
    main()
    # call_exe()
