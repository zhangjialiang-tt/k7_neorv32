from InfaredProcess import *
import numpy as np

pseudo_file = "../data/D640_Pseudo.dat"
pseudo_index = 1


def load_pseudo(filename):
    pseudo_colors = np.zeros((8, 256, 3), dtype=np.uint8)
    with open(filename, "rb") as f:
        for i in range(8):
            for j in range(256):
                pixel = f.read(4)
                if not pixel:
                    break
                yuv = pixel[1:4]

                pseudo_colors[i, j, :3] = list(yuv)
    return pseudo_colors


def load_rgb(filename):
    image = cv2.imread(filename)
    image2 = cv2.imread(filename, cv2.IMREAD_GRAYSCALE)

    yuv = cv2.cvtColor(image, cv2.COLOR_BGR2YUV)


def main():
    # load_rgb(r"C:\Users\zhangjl\Pictures\lena.jpg")
    filename = "../data/filter1.raw"
    datatype = "y16"
    width = 640
    height = 512
    endian = "little"
    signed = "unsigned"
    roi_en = 1
    roi_width = 320
    roi_height = 256
    print(InfaredProcess.__name__)
    ip = InfaredProcess(filename, datatype, width, height)

    pseudo_colors = load_pseudo(pseudo_file)

    image_num = ip.get_file_size()
    img1 = ip.loadraw_2mat(image_num, endian, signed)
    img2 = ip.image_roi(img1, roi_en, roi_width, roi_height)
    img2 = ip.convertY8(img2, equalize=True)
    img3 = img2[0]

    # 创建一个用于存储伪彩的数组
    yuv = np.zeros((roi_height, roi_width, 3), dtype=np.uint8)
    yuv[:, :, 0] = img3

    # white_pseudo = pseudo_colors[pseudo_index]
    for i in range(roi_height):
        for j in range(roi_width):
            yuv[i, j] = pseudo_colors[pseudo_index][int(img3[i, j])]
            yuv[i, j] = yuv[i, j][::-1]

    rgb = cv2.cvtColor(yuv, cv2.COLOR_YUV2BGR)
    ip.show_img(rgb)


if __name__ == "__main__":
    main()
