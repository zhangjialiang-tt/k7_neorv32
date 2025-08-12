from InfaredProcess import *
import json


def cal_demo(image, height, width):
    demo_out = image + 1
    return demo_out


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
    json_file = (
        r"E:\100-Working\102-Working-Prj\hisp_fpga\sim\sub0-demo\configuration.json"
    )
    with open(json_file) as f:
        json_cfg = json.load(f)
    image_cfg = json_cfg["image"]
    image_path = image_cfg["path"]
    image_name = image_cfg["name"]
    image_mode = image_cfg["image_mode"]
    image_width = int(image_cfg["width"])
    image_height = int(image_cfg["height"])
    # filename_src = r"E:\100-Working\102-Working-Prj\hisp_fpga\sim\data\video_y16_640x480_100.raw"
    filename_src = (
        image_path + image_name
    )  # r"E:\100-Working\102-Working-Prj\hisp_fpga\sim\data\y16_640x480.raw"
    datatype = image_mode#"y16"
    # image_width = 640
    # image_height = 480
    endian = "little"
    signed = "unsigned"

    # print(InfaredProcess.__name__)

    # 加载原始数据
    ip1 = InfaredProcess(filename_src, datatype, image_width, image_height)
    # print(image_width)
    # print(image_height)
    image_num = ip1.get_file_size()
    img1 = ip1.loadraw_2mat(image_num, endian, signed)
    img1[0] = cal_demo(img1[0], image_height, image_width)
    saveto_raw(
        img1,
        r"E:\100-Working\102-Working-Prj\hisp_fpga\sim\data\to_be_compare.raw",
        "little",
    )
    print("File save successfully!")

if __name__ == "__main__":
    main()
