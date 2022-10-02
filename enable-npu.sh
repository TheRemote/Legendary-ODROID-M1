#!/bin/bash
#
# This script will enable the NPU (overlay not available yet in 22.04)
#
# More information available at:
# https://jamesachambers.com/legendary-odroid-m1-ubuntu-images/
# https://github.com/TheRemote/Legendary-ODROID-M1

echo "Enabling rknpu overlay..."
sudo sed -i 's/overlays="i2c0 i2c1 spi0"/overlays="i2c0 i2c1 spi0 rknpu"/g' /boot/config.ini

echo "Disabling SPI Petitboot mode..."
sudo fw_setenv skip_spiboot true

echo "Enabling rknpu kernel module..."
if ! grep -q "rknpu" /etc/modules; then echo "rknpu" | sudo tee -a /etc/modules >/dev/null; fi

echo "Done.  Please reboot your system!"