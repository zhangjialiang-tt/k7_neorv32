from InfaredProcess import *


def saveto_raw(image: np.ndarray, rawname: str, endian: str) -> None:
    height, width = image.shape
    with open(rawname, "wb") as f:
        for j in range(height):
            for k in range(width):
                temp = int(image[j][k])
                f.write(temp.to_bytes(2, endian))
def show_img_y16(image):
    plt.imshow(image, cmap=plt.cm.gray)  # Display the image using a gray colormap
    plt.colorbar()  # Add a colorbar to the image
    plt.show()  # Show the image


def main():
    filename = (
        # r"C:\100-Working\102-Working-Prj\ghe\ghe_stage4\data\zp44b\0714153002.raw"
        r"C:\Users\zhangjl\Documents\WeChat Files\zjlily\FileStorage\File\2024-09\x16_0_640_516_1280_20000311_125223_415.x16"
    )
    datatype = "y16"
    width = 640
    height = 512
    paraline = 4
    # pix_bit = 16
    endian = "big"
    signed = "signed"
    roi_en = 0
    roi_width = 128
    roi_height = 128

    processor = InfaredProcess(filename, datatype, width, height + paraline)
    image_num = processor.get_file_size()
    img1 = processor.loadraw_2mat(image_num, endian, signed)
    img2 = img1[0]
    processor = InfaredProcess(filename, datatype, width, height)
    # 提取img2的前10行
    img3 = img2[:height]
    img4= img3+8192
    img5= img4.astype(np.uint16)
    saveto_raw(img5,r"C:\Users\zhangjl\Documents\WeChat Files\zjlily\FileStorage\File\2024-09\temp.raw","little")
    # show_img_y16(img3)


if __name__ == "__main__":
    main()
