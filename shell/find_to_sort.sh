#!/bin/bash

# --- 第一部分：获取并记录提交历史 ---
# 定义用于存储所有仓库历史提交信息的根目录
root_output_dir="$(pwd)/History_cord"
mkdir -p "$root_output_dir"

# 使用 'repo' 命令获取所有项目的相对路径，并检查是否执行成功
repo_paths=$(repo forall -c 'echo $REPO_PATH')
if [ $? -ne 0 ]; then
    echo "使用 'repo forall' 获取仓库列表失败。"
    exit 1
else
    echo "成功列出所有仓库。"
fi

# 处理每个仓库路径
while IFS= read -r repo_path; do
    if [ -z "$repo_path" ]; then
        continue
    fi

    absolute_repo_path=$(realpath "$repo_path")
    echo "正在处理仓库: $repo_path ..."
    echo "绝对路径: $absolute_repo_path"

    repo_output_dir_name=$(echo "$repo_path" | sed 's/\//_/g')
    repo_output_dir="${root_output_dir}/${repo_output_dir_name}"
    mkdir -p "$repo_output_dir"

    output_file="${repo_output_dir}/${repo_output_dir_name}.txt"
    echo "输出将保存到: $output_file"

    if ! git -C "$absolute_repo_path" log --pretty=format:"%h - %an, %ar : %s" > "$output_file"; then
        echo "获取 $repo_path 的提交历史失败"
    fi
done <<< "$repo_paths"

echo "所有仓库的提交历史已经处理完毕。"

# --- 第二部分：合并和排序结果 ---
result_file="$(pwd)/combined_results.txt"
> "$result_file"

delimiter="=================================================================="

find "$root_output_dir" -type f -name "*.txt" -print0 | sort -z | while IFS= read -r -d $'\0' txt_file; do
    file_name=$(basename "$txt_file")
    content=$(<"$txt_file")
    line_count=$(echo "$content" | wc -l)

    if [ "$line_count" -eq 1 ] && [[ "$content" == *"initialize platform base chipcode"* ]]; then
        continue
    fi

    printf "\n%s\n文件名: %s\n%s\n" "$delimiter" "$file_name" "$delimiter" >> "$result_file"
    grep -v -E "tag_SP3115_V|\[SP3915|\[SP3136|\[SP3115" "$txt_file" >> "$result_file"
done

echo "操作完成，所有符合条件的文件内容已整合到 $result_file 中。"
