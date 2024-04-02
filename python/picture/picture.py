import requests
import os
from urllib.parse import urlparse, unquote

# 参数映射表
sort_options = {
    '1': 'all',
    '2': 'mp',
    '3': 'pc',
    '4': 'silver',
    '5': 'furry',
    '6': 'r18',
    '7': 'pixiv',
    '8': 'jitsu',
}
size_options = {
    # '1': 'large',
    '2': 'mw2048',
    '3': 'mw1024',
    '4': 'mw690',
    '5': 'small',
    '6': 'bmiddle',
    '7': 'thumb180',
    '8': 'square',
}
size_r18_options = {
    '1': 'original',
    '2': 'regular',
    '3': 'small',
}

def save_image(image_url, save_path):
    """下载并保存图片到指定路径，文件名从URL中提取。"""
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'
    }
    # 从URL解析出文件名
    parsed_url = urlparse(image_url)
    # 解码URL编码的文件名（如果有的话），并从路径中提取文件名
    file_name = unquote(parsed_url.path.split('/')[-1])
    # 构造完整的保存路径
    full_save_path = os.path.join(save_path, file_name)

    if not os.path.exists(full_save_path):  # 检查图片是否已存在
        try:
            response = requests.get(image_url, headers=headers)
            response.raise_for_status()  # 确保请求成功
            with open(full_save_path, 'wb') as f:
                f.write(response.content)
            print(f"Image saved to {full_save_path}")
        except requests.RequestException as e:
            print(f"Failed to save image: {e}")
    else:
        print(f"Image already exists: {full_save_path}")


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
    """根据用户选择的参数获取并保存图片。"""
    sort = get_user_choice(sort_options, "Choose sort option:")
    # 根据用户选择的图片类型设置保存目录
    if sort == 'r18':
        save_dir = 'pics/r20'
    else:
        save_dir = 'pics/r10'

    size = get_user_choice(size_r18_options if sort == 'r18' else size_options, "Choose size option:")
    num = input("Enter number of images (1-100): ")

    params = {
        'sort': sort,
        'size': size,
        'type': 'json',
        'num': num
    }

    response = requests.get("https://moe.jitsu.top/img/", params=params)
    if response.status_code == 200:
        data = response.json()
        if 'pics' in data:  # 确认返回数据中有'pics'字段
            image_urls = data['pics']
            # 确保保存目录存在
            os.makedirs(save_dir, exist_ok=True)
            for i, image_url in enumerate(image_urls, start=1):
                save_image(image_url, save_dir)  # 使用动态确定的保存目录
        else:
            print("No images returned by the API.")
    else:
        print("Failed to fetch images or invalid response format")

if __name__ == "__main__":
    fetch_image()