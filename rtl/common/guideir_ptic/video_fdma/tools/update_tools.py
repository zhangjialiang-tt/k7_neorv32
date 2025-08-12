import requests
import os

# from download_tb import *


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


# 查询GitHub仓库文件列表
def get_github_file_list():
    # 替换为实际的GitHub用户名和仓库名
    username = "i540113104"
    repo_name = "zg_fpga"

    # GitHub API URL for listing the contents of a repository
    url = f"https://gitee.com/api/v5/repos/{username}/{repo_name}/git/trees/master?recursive=1"

    # 发送GET请求
    response = requests.get(url)

    # 检查请求是否成功
    if response.status_code == 200:
        # 解析响应数据
        tree = response.json()
        # 遍历文件列表，打印目录名为tools中所有文件
        for item in tree["tree"]:
            if item["path"].startswith("tools/"):
                filename = item["path"].split("/")[-1]
                url = "https://gitee.com/i540113104/zg_fpga/raw/master/" + item["path"]
                download_file_from_github(url, "../../tools/" + filename)
                print(url, filename)
        # 更新Makefile脚本
        url = "https://gitee.com/i540113104/zg_fpga/raw/master/sim/sub0-demo/makefile"
        filename = "makefile"
        download_file_from_github(url, filename)
        # 更新configuration.json
        url = "https://gitee.com/i540113104/zg_fpga/raw/master/sim/sub0-demo/configuration.json"
        filename = "configuration"
        download_file_from_github(url, filename)
    else:
        print("获取文件列表失败，状态码：", response.status_code)


def main():
    get_github_file_list()


if __name__ == "__main__":
    main()
