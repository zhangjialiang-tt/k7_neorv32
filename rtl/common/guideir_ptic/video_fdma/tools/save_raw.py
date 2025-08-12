from InfaredProcess import *
import json
import os
import subprocess
import shutil

# from cal_grad import *
from cal_demo import *


def main():
    width = 400
    height = 300
    endian = "little"
    signed = "unsigned"
    filename_src = r"E:\200-Learning\270-Learning-VIP\eis\sim\data\src_400x300.raw"
    # filename_src = r"E:\200-Learning\270-Learning-VIP\eis\sim\data\curr_frame.raw"
    filename_sim = "E:\\200-Learning\\270-Learning-VIP\\eis\\sim\\output\\"
    ip = InfaredProcess(filename_src, "y8", width, height)
    image_num = ip.get_file_size()
    print("image_num2", image_num)
    img1 = ip.loadraw_2mat(image_num, endian, signed)

    for i in range(50):
        print("reg [DW-1:0] reg_mem"+str(i) + "[0:WIDTH*HIDTH-1];")
    print("    task load_data2mem;")
    print("        begin")
    for i in range(50):
        print("            $readmemh(\"../output/"+str(i)+".txt\", reg_mem"+str(i)+");")
    print("        end")
    print("    endtask")
    for i in range(50):
        print(str(i) + " : data_tmp<=reg_mem" + str(i) + "[addr]; ")
    
    for i in range(50):
        ip.saveimage_to_simulation(
            img1[i], filename_sim + str(i) + ".txt", 8
        )


if __name__ == "__main__":
    main()
    # call_exe()
