import pandas as pd
import re

# 定义你的文件路径
file_path = '/mnt/data/combined_results3.txt'

# 初始化列表以保存提取的数据
filenames = []
ids = []
descriptions = []

# 正则表达式模式，用于匹配所需元素
file_pattern = r'^File: (.+?)\.txt$'
entry_pattern = r'^([a-z0-9]+) - (.+?), \d+ years, \d+ months ago : (.+)$'

# 打开并读取文件
with open(file_path, 'r') as file:
    lines = file.readlines()
    current_file = ""
    for line in lines:
        # 检查文件名行
        file_match = re.match(file_pattern, line.strip(), re.IGNORECASE)
        if file_match:
            current_file = file_match.group(1)  # 提取文件名
        else:
            # 检查条目行（id - 作者, 日期 : 描述）
            entry_match = re.match(entry_pattern, line.strip(), re.IGNORECASE)
            if entry_match:
                ids.append(entry_match.group(1))  # 提取ID
                descriptions.append(entry_match.group(3))  # 提取描述
                filenames.append(current_file)  # 添加当前文件名

# 创建DataFrame
df = pd.DataFrame({
    '文件名': filenames,
    'ID': ids,
    '描述': descriptions
})

# 定义输出CSV文件的路径
output_csv_path = '/mnt/data/extracted_data.csv'

# 将DataFrame保存到CSV文件
df.to_csv(output_csv_path, index=False, encoding='utf_8_sig')

output_csv_path
