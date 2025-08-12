from InfaredProcess import *
import json
import os
import subprocess
import shutil

# from cal_grad import *
from cal_demo import *


def main():
    # 加载原始数据
    filename = (
        r"C:\100-Working\102-Working-Prj\ghe\ghe_stage4\data\5\chezhai_640x512.raw"
    )
    datatype = "y16"
    width = 640
    height = 512
    # pix_bit = 16
    endian = "little"
    signed = "unsigned"
    ip1 = InfaredProcess(filename, datatype, width, height)
    image_num = ip1.get_file_size()
    img1 = ip1.loadraw_2mat(image_num, endian, signed)

    # img2 = img1[1]
    # img2 = img1[300]
    # img2 = img1[600]
    # img2 = img1[900]
    # img2 = img1[1200]
    img2 = np.zeros((5, 512, 640), dtype=np.uint16)
    for i in range(5):
        img2[i] = img1[i * 300]
        # ip1.show_img_y16(img2[i])
    ip1.saveto_raw(img2, r"C:\100-Working\102-Working-Prj\ghe\ghe_stage4\data\5\chezhai_640x512_copy2.raw", endian)


if __name__ == "__main__":
    main()
