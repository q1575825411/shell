#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <HEMA_OTA_VERSION>"
    exit 1
fi

export HEMA_OTA_VERSION=$1
export SCREEN_SIZE=1920x1080

if [ ! -f ./build.sh ]; then
    exit_with_error "build.sh not found."
fi

./build.sh -j64

if [ $? -ne 0 ]; then
    exit_with_error "build.sh failed."
fi

echo "Script executed successfully."

exit