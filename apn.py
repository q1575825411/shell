import os
import sys
import xml.etree.ElementTree as ET
import pandas as pd

def parse_apn_from_xml(xml_file):
    """
    解析 XML 文件中的 APN 配置。
    """
    tree = ET.parse(xml_file)
    root = tree.getroot()
    apns_data = []

    for apn in root.findall('.//apn'):
        apn_data = apn.attrib  # 获取所有属性
        apns_data.append(apn_data)

    return apns_data

def analyze_apns_in_folder(folder_path):
    """
    分析指定文件夹下的所有 XML 文件，并整理 APN 配置到 DataFrame 中。
    """
    apns = []
    for file in os.listdir(folder_path):
        if file.endswith('.xml'):
            apns.extend(parse_apn_from_xml(os.path.join(folder_path, file)))

    return pd.DataFrame(apns)

def save_apns_to_excel(dataframe, folder_path):
    """
    将 DataFrame 保存为 Excel 文件。
    """
    output_file = os.path.join(folder_path, f"{os.path.basename(folder_path)}_apns.xlsx")
    dataframe.to_excel(output_file, index=False)
    print(f"Saved APN configurations to {output_file}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script.py <folder_path>")
        sys.exit(1)

    folder_path = sys.argv[1]
    apns_df = analyze_apns_in_folder(folder_path)
    save_apns_to_excel(apns_df, folder_path)
