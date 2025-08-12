from InfaredProcess import *


def cal_grad(image, height, width):
    # 将image转换为有符号数
    image = image.astype(np.int16)
    gradient = image.copy()
    nMaxgradLimit = 4096
    nMingradLimit = 2
    sobel_x = np.array([[-1, 0, 1], [-2, 0, 2], [-1, 0, 1]], dtype=np.float32)
    sobel_y = np.array([[-1, -2, -1], [0, 0, 0], [1, 2, 1]], dtype=np.float32)

    # 应用卷积核
    gx = cv2.filter2D(image, -1, sobel_x).astype(np.int32)
    gy = cv2.filter2D(image, -1, sobel_y).astype(np.int32)
    gxgy = gx * gx + gy * gy

    # 计算gxgy根号值，并对结果向下取整
    # g = np.sqrt(gxgy)
    g = np.floor(np.sqrt(gxgy))

    # 对g中的元素进行阈值判断，如果大于nMaxgradLimit，则将其赋值为nMaxgradLimit；如果小于nMingradLimit，则将其赋值为nMingradLimit
    g[g > nMaxgradLimit] = nMaxgradLimit
    g[g < nMingradLimit] = nMingradLimit

    gradient = g.astype(np.int32)
    # 使用numpy快速将梯度矩阵gradient的第一行、第一列、最后一行、最后一列的梯度值都为0
    gradient[0, :] = 0
    gradient[:, 0] = 0
    gradient[-1, :] = 0
    gradient[:, -1] = 0
    return gradient


def saveto_raw(image: np.ndarray, rawname: str, endian: str) -> None:
    """
    Save the image data to a raw file.

    Args:
        image (np.ndarray): The image data to be saved.
        rawname (str): The name of the raw file to be saved.
        endian (str): The endian format of the raw file.

    Returns:
        None
    """
    number, height, width = image.shape
    # 判断image数据类型是否是有符号数
    if image.dtype == "uint16":
        with open(rawname, "wb") as f:
            for i in range(number):
                for j in range(height):
                    for k in range(width):
                        temp = int(image[i][j][k])
                        f.write(temp.to_bytes(2, endian))
    else:  # 如果image是有符号数，需要先转换为无符号数
        image = image.astype("uint16")
        with open(rawname, "wb") as f:
            for i in range(number):
                for j in range(height):
                    for k in range(width):
                        temp = int(image[i][j][k])
                        f.write(temp.to_bytes(2, endian))


def main():
    filename_src = r"E:\100-Working\102-Working-Prj\hisp_fpga\sim\data\filter1.raw"
    datatype = "y16"
    image_width = 640
    image_height = 512
    endian = "little"
    signed = "unsigned"

    # print(InfaredProcess.__name__)

    # 加载原始数据
    ip1 = InfaredProcess(filename_src, datatype, image_width, image_height)
    print(image_width)
    print(image_height)
    image_num = ip1.get_file_size()
    img1 = ip1.loadraw_2mat(image_num, endian, signed)
    img1[0] = cal_grad(img1[0], image_height, image_width)
    saveto_raw(img1, r"E:\100-Working\102-Working-Prj\hisp_fpga\sim\output\filter1_grad.raw", "little")
    # ip1.show_img_y16(img1_grad)


if __name__ == "__main__":
    main()
