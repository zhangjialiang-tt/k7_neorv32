import os
import json
from InfaredProcess import *


def save_sim(filename):
    with open(filename) as f:
        json_cfg = json.load(f)
    tb_cfg = json_cfg["tb"]
    image_cfg = json_cfg["image"]
    # object-tb
    tb_mode = tb_cfg["tb_mode"]
    if tb_mode == "image":
        print("\033[0;31;40m使用图像仿真脚本\033[0m")
        # print("使用图像仿真脚本")
        tb_path = tb_cfg["path"]
        tb_name = tb_cfg["name"]
        tb_width = int(tb_cfg["width"])
        tb_height = int(tb_cfg["height"])
        tb_frame_rate = int(tb_cfg["frame_rate"])
        tb_pixel_clock = int(tb_cfg["pixel_clock"])
        sim_data_path = tb_cfg["sim_data_path"]
        sim_data_name = tb_cfg["sim_data_name"]
        # object-image
        image_path = image_cfg["path"]
        image_name = image_cfg["name"]
        image_mode = image_cfg["image_mode"]
        print("数据源为：", image_path + image_name)
        image_image_number = int(image_cfg["image_number"])
        image_width = int(image_cfg["width"])
        image_height = int(image_cfg["height"])

        datatype = image_mode  # "y16""y8"
        print("数据模式为：", datatype)
        endian = "little"
        signed = "unsigned"
        ip = InfaredProcess(
            image_path + image_name, datatype, image_width, image_height
        )
        image_num = ip.get_file_size()
        print("图像数量为：", image_num)
        img1 = ip.loadraw_2mat(image_num, endian, signed)
        print("图像分辨率为：", img1[0].shape)

        # img2 = ip.image_roi(img1, roi_en, roi_width, roi_height)

        print("仿真文件为", sim_data_path + sim_data_name)
        ip.saveimage_to_simulation(
            img1[image_image_number - 1], sim_data_path + sim_data_name, 16
        )
    else:
        print("\033[0;31;40m使用简单仿真脚本,不需要保存仿真数据\033[0m")
        # print("使用简单仿真脚本,不需要保存仿真数据")


def main():
    files = os.listdir(os.getcwd())
    json_files = [f for f in files if f.endswith(".json")]
    configuration_name = os.getcwd() + "/" + json_files[0]
    # configuration_name = r"C:\100-Working\105-Working-improvement\github_lib\zg_fpga\sim\sub0-grad\configuration.json"
    save_sim(configuration_name)


if __name__ == "__main__":
    main()
