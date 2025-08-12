# -*- coding:UTF-8-*-
import cv2
import numpy as np
import struct
import os
import matplotlib.pyplot as plt


class InfaredProcess:
    def __init__(self, filename, datatype, width, height):
        self.a = 1
        self.filename = filename
        self.datatype = datatype
        self.width = width
        self.height = height
        if self.datatype == "y16":
            self.pix_bit = 16
        else:
            self.pix_bit = 8
        # self.endian = "little"
        # self.signed = 0
        # self.roi_en = 0
        # self.roi_width = self.width
        # self.roi_height = self.height

    # 文件加载方法

    def get_file_size(self):
        """
        Get the size of a file in bytes and calculate the number of images in the file.

        Args:
            filename (str): The path to the file.

        Returns:
            int: The number of images in the file.
        """
        # Get the size of the file
        file_size = os.path.getsize(self.filename)

        # Calculate the number of images
        if self.datatype == "y64":
            image_num = int(file_size / self.width / self.height / (64 / 8))
        elif self.datatype == "y32":
            image_num = int(file_size / self.width / self.height / (32 / 8))
        elif self.datatype == "y16":
            image_num = int(file_size / self.width / self.height / (16 / 8))
        elif self.datatype == "y8":
            image_num = int(file_size / self.width / self.height / (8 / 8))

        # Print file size and number of images
        # print("#################################################################")
        # print("File Size =  %d Bytes" % file_size)
        # print("Frame Number = %d " % image_num)
        # print("#################################################################")

        return image_num

    def loadbmp_2mat(self, image_num: int, endian: str, signed: str) -> np.ndarray:
        image = cv2.imread(self.filename, cv2.IMREAD_GRAYSCALE)
        print("hello world")
        return image

    # !使用Numpy库操作，大大缩小加载文件时间
    def loadraw_2mat(self, image_num: int, endian: str, signed: str) -> np.ndarray:
        """
        Load raw data from a file and convert it to a 2D matrix.

        Args:
            image_num (int): The number of images in the raw data.
            endian (str): The byte order of the raw data. Can be "big" or "little".
            signed (str): The signedness of the raw data. Can be "signed" or "unsigned".

        Returns:
            np.ndarray: The 2D matrix representation of the raw data.

        Raises:
            None
        """
        with open(self.filename, "rb") as raw_data:
            image1 = np.asarray(bytearray(raw_data.read()), dtype="uint8")

            # 将数组image1每8个字节组成一个64位的数据，组成新的数组image2
            # for i in range(8):
            #     image2 = image1[i::8] * pow(2, (8 + i))

            if self.datatype == "y64":
                if endian == "big":
                    image2 = (
                        image1[7::8] * pow(2, (8 * 0))
                        + image1[6::8] * pow(2, (8 * 1))
                        + image1[5::8] * pow(2, (8 * 2))
                        + image1[4::8] * pow(2, (8 * 3))
                        + image1[3::8] * pow(2, (8 * 4))
                        + image1[2::8] * pow(2, (8 * 5))
                        + image1[1::8] * pow(2, (8 * 6))
                        + image1[0::8] * pow(2, (8 * 7))
                    ).reshape(image_num, self.height, self.width)
                    if signed == "signed":
                        image3 = image2
                        # image3 = (pow(2, 64 - image2)) * (-1)
                        return image3.astype("int64")
                    else:
                        image3 = image2
                        return image3.astype("uint64")
                elif endian == "little":
                    image2 = (
                        image1[0::8] * pow(2, (8 * 0))
                        + image1[1::8] * pow(2, (8 * 1))
                        + image1[2::8] * pow(2, (8 * 2))
                        + image1[3::8] * pow(2, (8 * 3))
                        + image1[4::8] * pow(2, (8 * 4))
                        + image1[5::8] * pow(2, (8 * 5))
                        + image1[6::8] * pow(2, (8 * 6))
                        + image1[7::8] * pow(2, (8 * 7))
                    ).reshape(image_num, self.height, self.width)
                    if signed == "signed":
                        image3 = image2  # ((pow(2, 64 - image2)) - image2) * (-1)
                        return image3.astype("int64")
                    else:
                        image3 = image2
                        return image3.astype("uint64")
            elif self.datatype == "y32":
                if endian == "big":
                    image2 = (
                        image1[3::4] * pow(2, (8 * 0))
                        + image1[2::4] * pow(2, (8 * 1))
                        + image1[1::4] * pow(2, (8 * 2))
                        + image1[0::4] * pow(2, (8 * 3))
                    ).reshape(image_num, self.height, self.width)
                    if signed == "signed":
                        image3 = image2
                        # image3 = (pow(2, (8 * 2)) - image2) * (-1)
                        return image3.astype("int32")
                    else:
                        image3 = image2
                        return image3.astype("uint32")
                elif endian == "little":
                    image2 = (
                        image1[0::4] * pow(2, (8 * 0))
                        + image1[1::4] * pow(2, (8 * 1))
                        + image1[2::4] * pow(2, (8 * 2))
                        + image1[3::4] * pow(2, (8 * 3))
                    ).reshape(image_num, self.height, self.width)
                    if signed == "signed":
                        image3 = image2
                        # image3 = (pow(2, (8 * 2)) - image2) * (-1)
                        return image3.astype("int32")
                    else:
                        image3 = image2
                        return image3.astype("uint32")
            elif self.datatype == "y16":
                if endian == "big":
                    image2 = (image1[0::2] * pow(2, (8 * 1)) + image1[1::2]).reshape(
                        image_num, self.height, self.width
                    )
                    if signed == "signed":
                        image3 = image2
                        # image3 = (pow(2, (8 * 2)) - image2) * (-1)
                        return image3.astype("int16")
                    else:
                        image3 = image2
                        return image3.astype("uint16")
                elif endian == "little":
                    image2 = (image1[0::2] + image1[1::2] * pow(2, (8 * 1))).reshape(
                        image_num, self.height, self.width
                    )
                    if signed == "signed":
                        image3 = image2
                        # image3 = (pow(2, (8 * 2)) - image2) * (-1)
                        return image3.astype("int16")
                    else:
                        image3 = image2
                        return image3.astype("uint16")
            elif self.datatype == "y8":
                image2 = image1.reshape(image_num, self.height, self.width)
                if signed == "signed":
                    image3 = image2
                    # image3 = (256 - image2) * (-1)
                    return image3.astype("int8")
                else:
                    image3 = image2
                    return image3.astype("uint8")

            else:  # y8
                # If the data type is "y8"
                image2 = image1.reshape(image_num, self.height, self.width)

    # !使用Numpy库操作，大大缩小加载文件时间
    def loadraw_2mat_xy(self, endian: str, signed: str) -> np.ndarray:
        CUT = 128
        FH = 128
        nParaW = 6

        file_size = os.path.getsize(self.filename)
        total_frame_bytes = int(
            self.width * (self.height + nParaW) * (self.pix_bit / 8) + FH
        )
        image_num = int((file_size - CUT) / total_frame_bytes)  # 总帧数
        frame_size = self.width * self.height

        image6 = np.zeros((image_num, self.height, self.width))

        print("#################################################################")
        # print("File Size =", file_size, "Bytes")
        print("Frame Number = %d " % image_num)
        print("#################################################################")
        with open(self.filename, "rb") as raw_data:
            image1 = np.asarray(bytearray(raw_data.read()), dtype="uint8")
            # 对image先删掉前面的CUT个字节
            image2 = image1[CUT:]
            for i in range(image_num):
                # 截取一帧数据包
                image3 = image2[total_frame_bytes * i : total_frame_bytes * (i + 1)]
                # 截取数据包中有效图像数据
                image4 = image3[CUT : CUT + frame_size * 2]
                # 将字节数据转换为像素数据
                image5 = (image4[0::2] + image4[1::2] * 256).reshape(
                    self.height, self.width
                )
                image6[i] = image5

        return image6.astype("int16")

    def load_simulation_result(self, image_num: int) -> np.ndarray:
        """
        Load simulation result from a text file and reshape it to the desired shape.

        Parameters:
        image_num (int): The number of images in the simulation result.

        Returns:
        np.ndarray: The loaded simulation result as a numpy array with the desired shape.
        """
        # Load data from the text file
        image = np.loadtxt(self.filename, dtype=np.float64, usecols=(0), unpack=True)

        # Reshape the data to the desired shape
        image = image.reshape(image_num, self.height, self.width)

        return image

    # 保存为txt文件
    def saveimage_to_simulation(self, image, filename: str, pixByte: int) -> None:
        """
        Save the image data to a text file.

        Args:
            image (ndarray): The image data to be saved.

        Returns:
            None
        """
        if self.datatype == "y64":
            if pixByte == 64:
                np.savetxt(
                    filename, image.astype(dtype="uint64"), delimiter="\n", fmt="%X"
                )
        elif self.datatype == "y32":
            np.savetxt(filename, image.astype(dtype="uint32"), delimiter="\n", fmt="%X")
        elif self.datatype == "y16":
            np.savetxt(filename, image.astype(dtype="uint16"), delimiter="\n", fmt="%X")
        elif self.datatype == "y8":
            np.savetxt(filename, image.astype(dtype="uint8"), delimiter="\n", fmt="%X")

        # np.savetxt(filename, image.astype(dtype="uint16"), delimiter="\n", fmt="%X")

    def saveto_raw(self, image: np.ndarray, rawname: str, endian: str) -> None:
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

    def image_rect(self, image, start_x, start_y, roi_width, roi_height):
        return image[start_y : start_y + roi_height, start_x : start_x + roi_width]

    def image_reduce(self, image: np.ndarray, axis: int) -> np.ndarray:
        """
        Reduces the given image along the specified axis by taking the cumulative sum.

        Args:
            image (np.ndarray): The input image.
            axis (int): The axis along which the reduction should be performed.
            x=0 累加列
            x=1 累加行

        Returns:
            np.ndarray: The reduced image.
        """
        # Take the cumulative sum of the image along the specified axis
        vec_temp = np.cumsum(image, axis=axis)

        # Check if reduction should be performed along the rows (axis 0) or columns (axis 1)
        if axis == 0:
            # Return the last element of each row
            return vec_temp[-1, :]
        else:
            # Return the last element of each column
            return vec_temp[:, -1]

    def image_roi(self, image, roi_en, roi_width, roi_height):
        """
        Extracts a region of interest from an image.

        Args:
            image (numpy.ndarray): The input image.
            roi_en (int): Enable flag for region of interest extraction.

        Returns:
            numpy.ndarray: The extracted region of interest image if roi_en is 1,
                        otherwise returns the original image.
        """
        number, height, width = image.shape
        if roi_en == 1:
            image2 = np.zeros((number, roi_height, roi_width))
        else:
            image2 = np.zeros((number, height, width))
        for i in range(number):
            # print(i)
            start_y = int((height - roi_width) / 2)
            start_x = int((width - roi_height) / 2)

            if roi_en == 1:
                image2[i] = image[i][
                    start_y : start_y + roi_height, start_x : start_x + roi_width
                ]
                # return image[start_y : start_y + roi_height, start_x : start_x + roi_width]
            else:
                image2[i] = image[i]
                # return image
        return image2

    # 灰度映射
    def convertY8_single(self, image, equalize=True):
        """
        Convert a matrix of floating-point values to uint8 format.

        Args:
            image (ndarray): The input matrix.
            equalize (bool, optional): Whether to perform histogram equalization.
                Defaults to True.

        Returns:
            ndarray: The converted matrix.
        """
        # Calculate the minimum and maximum values in the matrix
        m_min = np.min(image)
        m_max = np.max(image)

        # Convert the matrix to the range [0, 255]
        post_image_8bit = (image - m_min) * 255.0 / (m_max - m_min)

        # Round the values and convert to uint8 type
        post_image_8bit = np.rint(post_image_8bit).astype(dtype="uint8")

        # Perform histogram equalization if required
        post_image_equalize = cv2.equalizeHist(post_image_8bit)

        # Choose the final output based on the equalize parameter
        if equalize:
            post_image = post_image_equalize
        else:
            post_image = post_image_8bit

        return post_image

    # 灰度映射
    def convertY8(self, image, equalize=True):
        """
        Convert a matrix of floating-point values to uint8 format.

        Args:
            image (ndarray): The input matrix.
            equalize (bool, optional): Whether to perform histogram equalization.
                Defaults to True.

        Returns:
            ndarray: The converted matrix.
        """

        number, height, width = image.shape
        post_image = np.zeros((number, height, width))
        for i in range(number):
            # Calculate the minimum and maximum values in the matrix
            m_min = np.min(image[i])
            m_max = np.max(image[i])

            # Convert the matrix to the range [0, 255]
            post_image_8bit = (image[i] - m_min) * 255.0 / (m_max - m_min)

            # Round the values and convert to uint8 type
            post_image_8bit = np.rint(post_image_8bit).astype(dtype="uint8")

            # Perform histogram equalization if required
            post_image_equalize = cv2.equalizeHist(post_image_8bit)

            # Choose the final output based on the equalize parameter
            if equalize:
                post_image[i] = post_image_equalize
            else:
                post_image[i] = post_image_8bit
            # self.show_img(post_image[i])
        return post_image

    def hist(self, image):
        """
        Calculate and plot the histogram of an image.

        Args:
            image (numpy.ndarray): The input image.

        Returns:
            None
        """

        # Get the number of rows and columns in the image
        rows, cols = image.shape

        # Initialize an array to store the histogram values
        xy = np.zeros([16384], np.uint64)

        # Calculate the histogram values
        for r in range(rows):
            for c in range(cols):
                xy[image[r][c]] += 1

        # Set the x-axis range for plotting
        x_range = range(16384)

        # Plot the histogram
        plt.plot(x_range, xy, "r", linewidth=2, c="red")

        # Set the y-axis range based on the maximum histogram value
        y_maxValue = np.max(xy)
        plt.axis([0, 16384 - 1, 0, y_maxValue])

        # Set the x-axis label
        plt.xlabel("gray Level")

        # Set the y-axis label
        plt.ylabel("number of pixels")

        # Display the histogram plot
        plt.show()

    def img_resize(self, image, post_x, post_y):
        """
        Resize the input image using the given parameters.

        Args:
            image (numpy.ndarray): The input image to be resized.
            post_x (int): The width of the output image.
            post_y (int): The height of the output image.

        Returns:
            numpy.ndarray: The resized image.
        """
        # Resize the image using the given width and height
        post_image = cv2.resize(image, (post_x, post_y))

        return post_image

    # 图像显示相关方法

    def show_img_y16(self, image):
        """
        Display the given image using a gray colormap and a colorbar.

        Args:
            image: The image to be displayed.
        """
        plt.imshow(image, cmap=plt.cm.gray)  # Display the image using a gray colormap
        plt.colorbar()  # Add a colorbar to the image
        plt.show()  # Show the image

    def show_img(self, image):
        cv2.imshow("image", image)
        cv2.waitKey(0)
        cv2.destroyAllWindows()

    def read_img(self, img_file):
        """
        Read an image file and return the image.
         Args:
            img_file (str): The path to the image file.
         Returns:
            numpy.ndarray: The image.
        """
        img = cv2.imread(img_file)
        return img


def main():
    filename = "./../data/filter1.raw"
    datatype = "y16"
    width = 640
    height = 512
    # pix_bit = 16
    endian = "little"
    signed = "unsigned"
    roi_en = 1
    roi_width = 128
    roi_height = 128

    processor = InfaredProcess(filename, datatype, width, height)
    image_num = processor.get_file_size()
    img1 = processor.loadraw_2mat(image_num, endian, signed)
    img2 = processor.image_roi(img1, roi_en, roi_width, roi_height)

    # processor.saveto_raw()
    # img2 = processor.image_rect(img1[0], 0, 0, height, width)
    # img3 = processor.convertY8(img2, equalize=True)
    # processor.show_img_y16(img2)
    processor.saveto_raw(img2[0:image_num], "./../data/test.raw", endian)

    print("hello")


if __name__ == "__main__":
    main()
