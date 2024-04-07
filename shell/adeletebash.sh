#!/bin/sh
if [ $# -ne 2 ]; then
    echo "用法: $0 <创建目录> <目标目录>"
    exit 1
fi

if [ ! -d "$1" ]; then
    mkdir -p "$1"
    if [ $? -ne 0 ]; then
        echo "无法创建目录: $1"
        exit 1
    fi
fi


if [ ! -d "$2" ]; then
    echo "目标目录不存在: $2"
    exit 1
fi

rsync --delete-before -av --delete "$1/" "$2"

if [ $? -ne 0 ]; then
    echo "复制时出现错误"
    exit 1
fi

rm -rf "$1"
if [ $? -ne 0 ]; then
    echo "无法删除目录: $1"
fi

rm -rf "$2"
if [ $? -ne 0 ]; then
    echo "无法删除目录: $2"
fi

ls

