from InfaredProcess import *
import json
import os
import subprocess
import shutil
# from cal_grad import *
from cal_demo import *
# 定义函数，实现将三维图像矩阵img1中第no帧数据拷贝到另一个三维图像矩阵img2中，重复次数times
def copy_image(img, no, times):
    height, width = img.shape[1], img.shape[2]
    img2 = np.zeros((times, height, width))
    for i in range(times):
        img2[no + i] = img[no]
    return img2

def main():
    filename = r"C:\100-Working\102-Working-Prj\ghe\ghe_stage4\data\5\chezhai_640x512.raw"
    datatype = "y16"
    width = 640
    height = 512
    # pix_bit = 16
    endian = "little"
    signed = "unsigned"
    # 加载原始数据
    ip1 = InfaredProcess(filename, datatype, width, height)
    image_num = ip1.get_file_size()
    img1 = ip1.loadraw_2mat(image_num, endian, signed)
    img2 = copy_image(img1, 0, 20)
    ip1.saveto_raw(img2, r"C:\100-Working\102-Working-Prj\ghe\ghe_stage4\data\5\chezhai_640x512_copy.raw", endian)
    

if __name__ == "__main__":
    main()
    # call_exe()
