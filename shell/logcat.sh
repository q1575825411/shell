#!/bin/bash

# 获取所有已连接设备的序列号
device_sns=($(adb devices | grep 'device$' | awk '{print $1}'))

if [ ${#device_sns[@]} -eq 0 ]; then
    echo "未检测到ADB设备，请连接设备后再试。"
    exit 1
fi

echo "已检测到以下设备序列号："
for device_sn in "${device_sns[@]}"; do
    echo "$device_sn"
done

# 询问用户是否重启所有设备并抓取日志
echo "是否重启所有设备并抓取日志？(y/n)"
read -r user_confirm

if [[ "$user_confirm" != "y" ]]; then
    echo "用户取消操作。"
    exit 0
fi

# 重启每个设备并抓取日志
for device_sn in "${device_sns[@]}"; do
    echo "正在重启设备 $device_sn 并抓取日志..."
    adb -s "$device_sn" reboot

    echo "等待设备 $device_sn 重新连接..."
    adb -s "$device_sn" wait-for-device

    log_file="/home/zly/Desktop/log/${device_sn}_$(date +%Y%m%d_%H%M%S).log"
    echo "开始抓取设备 $device_sn 的日志到 $log_file"
    adb -s "$device_sn" logcat -b all > "$log_file" &
    LOGCAT_PID=$!

    # 根据需要调整等待时间
    sleep 30

    echo "停止抓取设备 $device_sn 的日志。"
    kill "$LOGCAT_PID"
done

echo "所有操作已完成。"
