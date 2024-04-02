#!/system/bin/sh

MAC_ADDRESS=$(cat /sys/class/net/eth0/address)
setprop persist.eth.mac.address0 "$MAC_ADDRESS"
MAC_ADDRESS=$(cat /sys/class/net/eth1/address)
setprop persist.eth.mac.address1 "$MAC_ADDRESS"
MAC_ADDRESS=$(cat /sys/class/net/wlan0/address)
setprop persist.wlan.mac.address0 "$MAC_ADDRESS"
