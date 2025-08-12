import json
from InfaredProcess import *


def main():

    files = os.listdir(os.getcwd())
    json_files = [f for f in files if f.endswith(".json")]
    configuration_name = os.getcwd() + "/" + json_files[0]
    # configuration_name = r"C:\100-Working\102-Working-Prj\Embedded_Group_Repositories\AlgorithmModule\ghe_v2\sim\sub0-prepare\configuration.json"
    with open(configuration_name) as f:
        json_cfg = json.load(f)
    tb_cfg = json_cfg["tb"]
    image_cfg = json_cfg["image"]
    modelsim_cfg = json_cfg["modelsim"]

    tb_width = int(tb_cfg["width"])
    tb_height = int(tb_cfg["height"])
    post_sim_data_path = modelsim_cfg["post_sim_data_path"]
    post_sim_data_name = modelsim_cfg["post_sim_data_name"]

    filename = post_sim_data_path + post_sim_data_name
    datatype = modelsim_cfg["post_image_mode"]
    # datatype = "y16"
    # width = 640
    # height = 512
    endian = "little"
    signed = "unsigned"
    roi_en = 0
    roi_width = 128
    roi_height = 128
    print(InfaredProcess.__name__)
    ip = InfaredProcess(filename, datatype, tb_width, tb_height)
    image_num = ip.get_file_size()
    img1 = ip.loadraw_2mat(image_num, endian, signed)

    # 如果文件时多帧视频，在下面img1[x]中选择第几帧
    # img2 = ip.image_roi(img1, roi_en, roi_width, roi_height)
    # y16->y8
    # img3 = ip.convertY8(img2, equalize=True)
    # display
    ip.show_img_y16(img1[image_num-1])
    # or
    # ip.show_img(img3)


if __name__ == "__main__":
    main()
