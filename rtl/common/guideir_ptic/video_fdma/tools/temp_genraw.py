from InfaredProcess import *


def main():
    # filename = r"E:\100-Working\102-Working-Prj\hisp_fpga\sim\data\y16_640x512.raw"
    filename = r"E:\100-Working\102-Working-Prj\hisp_fpga\sim\data\y16_640x480.raw"
    datatype = "y16"
    width = 640
    height = 480
    # pix_bit = 16
    endian = "little"
    signed = "unsigned"
    roi_en = 0
    roi_width = 128
    roi_height = 128

    processor = InfaredProcess(filename, datatype, width, height)
    
    image_num = processor.get_file_size()
    img1 = processor.loadraw_2mat(image_num, endian, signed)
    img3 = img1+1

    # processor.saveto_raw()
    # img2 = processor.image_rect(img1[0], 0, 0, height, width)
    # img3 = processor.convertY8(img2, equalize=True)
    # processor.show_img_y16(img2)
    processor.saveto_raw(img3, r"E:\100-Working\102-Working-Prj\hisp_fpga\sim\data\y16_640x480_compare.raw", endian)

    print("hello")


if __name__ == "__main__":
    main()
