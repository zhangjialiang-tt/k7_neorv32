# -*- coding:UTF-8-*-

import cv2
import numpy as np
import struct
import os


# filename = './data/SG-05/result1.raw'
# filename = './data/Scart.bmp'
# filename = './data/raw2_16bits_1.raw'
# filename = './data/filter1.raw'
# filename = './data/Test.raw'
# filename = './data/640x480/20.raw'
filename = "./../data/vs_before_block_hist.raw"
output_name = "./../output/gauss_data.raw"
# filename = './data/Frame_200.raw'
width = 640
hidth = 512

pix_bit = 8  # 每个像素点有8位

window_size = 7
window_half = 3

sigma = 5

#放大系数
amp_coef = 1024


def read_img(img_file):
    img1 = cv2.imread(img_file)
    return img1


def show_img(image):
    cv2.imshow("image", image)
    cv2.waitKey(0)
    cv2.destroyAllWindows()


def load_raw_new(filename, total_frame, nx, ny, pix_bit):

    pix = np.zeros((total_frame, nx, ny))
    pix_byte = int(pix_bit / 8)
    if pix_byte == 1:
        pack_format = "B"
    else:
        pack_format = "h"

    with open(filename, "rb") as raw_data:
        for z in range(total_frame):
            for i in range(nx):
                for j in range(ny):
                    # data = raw_data.read(2)
                    data = raw_data.read(pix_byte)
                    elem = struct.unpack(pack_format, data)[0]
                    pix[z][i][j] = elem
    return pix



def get_gaussian_coefficient(sigma, size):
    kernel = cv2.getGaussianKernel(size, sigma)
    kernel = kernel * kernel.T
    kernel = kernel * amp_coef
    print(kernel.round())
    return kernel.round()




def aaply_gaussian(image):
    kernel = get_gaussian_coefficient(sigma=5, size=window_size)
    padded_image = np.pad(image, window_half, mode='edge')
    with open(output_name, 'wb') as file:
        for i in range(window_half, hidth + window_half):
            for j in range(window_half, width + window_half):
            # 提取3x3窗口
                window = padded_image[i-window_half:i+window_half+1, j-window_half:j+window_half+1]
                g_result_amp = np.sum(np.multiply(window,kernel))
                g_result = int(g_result_amp/amp_coef)
                file.write(struct.pack('i', g_result))
                if i==3:
                    if j==253+3:
                        print("********253**************")
                        print(window.round())
                        print(g_result_amp)
                        print(g_result)

                # np.savetxt(file, window.flatten()[np.newaxis], fmt='%d')
                # 每个窗口的数据占一行
                
        
    print(f"Gaussian results have been saved to {output_name}")
            # print(g_result)

 
    return g_result


# 获取文件大小，单位为字节
def get_file_size(filename):
    size = os.path.getsize(filename)
    return size


def main():
    print("#################################################################")
    
    file_size = get_file_size(filename)
    image_num = int(file_size / width / hidth / (pix_bit / 8))  # 288#144
    img1 = load_raw_new(filename, image_num, hidth, width, pix_bit)
    for i in range(image_num):
        data = aaply_gaussian(img1[i])
        


if __name__ == "__main__":
    main()
