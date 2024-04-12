#!/bin/sh

# 增强的错误处理，任何命令的非零退出状态都将终止脚本
set -eu

# 检查参数个数
if [ $# -ne 2 ]; then
    echo "用法: $0 <创建目录> <目标目录>"
    exit 1
fi

# 创建源目录，如果它不存在
mkdir -p "$1"

# 检查目标目录是否存在
if [ ! -d "$2" ]; then
    echo "目标目录不存在: $2"
    exit 1
fi

# 使用 rsync 同步目录内容
rsync --delete-before -av --delete "$1/" "$2"

# 删除源目录
rm -rf "$1"

# 删除目标目录
rm -rf "$2"

# 列出当前目录下的文件和文件夹
ls
