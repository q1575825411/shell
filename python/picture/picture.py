# main.py

import requests
from urllib.parse import urlparse, unquote
import os
import shutil
from config import API_URL, USER_AGENT, SAVE_DIR_BASE, COPY_DIR_BASE, sort_options, size_options, size_r18_options

session = requests.Session()
session.headers.update({'User-Agent': USER_AGENT})

def save_image(image_url, save_path):
    """下载并保存图片到指定路径，文件名从URL中提取。"""
    # 从URL解析出文件名
    parsed_url = urlparse(image_url)
    # 解码URL编码的文件名（如果有的话），并从路径中提取文件名
    file_name = unquote(parsed_url.path.split('/')[-1])
    # 构造完整的保存路径
    full_save_path = os.path.join(save_path, file_name)

    if not os.path.exists(full_save_path):  # 检查图片是否已存在
        try:
            response = session.get(image_url, stream=True)  # 使用会话发送请求
            response.raise_for_status()  # 检查请求是否成功
            with open(full_save_path, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    f.write(chunk)
            print(f"Image saved to {full_save_path}")
        except requests.RequestException as e:
            print(f"Failed to save image: {e}")
    else:
        print(f"Image already exists: {full_save_path}")
    copy_if_newer(save_path,COPY_DIR_BASE)

def copy_if_newer(src_dir, dst_dir):
    """
    复制src_dir中的所有文件到dst_dir，但只复制那些在dst_dir中不存在，
    或者比dst_dir中同名文件更新的文件。
    """
    for src_dirname, dirs, files in os.walk(src_dir):
        dst_dirname = src_dirname.replace(src_dir, dst_dir, 1)

        # 确保目标目录存在
        os.makedirs(dst_dirname, exist_ok=True)

        for file in files:
            src_file = os.path.join(src_dirname, file)
            dst_file = os.path.join(dst_dirname, file)

            # 如果目标文件不存在或源文件更新，则复制文件
            if not os.path.exists(dst_file) or os.path.getmtime(src_file) > os.path.getmtime(dst_file):
                shutil.copy2(src_file, dst_file)

def get_user_choice(options, prompt):
    """让用户选择一个选项，并返回对应的值。"""
    while True:
        print(prompt)
        for key, value in options.items():
            print(f"{key}: {value}")
        choice = input("Enter your choice: ")
        if choice in options:
            return options[choice]
        else:
            print("Invalid choice, please try again.")

def fetch_image():
    """根据用户选择获取并保存图片。"""
    sort = get_user_choice(sort_options, "Choose sort option:")
    if sort == 'r18':
        size = get_user_choice(size_r18_options, "Choose size option for r18:")
        save_dir = os.path.join(SAVE_DIR_BASE, 'r18')
    else:
        size = get_user_choice(size_options, "Choose size option:")
        save_dir = os.path.join(SAVE_DIR_BASE, sort)

    num = input("Enter number of images (1-100): ")

    # 构建请求参数
    params = {
        'sort': sort,
        'size': size,
        'type': 'json',
        'num': num
    }

    # 确保保存目录存在
    if not os.path.exists(save_dir):
        os.makedirs(save_dir)

    # 使用会话对象发送请求
    try:
        response = session.get(API_URL, params=params)
        response.raise_for_status()  # 检查响应状态码，确保请求成功

        data = response.json()
        if 'pics' in data:
            image_urls = data['pics']
            for image_url in image_urls:
                save_image(image_url, save_dir)
        else:
            print("No images returned by the API.")
    except requests.RequestException as e:
        print(f"Failed to fetch images: {e}")
    except ValueError:
        print("Failed to decode the JSON response.")


if __name__ == "__main__":
    fetch_image()