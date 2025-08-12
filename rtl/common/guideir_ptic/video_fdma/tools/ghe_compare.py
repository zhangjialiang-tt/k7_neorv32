from InfaredProcess import *
import json
import os
import subprocess
import shutil

# from cal_grad import *
from cal_demo import *


def main():
    # 加载原始数据
    filename = r"C:\100-Working\102-Working-Prj\Embedded_Group_Repositories\AlgorithmModule\ghe_v2\sim\output\temp.raw"
    datatype = "y8"
    width = 640
    height = 512
    # pix_bit = 16
    endian = "little"
    signed = "unsigned"
    ip1 = InfaredProcess(filename, datatype, width, height)
    image_num = ip1.get_file_size()
    img1 = ip1.loadraw_2mat(image_num, endian, signed)
    img1 = img1[4]

    filename = r"C:\100-Working\102-Working-Prj\Embedded_Group_Repositories\AlgorithmModule\ghe_v2\sim\data\vs_12.raw"
    datatype = "y8"
    width = 640
    height = 512
    # pix_bit = 16
    endian = "little"
    signed = "unsigned"
    ip2 = InfaredProcess(filename, datatype, width, height)
    image_num = ip2.get_file_size()
    img2 = ip2.loadraw_2mat(image_num, endian, signed)

    image_diff = img2 - img1
    image_diff = img2 - img1

    non_zero_elements = image_diff[image_diff != 0]

    print(non_zero_elements)


if __name__ == "__main__":
    main()
