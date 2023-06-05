#!/usr/bin/env bash

if [ ! -z $SUDO_USER ]; then
    UN=$SUDO_USER
else
    UN=$USER
fi

cat <<EOF | sudo tee /etc/udev/rules.d/100-brainstem.rules > /dev/null
# Acroname Brainstem control devices
SUBSYSTEM=="usb",ATTRS{idVendor}=="24ff",GROUP="dialout"

# NXP iMX HID device
KERNEL=="hidraw*",ATTRS{idVendor}=="1fc9",ATTRS{idProduct}=="0130",GROUP="dialout",MODE="0660"
EOF

sudo usermod -a -G dialout $UN

sudo udevadm control --reload-rules
