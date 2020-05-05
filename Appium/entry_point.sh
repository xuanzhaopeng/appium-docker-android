#!/bin/bash

NODE_CONFIG_JSON="/root/nodeconfig.json"
DEFAULT_CAPABILITIES_JSON="/root/defaultcapabilities.json"
APPIUM_LOG="/var/log/appium.log"
CMD="/usr/bin/node /usr/bin/appium --log $APPIUM_LOG"

if [ ! -z "$USB_BUS" ]; then
    try="0"
    while [ $try -lt 3 ]; do
        /root/usbreset $USB_BUS
        devices=($(adb devices | grep -oP "\K([^ ]+)(?=\sdevice(\W|$))"))
        count=${#devices[@]}
        if (( $count < 1 )); then
             echo "Try to reset usb: $try"
             sleep 1
             try=$[$try+1]
        else
             break;
        fi
    done
fi  

if [ "$CONNECT_TO_GRID" = true ]; then
    if [ "$CUSTOM_NODE_CONFIG" != true ]; then
        /root/generate_config.sh $NODE_CONFIG_JSON
    fi
    CMD+=" --nodeconfig $NODE_CONFIG_JSON"
fi

if [ "$DEFAULT_CAPABILITIES" = true ]; then
    CMD+=" --default-capabilities $DEFAULT_CAPABILITIES_JSON"
fi

if [ "$RELAXED_SECURITY" = true ]; then
    CMD+=" --relaxed-security"
fi

CMD+=" > /dev/null 2>&1 &"

rm -rf restart.sh
touch restart.sh
echo -e '#!/bin/bash' >> restart.sh
echo -e 'pgrep -f appium | xargs kill -9' >> restart.sh
echo -e 'old_device_unique_id=$1' >> restart.sh
echo -e 'new_device_unique_id=$2' >> restart.sh
echo -e 'sed -i s/$old_device_unique_id/$new_device_unique_id/g nodeconfig.json' >> restart.sh
echo -e $CMD >> restart.sh
chmod +x restart.sh

pkill -x Xvfb
rm -rf /tmp/.X99-lock

# http://elementalselenium.com/tips/38-headless
# https://github.com/appium/appium/issues/5446
Xvfb :99 -ac -screen 0 640x480x8 -nolisten tcp &
xvfb=$!

export DISPLAY=:99

$CMD

wait $xvfb