#!/bin/bash
#
# This script will disable the NPU (overlay not available yet in 22.04)
#
# More information available at:
# https://jamesachambers.com/legendary-odroid-m1-ubuntu-images/
# https://github.com/TheRemote/Legendary-ODROID-M1

echo "Disabling rknpu overlay..."
sudo sed -i 's/overlays="i2c0 i2c1 spi0 rknpu"/overlays="i2c0 i2c1 spi0"/g' /boot/config.ini

echo "Reenabling SPI Petitboot mode..."
sudo fw_setenv skip_spiboot false

echo "Disabling rknpu kernel module..."
if grep -q "rknpu" /etc/modules; then sudo sed -i '/rknpu/d' /etc/modules; fi

echo "Done.  Please reboot your system!"