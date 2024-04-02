#!/bin/bash

# 获取设备序列号
device_sn=$(adb devices | grep 'device$' | awk '{print $1}')

if [ -z "$device_sn" ]; then
    echo "未检测到ADB设备，请连接设备后再试。"
    exit 1
fi

echo "检测到设备序列号为：$device_sn"
echo "是否重启设备？(y/n)"
read -r user_confirm

if [[ "$user_confirm" != "y" ]]; then
    echo "用户取消操作。"
    exit 0
fi

# 重启ADB设备
adb -s "$device_sn" reboot
echo "设备重启中，请稍候..."

# 等待设备重新连接
echo -n "等待ADB设备连接"
until adb -s "$device_sn" wait-for-device; do
    echo -n "."
    sleep 0.1
done
echo " 设备已连接，准备执行命令..."

# 设备连接后执行的命令
if adb -s "$device_sn" root; then
    echo "已获取root权限。"
    if adb -s "$device_sn" shell setenforce 0; then
        echo "SELinux设置为宽容模式。"
        # 定义日志文件路径，确保正确使用变量
        log_file="/home/zly/Desktop/log/${device_sn}_$(date +%Y%m%d_%H%M%S).log"
        # 开始抓取日志并重定向到文件，运行在后台
        adb -s "$device_sn" logcat -b all > "$log_file" &
        LOGCAT_PID=$!
        echo "日志正在写入：$log_file"
        # 等待25秒
        sleep 30
        # 杀死日志抓取进程，停止抓取日志
        kill "$LOGCAT_PID"
        echo "已停止日志抓取。"
    else
        echo "设置SELinux宽容模式失败。"
        exit 1
    fi
else
    echo "获取root权限失败。"
    exit 1
fi
