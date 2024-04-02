#!/bin/bash

# 定义要存放所有仓库历史提交信息的根目录
root_output_dir="$(pwd)/History_cord"

# 确保目录存在，如果不存在则创建
mkdir -p "$root_output_dir"

# 使用 repo 命令获取所有项目的相对路径列表，并检查是否成功执行
if repo_paths=$(repo forall -c 'echo $REPO_PATH'); then
    echo "Successfully listed all repositories."
else
    echo "Failed to list repositories using 'repo forall'."
    exit 1
fi

echo "$repo_paths" | while IFS= read -r repo_path; do
    if [ -z "$repo_path" ]; then
        continue
    fi

    absolute_repo_path=$(realpath "$repo_path")
    echo "Processing repository: $repo_path ..."
    echo "Absolute path: $absolute_repo_path"

    # 使用 sed 命令来替换斜杠为下划线
    repo_output_dir_name=$(echo "$repo_path" | sed 's/\//_/g')
    repo_output_dir="${root_output_dir}/${repo_output_dir_name}"
    mkdir -p "$repo_output_dir"

    output_file="${repo_output_dir}/${repo_output_dir_name}.txt"

    echo "Output will be saved to: $output_file"

    if git -C "$absolute_repo_path" log --pretty=format:"%h - %an, %ar : %s" > "$output_file"; then
        echo "Commit history for $repo_path saved to $output_file"
    else
        echo "Failed to get commit history for $repo_path"
    fi
done

echo "All repositories' commit histories have been processed."
