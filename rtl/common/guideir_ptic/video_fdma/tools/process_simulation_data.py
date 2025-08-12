import os
import json


def main():
    files = os.listdir(os.getcwd())
    json_files = [f for f in files if f.endswith(".json")]
    configuration_name = os.getcwd() + "/" + json_files[0]
    print(configuration_name)

    with open(configuration_name) as f:
        json_cfg = json.load(f)
    tb_cfg = json_cfg["tb"]
    image_cfg = json_cfg["image"]
    compare_cfg = json_cfg["compare"]

    tb_width = int(tb_cfg["width"])
    tb_height = int(tb_cfg["height"])
    post_sim_data_path = tb_cfg["post_sim_data_path"]
    post_sim_data_name = tb_cfg["post_sim_data_name"]

    filename = post_sim_data_path + post_sim_data_name

    # 进入到post_sim_data_path中
    os.chdir(post_sim_data_path)
    output_files = os.listdir(os.getcwd())
    result_files = [f for f in output_files if f.endswith(".result")]
    print(output_files)
    print(result_files)


if __name__ == "__main__":
    main()
