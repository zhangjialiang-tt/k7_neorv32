import requests


def download_file_from_github(url, filename):
    # 发送GET请求
    response = requests.get(url, stream=True)

    # 检查请求是否成功
    if response.status_code == 200:
        # 打开文件以二进制写入模式
        with open(filename, "wb") as f:
            # 以块的形式读取数据并写入文件
            for chunk in response.iter_content(chunk_size=8192):
                if chunk:
                    f.write(chunk)
                    f.flush()  # 确保数据被写入磁盘
        print(f"文件 {filename} 下载成功！")
    else:
        print(f"请求失败，状态码：{response.status_code}")

def main():
    print("Downloading Testbench...")

    # GitHub上的文件URL  
    file_url = 'https://gitee.com/i540113104/zg_fpga/raw/master/BasicModule/modelsim_simulation_template/sim/tb_image.v'  
    # 本地保存的文件名  
    local_filename = '../sim/tb.v'  
    
    # 调用函数下载文件  
    download_file_from_github(file_url, local_filename)


if __name__ == "__main__":
    main()
