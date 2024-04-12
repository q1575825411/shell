import sys
import pandas as pd
import re
from datetime import datetime
from dateutil.relativedelta import relativedelta
import chardet
import os
import openpyxl  # 确保已经安装了 openpyxl

def detect_encoding(file_path):
    with open(file_path, 'rb') as file:
        result = chardet.detect(file.read(10000))
    return result['encoding']

def convert_time_ago_to_timestamp(time_ago):
    current_time = datetime.now()
    numbers = re.findall(r'\d+', time_ago)
    years_ago = int(numbers[0]) if 'year' in time_ago or 'years' in time_ago else 0
    months_ago = int(numbers[-1]) if 'month' in time_ago or 'months' in time_ago else 0
    date_ago = current_time - relativedelta(years=years_ago, months=months_ago)
    return date_ago.strftime('%Y/%m/%d')

def remove_android_prefix(name):
    return name[7:] if name.startswith("android") else name

def shorten_sheet_name(name):
    return name[:28] + "..." if len(name) > 31 else name

def process_filename_for_sheet(name):
    return shorten_sheet_name(remove_android_prefix(name))

def adjust_column_width(sheet):
    for column in sheet.columns:
        max_length = max((len(str(cell.value)) if cell.value is not None else 0 for cell in column), default=10)
        column_width = openpyxl.utils.get_column_letter(column[0].column)
        sheet.column_dimensions[column_width].width = max_length + 2

def extract_data_to_excel(file_path):
    encoding = detect_encoding(file_path)
    file_pattern = re.compile(r'^File: (.+?)\.txt$')
    entry_pattern = re.compile(r'^([a-z0-9]+) - (.+?), (\d+ years, \d+ months ago) : (.+)$')

    filenames, ids, descriptions, times = [], [], [], []
    with open(file_path, 'r', encoding=encoding, errors='ignore') as file:
        for line in file:
            file_match = file_pattern.match(line.strip())
            if file_match:
                current_file = file_match.group(1)
            else:
                entry_match = entry_pattern.match(line.strip())
                if entry_match:
                    ids.append(entry_match.group(1))
                    times.append(convert_time_ago_to_timestamp(entry_match.group(3)))
                    descriptions.append(entry_match.group(4))
                    filenames.append(current_file)

    df = pd.DataFrame({
        '文件名': filenames,
        'ID': ids,
        '时间': times,
        '描述': descriptions
    }).drop_duplicates(subset=['描述'], keep='first')

    output_filename = os.path.splitext(os.path.basename(file_path))[0] + "_new.xlsx"
    output_xlsx_path = os.path.join(os.path.dirname(file_path), output_filename)
    with pd.ExcelWriter(output_xlsx_path, engine='openpyxl') as writer:
        for filename, group in df.groupby('文件名'):
            sheet_name = process_filename_for_sheet(filename)
            group.drop('文件名', axis=1).to_excel(writer, sheet_name=sheet_name, index=False)
            adjust_column_width(writer.sheets[sheet_name])

    return output_xlsx_path

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python extract_to_excel.py <file_path>")
        sys.exit(1)
    file_path = sys.argv[1]
    try:
        output_xlsx_path = extract_data_to_excel(file_path)
        print(f"数据已经被提取并保存到了: {output_xlsx_path}")
    except Exception as e:
        print(f"处理文件时出错: {e}")
