import cv2
import numpy as np

# 该脚本是根据标准差和滤波器大小计算高斯系数,并将高斯系数分解为2的幂的和
# 目的是为了将高斯滤波器转换为移位运算,以提高运算速度

# 放大系数
# 窗口大小
win_size = 3
sigma = 30
amp_coef = 455
# sigma = 30
# amp_coef = 4096

kernel1 = np.array([[307, 507, 307], [507, 836, 507], [307, 507, 307]])
kernel2 = np.array([[454, 455, 454], [455, 455, 455], [454, 455, 455]])


# 计算高斯系数
def get_gaussian_coefficient(sigma, size):
    kernel = cv2.getGaussianKernel(size, sigma)
    kernel = kernel * kernel.T
    # kernel中心点
    center = kernel[size - 1 - 1, size - 1 - 1]
    # 迭代器遍历kernel
    dbg1, dbg2 = np.shape(kernel)
    dbg3 = np.shape(kernel)[0]
    for i in range(np.shape(kernel)[0]):
        for j in range(np.shape(kernel)[1]):
            kernel[i, j] = kernel[i, j] * amp_coef / center
            # print(kernel[i, j])
    # kernel = kernel.round()
    # kernel = kernel * amp_coef
    # print(kernel.round())
    # print(kernel)
    # numpy四舍五入
    # kernel = kernel.round()
    # kernel = np.floor(kernel)
    sum_kernel = np.sum(kernel.round())
    # print(kernel.round())
    # print(sum_kernel)
    # 初始化一个3*3矩阵，元素为{307, 507, 307,
    #   507, 836, 507,
    #   307, 507, 307}

    # kernel = np.array
    # return kernel.round()
    return kernel2


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
    kernel = get_gaussian_coefficient(sigma=sigma, size=win_size)
    # kernel = int(kernel)
    kernel_flat = kernel.flatten()
    kernel_list = kernel_flat.tolist()
    kernel_result = [decompose(i) for i in kernel_list]
    kernel_index = win_size * win_size - 1  # 0
    for i in kernel_result:
        line = "gauss_result_2[ " + str(kernel_index) + " * 32 +: 32 ] <= "
        for j in i:
            # 判断是否为最后一个元素
            if i.index(j) == len(i) - 1:
                line = (
                    line
                    + "(data_array[ "
                    + str(kernel_index)
                    + " * 16 +: 16 ] <<"
                    + str(j)
                    + " ); "
                )
            else:
                line = (
                    line
                    + "(data_array[ "
                    + str(kernel_index)
                    + " * 16 +: 16 ] <<"
                    + str(j)
                    + ") + "
                )

        kernel_index = kernel_index - 1
        print(line)

    # 将kernel_result中每个元素进行指数运算,验证kernel_result是否正确
    kernel_result_2 = [[2**j for j in i] for i in kernel_result]
    kernel_result_2 = [sum(i) for i in kernel_result_2]
    if kernel_result_2 == kernel_list:
        print("Success!")
        # print(kernel_result)
    else:
        print("Failed!")
    # print(kernel_result_2)


if __name__ == "__main__":
    # a = decompose(455) #[8, 7, 6, 2, 1, 0]
    main()
