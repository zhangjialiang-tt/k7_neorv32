from InfaredProcess import *
import numpy as np


def main():

    filename_src = r"C:\100-Working\102-Working-Prj\Embedded_Group_Repositories\AlgorithmModule\ghe_v2\sim\data\vs_y8_src.raw"
    datatype = "y8"
    image_width = 640
    image_height = 512
    # pix_bit = 16
    endian = "little"
    signed = "unsigned"
    roi_en = 0
    roi_width = 128
    roi_height = 128

    ip1 = InfaredProcess(filename_src, datatype, image_width, image_height)
    image_num = ip1.get_file_size()
    img1 = ip1.loadraw_2mat(image_num, endian, signed)

    img2 = img1.astype(np.uint16)
    ip1.saveto_raw(
        img2,
        r"C:\100-Working\102-Working-Prj\Embedded_Group_Repositories\AlgorithmModule\ghe_v2\sim\data\vs_y8_src_2byte.raw",
        endian,
    )

    print("将y8格式转换为y16格式")


if __name__ == "__main__":
    main()
    print("end")
