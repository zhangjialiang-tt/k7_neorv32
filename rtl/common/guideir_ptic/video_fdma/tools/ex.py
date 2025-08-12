from InfaredProcess import *


def saveto_raw(image: np.ndarray, rawname: str, endian: str) -> None:
    number, height, width = image.shape
    # 判断image数据类型是否是有符号数
    if image.dtype == "uint16":
        with open(rawname, "wb") as f:
            for i in range(number):
                for j in range(height):
                    for k in range(width):
                        temp = int(image[i][j][k])
                        f.write(temp.to_bytes(2, endian))
    elif image.dtype == "uint8":
        with open(rawname, "wb") as f:
            for i in range(number):
                for j in range(height):
                    for k in range(width):
                        temp = int(image[i][j][k])
                        f.write(temp.to_bytes(1, endian))
    else:  # 如果image是有符号数，需要先转换为无符号数
        image = image.astype("uint16")
        with open(rawname, "wb") as f:
            for i in range(number):
                for j in range(height):
                    for k in range(width):
                        temp = int(image[i][j][k])
                        f.write(temp.to_bytes(2, endian))


# 图像处理相关方法


def from_signedto_signed(image):
    image_num, image_height, image_width = image.shape
    image2 = np.zeros_like(image)

    for i in range(image_num):
        image2[i] = image[i] + 8192
    return image2


def load_image(filename):
    datatype = "y16"
    width = 640
    height = 512
    # pix_bit = 16
    endian = "little"
    signed = "signed"

    processor = InfaredProcess(filename, datatype, width, height)
    image_num = processor.get_file_size()
    img1 = processor.loadraw_2mat(image_num, endian, signed)
    # processor.show_img_y16(img1[0])
    return img1[0]


def main():
    filename_1 = r"C:\100-Working\102-Working-Prj\Embedded_Group_Repositories\AlgorithmModule\ghe_v4\c++\data\zp44b_dbg_ltm_1.raw"
    filename_2 = r"C:\100-Working\102-Working-Prj\Embedded_Group_Repositories\AlgorithmModule\ghe_v4\c++\data\zp44b_dbg_ltm_2.raw"
    filename_3 = r"C:\100-Working\102-Working-Prj\Embedded_Group_Repositories\AlgorithmModule\ghe_v4\c++\data\zp44b_dbg_ltm_3.raw"
    filename_4 = r"C:\100-Working\102-Working-Prj\Embedded_Group_Repositories\AlgorithmModule\ghe_v4\c++\data\zp44b_dbg_ltm_4.raw"
    filename_5 = r"C:\100-Working\102-Working-Prj\Embedded_Group_Repositories\AlgorithmModule\ghe_v4\c++\data\zp44b_dbg_ltm_5.raw"
    img_0 = load_image(filename_1)
    img_1 = load_image(filename_2)
    img_2 = load_image(filename_3)
    img_3 = load_image(filename_4)
    img_4 = load_image(filename_5)

    image_num = 50
    image = np.zeros((image_num, 512, 640))
    for i in range(image_num):
        # print(i % 5)
        if i % 5 == 0:
            image[i] = img_0
        elif i % 5 == 1:
            image[i] = img_1
        elif i % 5 == 2:
            image[i] = img_2
        elif i % 5 == 3:
            image[i] = img_3
        elif i % 5 == 4:
            image[i] = img_4

    # image[0] = img_0
    # image[1] = img_1
    # image[2] = img_2
    # image[3] = img_3
    # image[4] = img_4

    processor = InfaredProcess(filename_1, "y16", 640, 512)
    saveto_raw(
        image,
        r"C:\100-Working\102-Working-Prj\Embedded_Group_Repositories\AlgorithmModule\ghe_v4\c++\data\zp44b_dbg_ltm.raw",
        "little",
    )

    print("hello")
    # filename = r"C:\100-Working\102-Working-Prj\Embedded_Group_Repositories\AlgorithmModule\ghe_v2\sim\data\x16_0_640_516_1280_20000104_072058_528.x16"
    # datatype = "y16"
    # width = 640
    # height = 516
    # # pix_bit = 16
    # endian = "little"
    # signed = "signed"

    # processor = InfaredProcess(filename, datatype, width, height)
    # image_num = processor.get_file_size()
    # img1 = processor.loadraw_2mat(image_num, endian, signed)
    # img2 = np.zeros((image_num, 512, 640))
    # for i in range(image_num):
    #     img2[i] = processor.image_rect(img1[i], 0, 0, 640, 512)

    # processor.saveto_raw(img2, r"C:\100-Working\102-Working-Prj\ghe\ghe_stage4\data\x16_640_512.raw", "little")

    # img2 = from_signedto_signed(img1)
    # processor.saveto_raw(img2, r"C:\100-Working\102-Working-Prj\ghe\ghe_stage4\data\y16_640_512_unsigned.raw", endian)


if __name__ == "__main__":
    main()
    # for i in range(20):
    #     print(i)
