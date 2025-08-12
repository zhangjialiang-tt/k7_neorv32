from InfaredProcess import *
import numpy as np


def cal_sum(image):
    return np.sum(image)


def main():

    filename_src = r"C:\100-Working\102-Working-Prj\Embedded_Group_Repositories\AlgorithmModule\ghe_v2\sim\data\y16_20240527110901.raw"
    datatype = "y16"
    image_width = 640
    image_height = 512
    # pix_bit = 16
    endian = "little"
    signed = "unsigned"
    roi_en = 1
    roi_width = 128
    roi_height = 128

    ip1 = InfaredProcess(filename_src, datatype, image_width, image_height)
    image_num = ip1.get_file_size()
    img1 = ip1.loadraw_2mat(image_num, endian, signed)
    image_sum = np.zeros(image_num)
    for i in range(image_num):
        img1[i] = img1[i] + 8192
        image_sum[i] = cal_sum(img1[i]).astype(np.uint64)

    # ip1.saveto_raw(
    #     img1[0:image_num],
    #     r"C:\100-Working\102-Working-Prj\Embedded_Group_Repositories\AlgorithmModule\ghe_v2\sim\data\y16_640_512.raw",
    #     endian,
    # )

    print("将有符号数转换为无符号数")


if __name__ == "__main__":
    main()
    print("end")
