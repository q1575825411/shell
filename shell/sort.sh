#!/bin/bash

# 指定要遍历的目录
specified_dir="$(pwd)/History_cord"
# 结果记录在同级目录下的文件名
result_file="$(pwd)/combined_results.txt"

# 确保结果文件是空的
> "$result_file"

# 定义美观的分割线
delimiter="=============================================================================================================================="

# 使用 find 命令查找所有 txt 文件，并排序
find "$specified_dir" -type f -name "*.txt" | sort | while read txt_file; do
    # 获取文件名，用作分割标准
    file_name=$(basename "$txt_file")

    # 使用 awk 读取文件内容，判断是否只有一行且包含特定内容
    content=$(<"$txt_file")
    line_count=$(echo "$content" | wc -l)
    
    if [ "$line_count" -eq 1 ] && [[ "$content" == *"initialize platform base chipcode"* ]]; then
        # 如果文件只有一行且内容包含特定字符串，则忽略该文件
        continue
    fi

    # 将分隔符和文件名添加到结果中（使用 echo -e 可能不在所有环境中有效）
    printf "\n%s\nFile: %s\n%s\n" "$delimiter" "$file_name" "$delimiter" >> "$result_file"

    # 过滤内容，并将结果追加到结果文件
    grep -v -E "tag_SP3115_V|\[SP3915|\[SP3136|\[SP3115" "$txt_file" >> "$result_file"
done

echo "操作完成，所有符合条件的文件内容已整合到 $result_file 中。"
