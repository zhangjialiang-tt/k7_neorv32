from InfaredProcess import *
import numpy as np


def main():
    filename = "../sim/output/modelsim_post.raw"
    filename = "../sim/output/modelsim_post_climp.raw"
    filename_vs_1 = "../sim/data/vs_blockhist.raw"
    datatype = "y32"
    width = 1
    height = 4096
    # pix_bit = 16
    endian = "little"
    signed = "unsigned"

    processor = InfaredProcess(filename, datatype, width, height)
    image_num = processor.get_file_size()
    img1 = processor.loadraw_2mat(image_num, endian, signed)
    block_hist = img1.reshape(height * 1)

    # 提取block_hist前256个值
    block_hist2 = block_hist[0 * 256 : 1 * 256]  # block1
    block_hist2 = block_hist[1 * 256 : 2 * 256]  # block2
    block_hist2 = block_hist[2 * 256 : 3 * 256]  # block3
    block_hist2 = block_hist[3 * 256 : 4 * 256]  # block4
    block_hist2 = block_hist[4 * 256 : 5 * 256]  # block5
    block_hist2 = block_hist[5 * 256 : 6 * 256]  # block6
    block_hist2 = block_hist[6 * 256 : 7 * 256]  # block7
    block_hist2 = block_hist[7 * 256 : 8 * 256]  # block8
    block_hist2 = block_hist[8 * 256 : 9 * 256]  # block9
    block_hist2 = block_hist[9 * 256 : 10 * 256]  # block10
    block_hist2 = block_hist[10 * 256 : 11 * 256]  # block11
    block_hist2 = block_hist[11 * 256 : 12 * 256]  # block12
    block_hist_modelsim = block_hist[0 * 256 : 12 * 256]  # block12

    processor_vs_1 = InfaredProcess(filename_vs_1, datatype, 1, 256 * 12)
    image_num = processor_vs_1.get_file_size()
    img2 = processor_vs_1.loadraw_2mat(image_num, endian, signed)
    block_hist_vs = img2.reshape(256 * 12)

    diff = block_hist_modelsim - block_hist_vs
    # 打印diff中不等于0的值
    print(diff[diff != 0])

    print(InfaredProcess.__name__)


if __name__ == "__main__":
    main()
