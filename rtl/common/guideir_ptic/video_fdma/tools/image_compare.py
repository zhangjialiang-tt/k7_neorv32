from InfaredProcess import *


def main():
    # filename = "../sim/data/ghe_local_adjust_gradmap.raw"
    # filename = "../sim/data/ghe_local_adjust_y8.raw"
    # filename = r"C:\\100-Working\\102-Working-Prj\\Embedded_Group_Repositories\\AlgorithmModule\\ghe\\sim\\data\\ghe_y16.raw"
    filename = r"C:\100-Working\102-Working-Prj\Embedded_Group_Repositories\AlgorithmModule\ghe_v2\sim\data\filter120.raw"
    # filename = r"C:\\100-Working\\102-Working-Prj\\Embedded_Group_Repositories\\AlgorithmModule\\ghe\\sim\\data\\ghe_local_adjust_gradmap.raw"
    # filename = r"C:\\100-Working\\102-Working-Prj\\Embedded_Group_Repositories\\AlgorithmModule\\ghe\\sim\\data\\ghe_local_adjust_hlmap.raw"

    # modelsim_filename = r"C:\100-Working\102-Working-Prj\Embedded_Group_Repositories_gitee\AlgorithmModule\ghe\sim\data\modelsim_hist_map_hl.raw"
    # modelsim_filename = r"C:\100-Working\102-Working-Prj\Embedded_Group_Repositories_gitee\AlgorithmModule\ghe\sim\data\modelsim_hist_map_grad.raw"
    modelsim_filename = r"C:\100-Working\102-Working-Prj\Embedded_Group_Repositories\AlgorithmModule\ghe_v2\sim\data\us_src.raw"

    datatype = "y16"
    width = 640  # 16384  # 640
    height = 512  # 1  # 480
    endian = "little"
    signed = "unsigned"
    roi_en = 0
    roi_width = 128
    roi_height = 128
    print(InfaredProcess.__name__)

    ip = InfaredProcess(filename, datatype, width, height)
    image_num = ip.get_file_size()
    img1 = ip.loadraw_2mat(image_num, endian, signed)
    vs_image = img1[0]

    datatype = "y16"
    ip2 = InfaredProcess(modelsim_filename, datatype, width, height)
    image2_num = ip2.get_file_size()
    img3 = ip2.loadraw_2mat(image2_num, endian, signed)
    # img2 = ip2.load_simulation_result(3)
    sim_img = img3[image2_num - 1]

    diff = np.abs(vs_image - sim_img)

    # 统计diff不等于0的个数
    diff_count = np.count_nonzero(diff)
    # 打印diff不等于0的元素位置
    diff_index = np.argwhere(diff)
    for i in diff_index:
        a = i[0]
        b = i[1]
        print(i,vs_image[a][b],sim_img[a][b])
    print(diff_count, diff_index)



if __name__ == "__main__":
    main()
