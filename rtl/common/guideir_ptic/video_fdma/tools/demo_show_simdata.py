from InfaredProcess import *


def main():
    filename = r"C:\100-Working\102-Working-Prj\Embedded_Group_Repositories\AlgorithmModule\tv_correction\sim\data\cal_offset92 - 副本.txt"
    datatype = "y16"
    width = 640
    height = 512
    endian = "little"
    signed = "signed"
    roi_en = 0
    roi_width = 128
    roi_height = 128
    print(InfaredProcess.__name__)
    ip = InfaredProcess(filename, datatype, width, height)

    img1 = ip.load_simulation_result(filename, height, width)
    ip.show_img_y16(img1)


if __name__ == "__main__":
    main()
