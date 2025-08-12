from InfaredProcess import *
from sub_result2raw import load_result
import json


def main():
    files = os.listdir(os.getcwd())
    json_files = [f for f in files if f.endswith(".json")]
    configuration_name = os.getcwd() + "\\" + json_files[0]
    with open(configuration_name) as f:
        json_cfg = json.load(f)
    tb_cfg = json_cfg["tb"]
    image_cfg = json_cfg["image"]
    modelsim_cfg = json_cfg["modelsim"]

    tb_width = int(tb_cfg["width"])
    tb_height = int(tb_cfg["height"])
    sim_data_path = tb_cfg["sim_data_path"]
    sim_data_name = tb_cfg["sim_data_name"]
    post_sim_data_path = modelsim_cfg["post_sim_data_path"]
    post_sim_data_name = modelsim_cfg["post_sim_data_name"]
    post_image_mode = modelsim_cfg["post_image_mode"]
    root_dir = os.getcwd()

    # 找到result文件
    os.chdir(sim_data_path)
    # files = os.listdir(os.getcwd())
    files = post_sim_data_path + post_sim_data_name
    input_file = files.replace(".raw", ".result")
    output_file = files#input_file.replace(".result", ".raw")
    # result = os.getcwd() + "\\" + file
    load_result(
        input_file,
        output_file,
        post_image_mode,
    )
    # print增加颜色
    # print("\033[1;31;40m")
    # print("input_file = ",input_file)
    # result_files = [f for f in files if f.endswith(".result")]
    # print("result_files = ",result_files)
    # for file in result_files:
    #     os.chdir(sim_data_path)
    #     output_file = file.replace(".result", ".raw")
    #     result = os.getcwd() + "\\" + file
    #     load_result(
    #         result,
    #         output_file,
    #         post_image_mode,
    #     )
    #     os.chdir(root_dir)

if __name__ == "__main__":
    main()
