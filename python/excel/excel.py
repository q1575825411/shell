import pandas as pd
import re
import os
from datetime import datetime
from dateutil.relativedelta import relativedelta
import openpyxl
import sys

def convert_time_ago_to_timestamp(time_ago):
    current_time = datetime.now()
    parts = re.findall(r'(\d+)\s(years?|months?),?\s?', time_ago)
    years = months = 0
    
    for amount, unit in parts:
        if 'year' in unit:
            years = int(amount)
        elif 'month' in unit:
            months = int(amount)
    
    date_ago = current_time - relativedelta(years=years, months=months)
    return date_ago.strftime('%Y-%m')

def process_text_to_excel(file_path):
    if not os.path.exists(file_path):
        print(f"File not found: {file_path}")
        return

    base_dir = os.path.dirname(file_path)
    output_path = os.path.join(base_dir, os.path.basename(file_path).replace('.txt', '.xlsx'))
    
    file_block_pattern = re.compile(r'^=+\n文件名: (.+?)\.txt\n=+$', re.M)
    entry_pattern = re.compile(r'^([a-fA-F0-9]+) -- (.+?), (\d+ years?, \d+ months? ago) : (.+)$', re.M)
    
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            content = file.read()
    except IOError as e:
        print(f"Error reading file {file_path}: {e}")
        return
    
    file_blocks = re.split(file_block_pattern, content)[1:]
    writer = pd.ExcelWriter(output_path, engine='openpyxl')
    
    sheets_added = False
    for i in range(0, len(file_blocks), 2):
        sheet_name = file_blocks[i].replace('/', '_')[:31]
        entries = file_blocks[i + 1].strip().split('\n')
        
        data = []
        for entry in entries:
            match = entry_pattern.match(entry)
            if match:
                id_, submitter, time_ago, content = match.groups()
                timestamp = convert_time_ago_to_timestamp(time_ago)
                data.append([id_, submitter, timestamp, content])
        
        if data:
            df = pd.DataFrame(data, columns=['ID', '提交人', '时间', '提交内容'])
            df.to_excel(writer, sheet_name=sheet_name, index=False)
            sheets_added = True
    
    if sheets_added:
        writer.close()
        print(f"Excel file created at {output_path}")
    else:
        print("No data available to write to Excel.")
        writer.book.close()  # 关闭 Workbook 对象，避免文件损坏

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python script.py <path_to_file>")
    else:
        input_file_path = sys.argv[1]
        process_text_to_excel(input_file_path)
