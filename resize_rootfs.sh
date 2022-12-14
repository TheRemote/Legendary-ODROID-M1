#!/bin/bash
#
# This script will resize the root filesystem to use all available storage on first startup
#
# More information available at:
# https://jamesachambers.com/legendary-odroid-m1-ubuntu-images/
# https://github.com/TheRemote/Legendary-ODROID-M1

set -e

if [ "$(id -u)" -ne "0" ]; then
	echo "This script requires root."
	exit 1
fi

echo "Resizing root filesystem -- please wait..."
echo "<4>resize_rootfs.sh: Resizing root filesystem -- please wait..." | tee /dev/kmsg

set -x

DEVICE=$(findmnt -n -o SOURCE --target / | cut -d'p' -f1)
PART="2"

resize() {
	start=$(fdisk -l ${DEVICE}|grep ${DEVICE}p${PART}|awk '{print $2}')
	echo $start

	set +e
	fdisk ${DEVICE} <<EOF
p
d
2
n
p
2
$start

w
EOF
	set -e

	partx -u ${DEVICE}
	resize2fs ${DEVICE}p${PART}
}

resize

# Run update-initramfs
echo "Running update-initramfs..."
echo "<4>resize_rootfs.sh: Running update-initramfs..." | tee /dev/kmsg
update-initramfs -u

echo "Done!"
