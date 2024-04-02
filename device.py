# -*- coding: utf-8 -*-
import subprocess
import threading
import os
import time
from datetime import datetime

# 获取连接的ADB设备列表
def get_adb_devices():
    result = subprocess.run(['adb', 'devices'], stdout=subprocess.PIPE)
    lines = result.stdout.decode('utf-8').splitlines()
    device_sns = [line.split('\t')[0] for line in lines if 'device' in line and not line.endswith('offline')]
    return device_sns

# 重启设备并抓取日志
def reboot_and_capture_logs(device_sn):
    print("正在重启设备 {} 并抓取日志...".format(device_sn))
    subprocess.run(['adb', '-s', device_sn, 'reboot'])
    print("等待设备 {} 重新连接...".format(device_sn))
    subprocess.run(['adb', '-s', device_sn, 'wait-for-device'])

    log_dir = "/home/zly/Desktop/log"
    os.makedirs(log_dir, exist_ok=True)
    log_file = os.path.join(log_dir, "{}_{}.log".format(device_sn, datetime.now().strftime('%Y%m%d_%H%M%S')))
    print("开始抓取设备 {} 的日志到 {}".format(device_sn, log_file))

    with open(log_file, 'w') as logfile:
        logcat_process = subprocess.Popen(['adb', '-s', device_sn, 'logcat', '-b', 'all'], stdout=logfile)
    
    time.sleep(30)

    print("停止抓取设备 {} 的日志。".format(device_sn))
    logcat_process.terminate()

# 主函数
def main():
    device_sns = get_adb_devices()
    if not device_sns:
        print("未检测到ADB设备，请连接设备后再试。")
        return
    
    print("已检测到以下设备序列号：")
    for device_sn in device_sns:
        print(device_sn)

    user_confirm = input("是否重启所有设备并抓取日志？(y/n): ")
    if user_confirm.lower() != 'y':
        print("用户取消操作。")
        return

    threads = []
    for device_sn in device_sns:
        thread = threading.Thread(target=reboot_and_capture_logs, args=(device_sn,))
        threads.append(thread)
        thread.start()

    for thread in threads:
        thread.join()

    print("所有操作已完成。")

if __name__ == "__main__":
    main()
