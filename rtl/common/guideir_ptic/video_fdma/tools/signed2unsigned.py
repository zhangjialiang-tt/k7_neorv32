from InfaredProcess import *


def from_signedto_signed(image):
    image_num, image_height, image_width = image.shape
    image2 = np.zeros_like(image)

    for i in range(image_num):
        image2[i] = image[i] + 8192
    return image2


def main():
    print("hello")
    filename = r"C:\100-Working\102-Working-Prj\ghe\ghe_stage4\data\y16_640_512.raw"
    datatype = "y16"
    width = 640
    height = 512
    # pix_bit = 16
    endian = "little"
    signed = "signed"

    processor = InfaredProcess(filename, datatype, width, height)
    image_num = processor.get_file_size()
    img1 = processor.loadraw_2mat(image_num, endian, signed)
    img2 = from_signedto_signed(img1)
    processor.saveto_raw(img2, r"C:\100-Working\102-Working-Prj\ghe\ghe_stage4\data\y16_640_512_unsigned.raw", endian)


if __name__ == "__main__":
    main()
