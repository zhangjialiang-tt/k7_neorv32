from InfaredProcess import *


# filename = './data/filter1.raw'
# width = 640
# hidth = 512
# pix_bit = 16
def main():
    filename = r"C:\100-Working\102-Working-Prj\Embedded_Group_Repositories\Scripts\python\data\BP1620230804_1958.raw"
    datatype = "y8"
    width = 320
    height = 256
    pix_bit = 8
    endian = "little"
    signed = "unsigned"
    roi_en = 1
    roi_width = 128
    roi_height = 128

    print(InfaredProcess.__name__)
    ip = InfaredProcess(filename, datatype, width, height)

    # 加载红外数据
    image_num = ip.get_file_size()
    img1 = ip.loadraw_2mat(image_num, endian, signed)
    # img2 = ip.image_roi(img1[0], roi_en, roi_width, roi_height)
    # img2 = ip.image_reduce(img1[0], 0)
    # img3 = ip.image_reduce(img2, axis=0)
    # img3 = ip.convertY8(img2, equalize=True)
    ip.show_img_y16(img1[0])


if __name__ == "__main__":
    main()
