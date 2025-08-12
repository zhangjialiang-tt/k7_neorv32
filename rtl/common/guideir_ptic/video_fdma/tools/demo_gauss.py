import cv2
import numpy as np

# 该脚本是根据标准差和滤波器大小计算高斯系数,并将高斯系数分解为2的幂的和
# 目的是为了将高斯滤波器转换为移位运算,以提高运算速度
from InfaredProcess import *


# 计算高斯系数
def get_gaussian_coefficient(sigma, size=3, scaler_coef=4096):
    kernel = cv2.getGaussianKernel(size, sigma)
    kernel = kernel * kernel.T
    kernel = kernel * 4096

    # 计算kernel的和
    # sum_kernel = np.sum(kernel)
    # print(kernel.round())
    # print("gauss核的和为： ",sum_kernel)

    return kernel.round()


def gauss_filter(image):
    kernel = get_gaussian_coefficient(sigma=10, size=5, scaler_coef=4096)
    h = image.shape[0]
    w = image.shape[1]
    kernel_size = kernel.shape[0]
    half_kernel = int(kernel_size / 2)
    image_pad = np.pad(image, (half_kernel, half_kernel), "edge")
    image2 = np.zeros((h, w))
    print(kernel)
    # print(sum_kernel)
    print(np.sum(kernel))
    for i in range(half_kernel, h + half_kernel):
        for j in range(half_kernel, w + half_kernel):
            # print(
            #     image_pad[
            #         i - half_kernel : i + half_kernel + 1,
            #         j - half_kernel : j + half_kernel + 1,
            #     ]
            # )
            # if j==w + half_kernel - 1:
            image2[i - half_kernel, j - half_kernel] = np.sum(
                image_pad[
                    i - half_kernel : i + half_kernel + 1,
                    j - half_kernel : j + half_kernel + 1,
                ]
                * kernel
            )
    image3 = np.fix(image2 / np.sum(kernel))
    # 打印image3矩阵中前10个元素
    print(image2[0, :11])
    print(image3[0, :11])
    return image3


# 将一个整数分解为2的幂的和
def decompose(n):
    result = []
    power = []
    while n > 0:
        p = 0
        while 2 ** (p + 1) <= n:
            p += 1
        result.append(2**p)
        power.append(p)
        n -= 2**p
    return power


def main():
    filename_src = r"C:\100-Working\102-Working-Prj\Embedded_Group_Repositories\AlgorithmModule\ghe_v2\sim\data\ghe_clamp.raw"
    datatype = "y16"
    image_width = 640
    image_height = 512
    endian = "little"
    signed = "unsigned"

    ip1 = InfaredProcess(filename_src, datatype, image_width, image_height)
    # print(image_width)
    # print(image_height)
    image_num = ip1.get_file_size()
    img1 = ip1.loadraw_2mat(image_num, endian, signed)
    # print(img1.shape)

    # print(kernel)
    gauss_filter(img1[0])
    # kernel_flat = kernel.flatten()
    # kernel_list = kernel_flat.tolist()
    # kernel_result = [decompose(i) for i in kernel_list]
    # kernel_index = 0
    # for i in kernel_result:
    #     line = "gauss_result[ " + str(kernel_index) + " ] = "
    #     for j in i:
    #         # 判断是否为最后一个元素
    #         if i.index(j) == len(i) - 1:
    #             line = line + "pix << " + str(j) + " ; "
    #         else:
    #             line = line + "pix << " + str(j) + " + "

    #     kernel_index = kernel_index + 1
    #     print(line)

    # # 将kernel_result中每个元素进行指数运算,验证kernel_result是否正确
    # kernel_result_2 = [[2**j for j in i] for i in kernel_result]
    # kernel_result_2 = [sum(i) for i in kernel_result_2]
    # if kernel_result_2 == kernel_list:
    #     print("Success!")
    # else:
    #     print("Failed!")


if __name__ == "__main__":
    main()
