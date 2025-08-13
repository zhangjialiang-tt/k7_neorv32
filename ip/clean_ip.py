import os

# 定义要保留的文件后缀
KEEP_EXTENSIONS = {".xci", ".prj", ".py", ".coe"}

# 获取脚本所在目录
script_dir = os.path.dirname(os.path.abspath(__file__))

# 递归遍历目录
for root, dirs, files in os.walk(script_dir):
    # 跳过uisrc目录
    if 'uisrc' in dirs:
        dirs.remove('uisrc')
        
    # 跳过neorv32目录
    if 'neorv32' in dirs:
        dirs.remove('neorv32')
        
    for filename in files:
        file_path = os.path.join(root, filename)

        # 获取文件扩展名
        _, ext = os.path.splitext(filename)

        # 如果是 .gitignore 文件，跳过删除
        if filename == ".gitignore":
            continue

        # 如果扩展名不在保留列表中，则删除
        if ext not in KEEP_EXTENSIONS:
            print(f"正在删除: {file_path}")
            os.remove(file_path)

print("递归清理完成！")
