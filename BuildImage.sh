#!/bin/bash
#
# This script will download and update the ODROID M1 20.04 image to 22.04
#
# More information available at:
# https://jamesachambers.com/legendary-odroid-m1-ubuntu-images/
# https://github.com/TheRemote/Legendary-ODROID-M1
# Dependencies - build-essential guestfs-tools kpartx

# CONFIGURATION

IMAGE_VERSION="v1.2"
SOURCE_RELEASE="20.04"
DEST_RELEASE="22.04.1"
TARGET_IMG="legendary-ubuntu-${DEST_RELEASE}-server-odroidm1-${IMAGE_VERSION}.img"
TARGET_IMGXZ="legendary-ubuntu-${DEST_RELEASE}-server-odroidm1-${IMAGE_VERSION}.tar.xz"
DESKTOP_IMG="legendary-ubuntu-${DEST_RELEASE}-desktop-odroidm1-${IMAGE_VERSION}.img"
DESKTOP_IMGXZ="legendary-ubuntu-${DEST_RELEASE}-desktop-odroidm1-${IMAGE_VERSION}.tar.xz"
MATE_DESKTOP_IMG="legendary-ubuntu-${DEST_RELEASE}-mate-desktop-odroidm1-${IMAGE_VERSION}.img"
MATE_DESKTOP_IMGXZ="legendary-ubuntu-${DEST_RELEASE}-mate-desktop-odroidm1-${IMAGE_VERSION}.tar.xz"
KUBUNTU_DESKTOP_IMG="legendary-kubuntu-${DEST_RELEASE}-desktop-odroidm1-${IMAGE_VERSION}.img"
KUBUNTU_DESKTOP_IMGXZ="legendary-kubuntu-${DEST_RELEASE}-desktop-odroidm1-${IMAGE_VERSION}.tar.xz"
XUBUNTU_DESKTOP_IMG="legendary-xubuntu-${DEST_RELEASE}-desktop-odroidm1-${IMAGE_VERSION}.img"
XUBUNTU_DESKTOP_IMGXZ="legendary-xubuntu-${DEST_RELEASE}-desktop-odroidm1-${IMAGE_VERSION}.tar.xz"
LUBUNTU_DESKTOP_IMG="legendary-lubuntu-${DEST_RELEASE}-desktop-odroidm1-${IMAGE_VERSION}.img"
LUBUNTU_DESKTOP_IMGXZ="legendary-lubuntu-${DEST_RELEASE}-desktop-odroidm1-${IMAGE_VERSION}.tar.xz"
SOURCE_IMG="ubuntu-${SOURCE_RELEASE}-server-odroidm1-20220531.img"
SOURCE_IMGXZ="ubuntu-${SOURCE_RELEASE}-server-odroidm1-20220531.img.xz"
UPDATED_IMG="ubuntu-${DEST_RELEASE}-server-odroidm1.img"
UPDATED_DESKTOP_IMG="ubuntu-${DEST_RELEASE}-desktop-odroidm1.img"
UPDATED_MATE_IMG="ubuntu-${DEST_RELEASE}-mate-desktop-odroidm1.img"
UPDATED_XUBUNTU_IMG="xubuntu-${DEST_RELEASE}-desktop-odroidm1.img"
UPDATED_KUBUNTU_IMG="kubuntu-${DEST_RELEASE}-desktop-odroidm1.img"
UPDATED_LUBUNTU_IMG="lubuntu-${DEST_RELEASE}-desktop-odroidm1.img"

export SLEEP_SHORT="0.2"
export SLEEP_LONG="1"

export MOUNT_IMG=""
export KERNEL_VERSION=""

# FUNCTIONS
function PrepareIMG() {
    while mountpoint -q /mnt/boot && ! sudo umount /mnt/boot; do
        echo "/mnt/boot still mounted -- unmounting"
        sync
        sync
        sleep "${SLEEP_SHORT}"
    done

    while mountpoint -q /mnt/proc && ! sudo umount /mnt/proc; do
        echo "/mnt/proc still mounted -- unmounting"
        sync
        sync
        sleep "${SLEEP_SHORT}"
    done

    while mountpoint -q /mnt/sys && ! sudo umount /mnt/sys; do
        echo "/mnt/sys still mounted -- unmounting"
        sync
        sync
        sleep "${SLEEP_SHORT}"
    done

    while mountpoint -q /mnt/tmp && ! sudo umount -f /mnt/tmp; do
        sync
        sync
        sleep "${SLEEP_SHORT}"
    done

    while mountpoint -q /mnt/dev/null && ! sudo umount -f /mnt/dev/null; do
        sync
        sync
        sleep "${SLEEP_SHORT}"
    done

    while mountpoint -q /mnt/dev/random && ! sudo umount -f /mnt/dev/random; do
        sync
        sync
        sleep "${SLEEP_SHORT}"
    done

    while mountpoint -q /mnt/dev/urandom && ! sudo umount -f /mnt/dev/urandom; do
        sync
        sync
        sleep "${SLEEP_SHORT}"
    done

    while mountpoint -q /mnt/dev/pts && ! sudo umount -f /mnt/dev/pts; do
        sync
        sync
        sleep "${SLEEP_SHORT}"
    done

    while mountpoint -q /mnt && ! sudo umount /mnt; do
        echo "/mnt still mounted -- unmounting"
        sync
        sync
        sleep "${SLEEP_SHORT}"
    done

    MountCheck=$(sudo losetup --list | grep "(deleted)" | awk 'NR==1{ print $1 }')
    while [ -n "$MountCheck" ]; do
        echo "Leftover image $MountCheck found -- removing"
        # sudo rm -rf $MountCheck
        sudo kpartx -dv "${MountCheck%p1}"
        sleep "${SLEEP_SHORT}"
        sudo losetup -D
        sleep "${SLEEP_SHORT}"
        MountCheck=$(sudo losetup --list | grep "(deleted)" | awk 'NR==1{ print $1 }')
    done

    MountCheck=$(sudo losetup --list | grep "legendary-" | awk 'NR==1{ print $1 }')
    while [ -n "$MountCheck" ]; do
        echo "Leftover legendary-image $MountCheck found -- removing"
        # sudo rm -rf $MountCheck
        sudo kpartx -dv "${MountCheck%p1}"
        sleep "${SLEEP_SHORT}"
        sudo losetup -D
        sleep "${SLEEP_SHORT}"
        MountCheck=$(sudo losetup --list | grep "legendary-" | awk 'NR==1{ print $1 }')
    done
}

function MountIMG() {
    if [ -n "${MOUNT_IMG}" ]; then
        echo "An image is already mounted on ${MOUNT_IMG}"
        return 1
    fi
    if [ ! -e "${1}" ]; then
        echo "Image ${1} does not exist!"
        return 1
    fi

    echo "Mounting image ${1}"
    MountCheck=$(sudo kpartx -avs "${1}")
    echo "$MountCheck"
    export MOUNT_IMG=$(echo "$MountCheck" | awk 'NR==1{ print $3 }')
    export MOUNT_IMG="${MOUNT_IMG%p1}"

    if [ -n "${MOUNT_IMG}" ]; then
        sync
        sync
        sleep "${SLEEP_SHORT}"
        echo "Mounted ${1} on loop ${MOUNT_IMG}"
    else
        echo "Unable to mount ${1}: ${MOUNT_IMG} Check - $MountCheck"
        export MOUNT_IMG=""
    fi

    sync
    sync
    sleep "${SLEEP_SHORT}"
}

function MountIMGPartitions() {
    echo "Mounting partitions"
    # Mount the rootfs on /mnt (/)
    sudo mount "/dev/mapper/${1}p2" /mnt

    # Mount the bootfs on /mnt/boot (/boot)
    sudo mount "/dev/mapper/${1}p1" /mnt/boot

    sudo mount --bind /tmp "/mnt/tmp" &&
        sudo mount --bind /dev/null "/mnt/dev/null" &&
        sudo mount --bind /dev/pts "/mnt/dev/pts" &&
        sudo mount --bind /dev/random "/mnt/dev/random" &&
        sudo mount --bind /dev/urandom "/mnt/dev/urandom" &&
        sync
    sync
    sleep "${SLEEP_SHORT}"
}

function UnmountIMGPartitions() {
    sync
    sync

    # Unmount boot and root partitions
    echo "Unmounting partitions ..."
    while mountpoint -q /mnt/boot && ! sudo umount -f /mnt/boot; do
        sync
        sync
        sleep "${SLEEP_SHORT}"
    done

    while mountpoint -q /mnt/proc && ! sudo umount /mnt/proc; do
        sync
        sync
        sleep "${SLEEP_SHORT}"
    done

    while mountpoint -q /mnt/sys && ! sudo umount /mnt/sys; do
        sync
        sync
        sleep "${SLEEP_SHORT}"
    done

    while mountpoint -q /mnt/tmp && ! sudo umount -f /mnt/tmp; do
        sync
        sync
        sleep "${SLEEP_SHORT}"
    done

    while mountpoint -q /mnt/dev/null && ! sudo umount -f /mnt/dev/null; do
        sync
        sync
        sleep "${SLEEP_SHORT}"
    done

    while mountpoint -q /mnt/dev/random && ! sudo umount -f /mnt/dev/random; do
        sync
        sync
        sleep "${SLEEP_SHORT}"
    done

    while mountpoint -q /mnt/dev/urandom && ! sudo umount -f /mnt/dev/urandom; do
        sync
        sync
        sleep "${SLEEP_SHORT}"
    done

    while mountpoint -q /mnt/dev/pts && ! sudo umount -f /mnt/dev/pts; do
        sync
        sync
        sleep "${SLEEP_SHORT}"
    done

    while mountpoint -q /mnt && ! sudo umount -f /mnt; do
        sync
        sync
        sleep "${SLEEP_SHORT}"
    done

    sync
    sync
}

function UnmountIMG() {
    # Unmount image and save changes
    sync
    sync

    # Check if image is mounted first
    MountCheck=$(sudo losetup --list | grep "${1}")
    if [ ! -n "$MountCheck" ]; then
        echo "Unable to unmount $1 (not in losetup --list)"
        UnmountIMGPartitions
        export MOUNT_IMG=""
        return
    fi

    echo "Unmounting $1"
    UnmountIMGPartitions
    sudo kpartx -dvs "/dev/${MOUNT_IMG}"
    sync
    sync
    sleep "${SLEEP_LONG}"
    sudo losetup -D

    MountCheck=$(sudo losetup --list | grep "legendary-" | awk 'NR==1{ print $1 }')
    while [ -n "$MountCheck" ]; do
        echo "Leftover legendary-image $MountCheck found -- removing"
        # sudo rm -rf $MountCheck
        sudo kpartx -dv "${MountCheck%p1}"
        sleep "${SLEEP_SHORT}"
        sudo losetup -D
        sleep "${SLEEP_SHORT}"
        MountCheck=$(sudo losetup --list | grep "legendary-" | awk 'NR==1{ print $1 }')
    done

    # Wait for loop to disappear from list before continuing
    WaitLoops=0
    while [ -n "$(sudo losetup --list | grep ${1})" ]; do
        WaitLoops=$((WaitLoops + 1))
        if ((WaitLoops > 100)); then
            # Remove all mappings
            echo "Stuck -- can use sudo dmsetup remove_all to remove all mappings"
            #sudo dmsetup remove_all
        elif ((WaitLoops > 50)); then
            echo "Exceeded maximum wait time -- trying to force close"
            sudo kpartx -dvs "/dev/${MOUNT_IMG}"
            sudo losetup -D
        fi
        sync
        sync
        sleep "${SLEEP_SHORT}"
    done

    sudo chown -R "$LOGNAME" .

    export MOUNT_IMG=""
}

function CompactIMG() {
    echo "Compacting IMG file ${1}"
    sudo rm -rf "${1}.2"
    sudo virt-sparsify "${1}" "${1}.2"
    sync
    sync
    sleep "${SLEEP_SHORT}"

    sudo rm -rf "${1}"
    mv "${1}.2" "${1}"
    sync
    sync
    sleep "${SLEEP_SHORT}"
}

function CleanIMG() {
    echo "Cleaning IMG file (after)"

    # Clear apt cache
    sudo rm -rf /mnt/var/lib/apt/lists/ports* /mnt/var/lib/apt/lists/*InRelease /mnt/var/lib/apt/lists/*-en /mnt/var/lib/apt/lists/*Packages

    # Clear Python cache
    sudo find /mnt -regex '^.*\(__pycache__\|\.py[co]\)$' -delete

    # Remove any crash files generated
    sudo rm -rf /mnt/var/crash/*
    sudo rm -rf /mnt/root/*

    # Remove machine ID so all clones don't have the same one
    sudo rm -rf /mnt/etc/machine-id
    sudo touch /mnt/etc/machine-id

    # Trim
    sudo fstrim -v /mnt
    sudo fstrim -v /mnt/boot

    sync
    sync
    sleep "${SLEEP_LONG}"
}

function ShrinkIMG() {
    MountIMG "$1"

    tune2fs_output=$(sudo tune2fs -l "/dev/mapper/${MOUNT_IMG}p2")
    currentsize=$(echo "$tune2fs_output" | grep '^Block count:' | tr -d ' ' | cut -d ':' -f 2)
    blocksize=$(echo "$tune2fs_output" | grep '^Block size:' | tr -d ' ' | cut -d ':' -f 2)
    minsize=$(sudo resize2fs -P "/dev/mapper/${MOUNT_IMG}p2" | tr -d ' ' | cut -d ':' -f 2)
    extra_space=$(($currentsize - $minsize))

    beforesize=$(ls -lh "$1" | cut -d ' ' -f 5)
    echo "Before: $beforesize, Extra_Space: $extra_space, Blocksize: $blocksize"
    parted_output=$(sudo parted -ms "$1" unit B print | tail -n 1)
    partnum=$(echo "$parted_output" | cut -d ':' -f 1)
    partstart=$(echo "$parted_output" | cut -d ':' -f 2 | tr -d 'B')
    # Add 10000 blocks of free space
    minsize=$(($minsize + 10000))
    echo "parted_output: $parted_output, partnum: $partnum, partstart: $partstart, minsize: $minsize"
    sudo resize2fs -fp "/dev/mapper/${MOUNT_IMG}p2" $minsize

    UnmountIMG "$1"

    # Set new partition size
    partnewsize=$(($minsize * $blocksize))
    newpartend=$(($partstart + $partnewsize))
    echo "partnewsize: $partnewsize, newpartend: $newpartend"
    if ! sudo parted -s -a minimal "$1" rm "$partnum"; then
        rc=$?
        echo "parted failed: $rc"
        return
    fi

    if ! sudo parted -s "$1" unit B mkpart primary "$partstart" "$newpartend"; then
        rc=$?
        echo "parted failed: $rc"
        return
    fi

    # Truncate the file
    if ! endresult=$(sudo parted -ms "$1" unit B print free); then
        rc=$?
        echo "parted failed: $rc"
        return
    fi

    endresult=$(tail -1 <<<"$endresult" | cut -d ':' -f 2 | tr -d 'B')
    if ! sudo truncate -s "$endresult" "$1"; then
        rc=$?
        echo "truncate failed: $rc"
        return
    fi

    MountIMG "$1"

    # Run e2fsck
    echo "Running fsck"
    sudo fsck.ext4 -yfv "/dev/mapper/${MOUNT_IMG}p2"
    sync
    sync
    sleep "${SLEEP_SHORT}"
    #UnmountIMG "$1"
    #MountIMG "$1"

    # Run resize2fs
    echo "Running resize2fs"
    sudo resize2fs -p "/dev/mapper/${MOUNT_IMG}p2"
    sync
    sync
    sleep "${SLEEP_SHORT}"
    UnmountIMG "$1"

    CompactIMG "$1"
}

function CreateUpdatedIMG() {
    if [ ! -f "${UPDATED_IMG}" ]; then
        echo "Creating updated image ..."
        # Get ODROID M1 Ubuntu source image
        if [ ! -f "$SOURCE_IMGXZ" ]; then
            echo "Retrieving Ubuntu $SOURCE_RELEASE source image ..."
            wget "https://dn.odroid.com/RK3568/ODROID-M1/Ubuntu/${SOURCE_IMGXZ}"
        fi

        # Extract and compact our source image from the xz if the source image isn't present
        if [ ! -f "${SOURCE_IMG}" ]; then
            echo "Extracting Ubuntu $SOURCE_RELEASE source image ..."
            xzcat --threads=0 "$SOURCE_IMGXZ" >"${SOURCE_IMG}"
        fi

        cp -vf "${SOURCE_IMG}" "${UPDATED_IMG}"

        # Expands the target image to help us not run out of space and encounter errors
        echo "Expanding target image free space ..."
        truncate -s +1209715200 "${UPDATED_IMG}"
        sync
        sync

        # Mount image
        MountIMG "${UPDATED_IMG}"

        # Run fdisk
        # Get the starting offset of the root partition
        PART_START=$(sudo parted "/dev/${MOUNT_IMG}" -ms unit s p | grep ":ext4" | cut -f 2 -d: | sed 's/[^0-9]//g')
        # Perform fdisk to correct the partition table
        sudo fdisk "/dev/${MOUNT_IMG}" <<EOF
p
d
2
n
p
2
$PART_START

p
w
EOF

        UnmountIMG "${UPDATED_IMG}"
        MountIMG "${UPDATED_IMG}"

        # Run e2fsck
        echo "Running e2fsck"
        sudo e2fsck -yfv "/dev/mapper/${MOUNT_IMG}p2"
        sync
        sync
        sleep "${SLEEP_SHORT}"
        UnmountIMG "${UPDATED_IMG}"
        MountIMG "${UPDATED_IMG}"

        # Run resize2fs
        echo "Running resize2fs"
        sudo resize2fs -p "/dev/mapper/${MOUNT_IMG}p2"
        sync
        sync
        sleep "${SLEEP_SHORT}"
        UnmountIMG "${UPDATED_IMG}"

        # Compact image after our file operations
        CompactIMG "${UPDATED_IMG}"
        MountIMG "${UPDATED_IMG}"
        MountIMGPartitions "${MOUNT_IMG}"

        sync
        sync
        sleep "${SLEEP_SHORT}"

        # Prepare chroot
        sudo cp -f /usr/bin/qemu-aarch64-static /mnt/usr/bin

        # Copy resolv.conf from local host so we have networking in our chroot
        echo "Copying resolv.conf"
        sudo mkdir -p /mnt/run/systemd/resolve
        sudo touch /mnt/run/systemd/resolve/stub-resolv.conf
        sudo cat /run/systemd/resolve/stub-resolv.conf | sudo tee /mnt/run/systemd/resolve/stub-resolv.conf >/dev/null

        # Update apt sources for Jammy
        echo "Updating apt sources"
        sed -i 's/focal/jammy/g' /mnt/etc/apt/sources.list
        sed -i 's/focal/jammy/g' /mnt/etc/apt/sources.list.d/ppa-linuxfactory-or-kr.list

        # Remove flash-kernel hooks
        echo "Removing flash-kernel hooks"
        sudo mv /mnt/etc/kernel/postinst.d/zz-flash-kernel /mnt/etc/zz-flash-kernel-postinst
        sudo mv /mnt/etc/kernel/postrm.d/zz-flash-kernel /mnt/etc/zz-flash-kernel
        sudo mv /mnt/etc/initramfs/post-update.d//flash-kernel /mnt/flash-kernel

        sudo chroot /mnt /bin/bash <<EOF
# Update and install packages
DEBIAN_FRONTEND=noninteractive apt update && DEBIAN_FRONTEND=noninteractive apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" full-upgrade -y && DEBIAN_FRONTEND=noninteractive apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install linux-image-5.19.0-odroid-arm64 ifupdown nano libubootenv-tool git bc curl unzip -y
EOF

        sudo chroot /mnt /bin/bash <<EOF
# Purge old 4.x kernels
DEBIAN_FRONTEND=noninteractive apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" purge linux-image-4.* -y
EOF

        sudo chroot /mnt /bin/bash <<EOF
# Clean up after ourselves and clean out package cache to keep the image small
DEBIAN_FRONTEND=noninteractive apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" autoremove -y
EOF

        # Restore flash-kernel hooks
        echo "Restoring flash-kernel hooks"
        sudo mv /mnt/etc/zz-flash-kernel-postinst /mnt/etc/kernel/postrm.d/zz-flash-kernel
        sudo mv /mnt/etc/zz-flash-kernel /mnt/etc/kernel/postinst.d/zz-flash-kernel
        sudo mv /mnt/flash-kernel /mnt/etc/initramfs/post-update.d//flash-kernel

        # Run the after clean function
        CleanIMG

        # Run fsck on image then unmount and remount
        UnmountIMGPartitions
        sudo fsck.ext4 -yfv "/dev/mapper/${MOUNT_IMG}p2"
        sudo fsck.ext2 -yfv "/dev/mapper/${MOUNT_IMG}p1"
        UnmountIMG "${UPDATED_IMG}"
        CompactIMG "${UPDATED_IMG}"

        echo "Update image completed"
    fi
}

function ModifyFilesystem() {

    # Enable NPU overlay helper script
    #sudo cp enable-npu.sh /mnt/home/odroid/enable-npu.sh
    #sudo chmod +x /mnt/home/odroid/enable-npu.sh
    #sudo cp disable-npu.sh /mnt/home/odroid/disable-npu.sh
    #sudo chmod +x /mnt/home/odroid/disable-npu.sh

    # Resize rootfs helper script
    sudo cp -f resize_rootfs.sh /mnt/usr/sbin/
    sudo chmod +x /mnt/usr/sbin/resize_rootfs.sh
    cat >"/mnt/lib/systemd/system/resize-rootfs.service" <<EOF
[Unit]
Description=Resize root filesystem to fit available disk space
After=systemd-remount-fs.service

[Service]
Type=oneshot
ExecStart=-/usr/sbin/resize_rootfs.sh
ExecStartPost=/bin/systemctl disable resize-rootfs.service

[Install]
WantedBy=basic.target
EOF

    # Remove flash-kernel hooks
    echo "Removing flash-kernel hooks"
    sudo mv /mnt/etc/kernel/postinst.d/zz-flash-kernel /mnt/etc/zz-flash-kernel-postinst
    sudo mv /mnt/etc/kernel/postrm.d/zz-flash-kernel /mnt/etc/zz-flash-kernel
    sudo mv /mnt/etc/initramfs/post-update.d//flash-kernel /mnt/flash-kernel

    # Copy new boot.scr
    sudo cp boot.scr /mnt/boot/boot.scr

    # Prepare chroot
    sudo cp -f /usr/bin/qemu-aarch64-static /mnt/usr/bin

    # Fix dtbs and image path
    initrdpath=$(ls /mnt/boot | grep -m 1 'initrd.img-5.19')
    vmlinuzpath=$(ls /mnt/boot | grep -m 1 'vmlinuz-5.19')
    olddir=$(pwd)
    kvers=$(ls /mnt/boot | grep -m 1 'initrd.img-5.19' | cut -d- -f2-)
    mkdir -p "/mnt/boot/dtbs/$kvers/rockchip/overlays/odroidm1"
    cp -rfv /mnt/usr/lib/linux-image-$kvers/* "/mnt/boot/dtbs/$kvers"
    cd /mnt/boot
    ln -sfv "$initrdpath" initrd.img
    ln -sfv "$vmlinuzpath" vmlinuz
    ln -sfv "dtbs/$kvers/rockchip/rk3568-odroid-m1.dtb" dtb
    ln -sfv "dtbs/$kvers/rockchip/rk3568-odroid-m1.dtb" "dtb-$kvers"
    cd "dtbs/$kvers"
    ln -sfv rockchip/rk3568-odroid-m1.dtb rk3568-odroid-m1.dtb
    cd "$olddir"

    # Enter Ubuntu image chroot
    echo "Entering chroot of IMG file"
    sudo chroot /mnt /bin/bash <<EOF
# Enable SSH
systemctl enable ssh

# Enable resize_rootfs oneshot service
systemctl enable resize-rootfs.service

# Change machine name from "server"
echo "odroidm1" > /etc/hostname
sed -i 's/server/odroidm1/g' /etc/hosts

# Fix permissions
chown -R odroid /home/odroid
EOF
    echo "The chroot container has exited"

    # Restore flash-kernel hooks
    echo "Restoring flash-kernel hooks"
    sudo mv /mnt/etc/zz-flash-kernel-postinst /mnt/etc/kernel/postrm.d/zz-flash-kernel
    sudo mv /mnt/etc/zz-flash-kernel /mnt/etc/kernel/postinst.d/zz-flash-kernel
    sudo mv /mnt/flash-kernel /mnt/etc/initramfs/post-update.d//flash-kernel
}

function ModifyDesktopFilesystem() {
    # First startup helper script
    sudo cp -f first_startup.sh /mnt/usr/sbin/
    sudo chmod +x /mnt/usr/sbin/first_startup.sh
    cat >"/mnt/lib/systemd/system/first_startup.service" <<EOF
[Unit]
Description=First startup service to configure ODROID image
After=networking.service

[Service]
Type=oneshot
ExecStart=-/usr/sbin/first_startup.sh
ExecStartPost=/bin/systemctl disable first_startup.service

[Install]
WantedBy=multi-user.target
EOF

    sudo chroot /mnt /bin/bash <<EOF
systemctl enable first_startup.service
EOF
}

function CreateServerIMG() {
    # Create target image from Ubuntu source image
    echo "Creating target image ..."
    if [ -f "${TARGET_IMG}" ]; then
        sudo rm -rf "${TARGET_IMG}"
    fi
    cp -vf "${UPDATED_IMG}" "${TARGET_IMG}"
    MountIMG "${TARGET_IMG}"
    MountIMGPartitions "${MOUNT_IMG}"

    # Modify filesystem
    ModifyFilesystem

    # Run the after clean function
    CleanIMG

    # Run fsck on image then unmount and remount
    UnmountIMGPartitions
    sudo fsck.ext4 -yfv "/dev/mapper/${MOUNT_IMG}p2"
    sudo fsck.ext2 -yfv "/dev/mapper/${MOUNT_IMG}p1"
    UnmountIMG "${TARGET_IMG}"
    CompactIMG "${TARGET_IMG}"
}

function CreateUpdatedMateIMG() {
    # Build mate-desktop image

    if [ ! -f "${UPDATED_MATE_IMG}" ]; then
        echo "Creating updated mate-desktop image ..."
        cp -vf "${UPDATED_IMG}" "${UPDATED_MATE_IMG}"

        # Expands the target image by approximately 2GB to help us not run out of space and encounter errors
        echo "Expanding desktop image free space ..."
        truncate -s +6009715200 "${UPDATED_MATE_IMG}"
        sync
        sync

        MountIMG "${UPDATED_MATE_IMG}"

        # Run fdisk
        # Get the starting offset of the root partition
        PART_START=$(sudo parted "/dev/${MOUNT_IMG}" -ms unit s p | grep ":ext4" | cut -f 2 -d: | sed 's/[^0-9]//g')
        # Perform fdisk to correct the partition table
        sudo fdisk "/dev/${MOUNT_IMG}" <<EOF
p
d
2
n
p
2
$PART_START

p
w
EOF

        UnmountIMG "${UPDATED_MATE_IMG}"
        MountIMG "${UPDATED_MATE_IMG}"

        # Run e2fsck
        echo "Running e2fsck"
        sudo e2fsck -yfv "/dev/mapper/${MOUNT_IMG}p2"
        sync
        sync
        sleep "${SLEEP_SHORT}"
        UnmountIMG "${UPDATED_MATE_IMG}"
        MountIMG "${UPDATED_MATE_IMG}"

        # Run resize2fs
        echo "Running resize2fs"
        sudo resize2fs -p "/dev/mapper/${MOUNT_IMG}p2"
        sync
        sync
        sleep "${SLEEP_SHORT}"
        UnmountIMG "${UPDATED_MATE_IMG}"

        # Compact image after our file operations
        CompactIMG "${UPDATED_MATE_IMG}"
        MountIMG "${UPDATED_MATE_IMG}"
        MountIMGPartitions "${MOUNT_IMG}"

        # Remove flash-kernel hooks
        echo "Removing flash-kernel hooks"
        sudo mv /mnt/etc/kernel/postinst.d/zz-flash-kernel /mnt/etc/zz-flash-kernel-postinst
        sudo mv /mnt/etc/kernel/postrm.d/zz-flash-kernel /mnt/etc/zz-flash-kernel
        sudo mv /mnt/etc/initramfs/post-update.d//flash-kernel /mnt/flash-kernel

        sudo chroot /mnt /bin/bash <<EOF
DEBIAN_FRONTEND=noninteractive apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" update && DEBIAN_FRONTEND=noninteractive apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install ubuntu-mate-desktop -y
EOF

        sudo chroot /mnt /bin/bash <<EOF
DEBIAN_FRONTEND=noninteractive apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" full-upgrade -y
EOF

        # Restore flash-kernel hooks
        echo "Restoring flash-kernel hooks"
        sudo mv /mnt/etc/zz-flash-kernel-postinst /mnt/etc/kernel/postrm.d/zz-flash-kernel
        sudo mv /mnt/etc/zz-flash-kernel /mnt/etc/kernel/postinst.d/zz-flash-kernel
        sudo mv /mnt/flash-kernel /mnt/etc/initramfs/post-update.d//flash-kernel

        # Run the after clean function
        CleanIMG

        # Run fsck on image then unmount and remount
        UnmountIMGPartitions
        sudo fsck.ext4 -yfv "/dev/mapper/${MOUNT_IMG}p2"
        sudo fsck.ext2 -yfv "/dev/mapper/${MOUNT_IMG}p1"
        UnmountIMG "${UPDATED_MATE_IMG}"
        CompactIMG "${UPDATED_MATE_IMG}"
    fi
}

function CreateMateIMG() {
    # Build mate-desktop image
    echo "Creating mate-desktop image ..."
    if [ -f "${MATE_DESKTOP_IMG}" ]; then
        sudo rm -rf "${MATE_DESKTOP_IMG}"
    fi
    cp -vf "${UPDATED_MATE_IMG}" "${MATE_DESKTOP_IMG}"

    # Mount image
    MountIMG "${MATE_DESKTOP_IMG}"
    MountIMGPartitions "${MOUNT_IMG}"

    # Modify filesystem
    ModifyFilesystem

    # Modify desktop filesystem
    ModifyDesktopFilesystem

    # Run the after clean function
    CleanIMG

    # Run fsck on image then unmount and remount
    UnmountIMGPartitions
    sudo fsck.ext4 -yfv "/dev/mapper/${MOUNT_IMG}p2"
    sudo fsck.ext2 -yfv "/dev/mapper/${MOUNT_IMG}p1"
    UnmountIMG "${MATE_DESKTOP_IMG}"
    CompactIMG "${MATE_DESKTOP_IMG}"
}

function CreateUpdatedDesktopIMG() {
    # Build ubuntu-desktop image

    if [ ! -f "${UPDATED_DESKTOP_IMG}" ]; then
        echo "Creating ubuntu-desktop image ..."
        cp -vf "${UPDATED_IMG}" "${UPDATED_DESKTOP_IMG}"

        # Expands the target image by approximately 2GB to help us not run out of space and encounter errors
        echo "Expanding desktop image free space ..."
        truncate -s +6009715200 "${UPDATED_DESKTOP_IMG}"
        sync
        sync

        MountIMG "${UPDATED_DESKTOP_IMG}"

        # Run fdisk
        # Get the starting offset of the root partition
        PART_START=$(sudo parted "/dev/${MOUNT_IMG}" -ms unit s p | grep ":ext4" | cut -f 2 -d: | sed 's/[^0-9]//g')
        # Perform fdisk to correct the partition table
        sudo fdisk "/dev/${MOUNT_IMG}" <<EOF
p
d
2
n
p
2
$PART_START

p
w
EOF

        UnmountIMG "${UPDATED_DESKTOP_IMG}"
        MountIMG "${UPDATED_DESKTOP_IMG}"

        # Run e2fsck
        echo "Running e2fsck"
        sudo e2fsck -yfv "/dev/mapper/${MOUNT_IMG}p2"
        sync
        sync
        sleep "${SLEEP_SHORT}"
        UnmountIMG "${UPDATED_DESKTOP_IMG}"
        MountIMG "${UPDATED_DESKTOP_IMG}"

        # Run resize2fs
        echo "Running resize2fs"
        sudo resize2fs -p "/dev/mapper/${MOUNT_IMG}p2"
        sync
        sync
        sleep "${SLEEP_SHORT}"
        UnmountIMG "${UPDATED_DESKTOP_IMG}"

        # Compact image after our file operations
        CompactIMG "${UPDATED_DESKTOP_IMG}"
        MountIMG "${UPDATED_DESKTOP_IMG}"
        MountIMGPartitions "${MOUNT_IMG}"

        # Remove flash-kernel hooks
        echo "Removing flash-kernel hooks"
        sudo mv /mnt/etc/kernel/postinst.d/zz-flash-kernel /mnt/etc/zz-flash-kernel-postinst
        sudo mv /mnt/etc/kernel/postrm.d/zz-flash-kernel /mnt/etc/zz-flash-kernel
        sudo mv /mnt/etc/initramfs/post-update.d//flash-kernel /mnt/flash-kernel

        sudo chroot /mnt /bin/bash <<EOF
DEBIAN_FRONTEND=noninteractive apt update && DEBIAN_FRONTEND=noninteractive apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install ubuntu-desktop -y
EOF

        sudo chroot /mnt /bin/bash <<EOF
DEBIAN_FRONTEND=noninteractive apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" autoremove -y
EOF

        sudo chroot /mnt /bin/bash <<EOF
DEBIAN_FRONTEND=noninteractive apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" full-upgrade -y
EOF

        # Restore flash-kernel hooks
        echo "Restoring flash-kernel hooks"
        sudo mv /mnt/etc/zz-flash-kernel-postinst /mnt/etc/kernel/postrm.d/zz-flash-kernel
        sudo mv /mnt/etc/zz-flash-kernel /mnt/etc/kernel/postinst.d/zz-flash-kernel
        sudo mv /mnt/flash-kernel /mnt/etc/initramfs/post-update.d//flash-kernel

        # Run the after clean function
        CleanIMG

        # Run fsck on image then unmount and remount
        UnmountIMGPartitions
        sudo fsck.ext4 -yfv "/dev/mapper/${MOUNT_IMG}p2"
        sudo fsck.ext2 -yfv "/dev/mapper/${MOUNT_IMG}p1"
        UnmountIMG "${UPDATED_DESKTOP_IMG}"
        CompactIMG "${UPDATED_DESKTOP_IMG}"
    fi
}

function CreateDesktopIMG() {
    # Build ubuntu-desktop image
    echo "Creating ubuntu-desktop image ..."
    if [ -f "${DESKTOP_IMG}" ]; then
        sudo rm -rf "${DESKTOP_IMG}"
    fi
    cp -vf "${UPDATED_DESKTOP_IMG}" "${DESKTOP_IMG}"

    MountIMG "${DESKTOP_IMG}"
    MountIMGPartitions "${MOUNT_IMG}"

    # Modify filesystem
    ModifyFilesystem

    # Modify desktop filesystem
    ModifyDesktopFilesystem

    # Run the after clean function
    CleanIMG

    # Run fsck on image then unmount and remount
    UnmountIMGPartitions
    sudo fsck.ext4 -yfv "/dev/mapper/${MOUNT_IMG}p2"
    sudo fsck.ext2 -yfv "/dev/mapper/${MOUNT_IMG}p1"
    UnmountIMG "${DESKTOP_IMG}"
    CompactIMG "${DESKTOP_IMG}"
}

function CreateUpdatedXubuntuIMG() {
    # Build mate-desktop image

    if [ ! -f "${UPDATED_XUBUNTU_IMG}" ]; then
        echo "Creating updated xubuntu-desktop image ..."
        cp -vf "${UPDATED_IMG}" "${UPDATED_XUBUNTU_IMG}"

        # Expands the target image by approximately 2GB to help us not run out of space and encounter errors
        echo "Expanding desktop image free space ..."
        truncate -s +6009715200 "${UPDATED_XUBUNTU_IMG}"
        sync
        sync

        MountIMG "${UPDATED_XUBUNTU_IMG}"

        # Run fdisk
        # Get the starting offset of the root partition
        PART_START=$(sudo parted "/dev/${MOUNT_IMG}" -ms unit s p | grep ":ext4" | cut -f 2 -d: | sed 's/[^0-9]//g')
        # Perform fdisk to correct the partition table
        sudo fdisk "/dev/${MOUNT_IMG}" <<EOF
p
d
2
n
p
2
$PART_START

p
w
EOF

        UnmountIMG "${UPDATED_XUBUNTU_IMG}"
        MountIMG "${UPDATED_XUBUNTU_IMG}"

        # Run e2fsck
        echo "Running e2fsck"
        sudo e2fsck -yfv "/dev/mapper/${MOUNT_IMG}p2"
        sync
        sync
        sleep "${SLEEP_SHORT}"
        UnmountIMG "${UPDATED_XUBUNTU_IMG}"
        MountIMG "${UPDATED_XUBUNTU_IMG}"

        # Run resize2fs
        echo "Running resize2fs"
        sudo resize2fs -p "/dev/mapper/${MOUNT_IMG}p2"
        sync
        sync
        sleep "${SLEEP_SHORT}"
        UnmountIMG "${UPDATED_XUBUNTU_IMG}"

        # Compact image after our file operations
        CompactIMG "${UPDATED_XUBUNTU_IMG}"
        MountIMG "${UPDATED_XUBUNTU_IMG}"
        MountIMGPartitions "${MOUNT_IMG}"

        # Remove flash-kernel hooks
        echo "Removing flash-kernel hooks"
        sudo mv /mnt/etc/kernel/postinst.d/zz-flash-kernel /mnt/etc/zz-flash-kernel-postinst
        sudo mv /mnt/etc/kernel/postrm.d/zz-flash-kernel /mnt/etc/zz-flash-kernel
        sudo mv /mnt/etc/initramfs/post-update.d//flash-kernel /mnt/flash-kernel

        sudo chroot /mnt /bin/bash <<EOF
DEBIAN_FRONTEND=noninteractive apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" update && DEBIAN_FRONTEND=noninteractive apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install xubuntu-desktop -y
EOF

        sudo chroot /mnt /bin/bash <<EOF
DEBIAN_FRONTEND=noninteractive apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" full-upgrade -y
EOF

        # Restore flash-kernel hooks
        echo "Restoring flash-kernel hooks"
        sudo mv /mnt/etc/zz-flash-kernel-postinst /mnt/etc/kernel/postrm.d/zz-flash-kernel
        sudo mv /mnt/etc/zz-flash-kernel /mnt/etc/kernel/postinst.d/zz-flash-kernel
        sudo mv /mnt/flash-kernel /mnt/etc/initramfs/post-update.d//flash-kernel

        # Run the after clean function
        CleanIMG

        # Run fsck on image then unmount and remount
        UnmountIMGPartitions
        sudo fsck.ext4 -yfv "/dev/mapper/${MOUNT_IMG}p2"
        sudo fsck.ext2 -yfv "/dev/mapper/${MOUNT_IMG}p1"
        UnmountIMG "${UPDATED_XUBUNTU_IMG}"
        CompactIMG "${UPDATED_XUBUNTU_IMG}"
    fi
}

function CreateXubuntuIMG() {
    # Build mate-desktop image
    echo "Creating xubuntu-desktop image ..."
    if [ -f "${XUBUNTU_DESKTOP_IMG}" ]; then
        sudo rm -rf "${XUBUNTU_DESKTOP_IMG}"
    fi
    cp -vf "${UPDATED_XUBUNTU_IMG}" "${XUBUNTU_DESKTOP_IMG}"

    # Mount image
    MountIMG "${XUBUNTU_DESKTOP_IMG}"
    MountIMGPartitions "${MOUNT_IMG}"

    # Modify filesystem
    ModifyFilesystem

    # Modify desktop filesystem
    ModifyDesktopFilesystem

    # Run the after clean function
    CleanIMG

    # Run fsck on image then unmount and remount
    UnmountIMGPartitions
    sudo fsck.ext4 -yfv "/dev/mapper/${MOUNT_IMG}p2"
    sudo fsck.ext2 -yfv "/dev/mapper/${MOUNT_IMG}p1"
    UnmountIMG "${XUBUNTU_DESKTOP_IMG}"
    CompactIMG "${XUBUNTU_DESKTOP_IMG}"
}

function CreateUpdatedKubuntuIMG() {
    # Build mate-desktop image

    if [ ! -f "${UPDATED_KUBUNTU_IMG}" ]; then
        echo "Creating updated kubuntu-desktop image ..."
        cp -vf "${UPDATED_IMG}" "${UPDATED_KUBUNTU_IMG}"

        # Expands the target image by approximately 2GB to help us not run out of space and encounter errors
        echo "Expanding desktop image free space ..."
        truncate -s +6009715200 "${UPDATED_KUBUNTU_IMG}"
        sync
        sync

        MountIMG "${UPDATED_KUBUNTU_IMG}"

        # Run fdisk
        # Get the starting offset of the root partition
        PART_START=$(sudo parted "/dev/${MOUNT_IMG}" -ms unit s p | grep ":ext4" | cut -f 2 -d: | sed 's/[^0-9]//g')
        # Perform fdisk to correct the partition table
        sudo fdisk "/dev/${MOUNT_IMG}" <<EOF
p
d
2
n
p
2
$PART_START

p
w
EOF

        UnmountIMG "${UPDATED_KUBUNTU_IMG}"
        MountIMG "${UPDATED_KUBUNTU_IMG}"

        # Run e2fsck
        echo "Running e2fsck"
        sudo e2fsck -yfv "/dev/mapper/${MOUNT_IMG}p2"
        sync
        sync
        sleep "${SLEEP_SHORT}"
        UnmountIMG "${UPDATED_KUBUNTU_IMG}"
        MountIMG "${UPDATED_KUBUNTU_IMG}"

        # Run resize2fs
        echo "Running resize2fs"
        sudo resize2fs -p "/dev/mapper/${MOUNT_IMG}p2"
        sync
        sync
        sleep "${SLEEP_SHORT}"
        UnmountIMG "${UPDATED_KUBUNTU_IMG}"

        # Compact image after our file operations
        CompactIMG "${UPDATED_KUBUNTU_IMG}"
        MountIMG "${UPDATED_KUBUNTU_IMG}"
        MountIMGPartitions "${MOUNT_IMG}"

        # Remove flash-kernel hooks
        echo "Removing flash-kernel hooks"
        sudo mv /mnt/etc/kernel/postinst.d/zz-flash-kernel /mnt/etc/zz-flash-kernel-postinst
        sudo mv /mnt/etc/kernel/postrm.d/zz-flash-kernel /mnt/etc/zz-flash-kernel
        sudo mv /mnt/etc/initramfs/post-update.d//flash-kernel /mnt/flash-kernel

        sudo chroot /mnt /bin/bash <<EOF
DEBIAN_FRONTEND=noninteractive apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" update && DEBIAN_FRONTEND=noninteractive apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install kubuntu-desktop -y
EOF

        sudo chroot /mnt /bin/bash <<EOF
DEBIAN_FRONTEND=noninteractive apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" full-upgrade -y
EOF

        # Restore flash-kernel hooks
        echo "Restoring flash-kernel hooks"
        sudo mv /mnt/etc/zz-flash-kernel-postinst /mnt/etc/kernel/postrm.d/zz-flash-kernel
        sudo mv /mnt/etc/zz-flash-kernel /mnt/etc/kernel/postinst.d/zz-flash-kernel
        sudo mv /mnt/flash-kernel /mnt/etc/initramfs/post-update.d//flash-kernel

        # Run the after clean function
        CleanIMG

        # Run fsck on image then unmount and remount
        UnmountIMGPartitions
        sudo fsck.ext4 -yfv "/dev/mapper/${MOUNT_IMG}p2"
        sudo fsck.ext2 -yfv "/dev/mapper/${MOUNT_IMG}p1"
        UnmountIMG "${UPDATED_KUBUNTU_IMG}"
        CompactIMG "${UPDATED_KUBUNTU_IMG}"
    fi
}

function CreateKubuntuIMG() {
    # Build kubuntu-desktop image
    echo "Creating kubuntu-desktop image ..."
    if [ -f "${KUBUNTU_DESKTOP_IMG}" ]; then
        sudo rm -rf "${KUBUNTU_DESKTOP_IMG}"
    fi
    cp -vf "${UPDATED_KUBUNTU_IMG}" "${KUBUNTU_DESKTOP_IMG}"

    # Mount image
    MountIMG "${KUBUNTU_DESKTOP_IMG}"
    MountIMGPartitions "${MOUNT_IMG}"

    # Modify filesystem
    ModifyFilesystem

    # Modify desktop filesystem
    ModifyDesktopFilesystem

    # Run the after clean function
    CleanIMG

    # Run fsck on image then unmount and remount
    UnmountIMGPartitions
    sudo fsck.ext4 -yfv "/dev/mapper/${MOUNT_IMG}p2"
    sudo fsck.ext2 -yfv "/dev/mapper/${MOUNT_IMG}p1"
    UnmountIMG "${KUBUNTU_DESKTOP_IMG}"
    CompactIMG "${KUBUNTU_DESKTOP_IMG}"
}

function CreateUpdatedLubuntuIMG() {
    # Build lubuntu-desktop image
    if [ ! -f "${UPDATED_LUBUNTU_IMG}" ]; then
        echo "Creating updated lubuntu-desktop image ..."
        cp -vf "${UPDATED_IMG}" "${UPDATED_LUBUNTU_IMG}"

        # Expands the target image by approximately 2GB to help us not run out of space and encounter errors
        echo "Expanding desktop image free space ..."
        truncate -s +6009715200 "${UPDATED_LUBUNTU_IMG}"
        sync
        sync

        MountIMG "${UPDATED_LUBUNTU_IMG}"

        # Run fdisk
        # Get the starting offset of the root partition
        PART_START=$(sudo parted "/dev/${MOUNT_IMG}" -ms unit s p | grep ":ext4" | cut -f 2 -d: | sed 's/[^0-9]//g')
        # Perform fdisk to correct the partition table
        sudo fdisk "/dev/${MOUNT_IMG}" <<EOF
p
d
2
n
p
2
$PART_START

p
w
EOF

        UnmountIMG "${UPDATED_LUBUNTU_IMG}"
        MountIMG "${UPDATED_LUBUNTU_IMG}"

        # Run e2fsck
        echo "Running e2fsck"
        sudo e2fsck -yfv "/dev/mapper/${MOUNT_IMG}p2"
        sync
        sync
        sleep "${SLEEP_SHORT}"
        UnmountIMG "${UPDATED_LUBUNTU_IMG}"
        MountIMG "${UPDATED_LUBUNTU_IMG}"

        # Run resize2fs
        echo "Running resize2fs"
        sudo resize2fs -p "/dev/mapper/${MOUNT_IMG}p2"
        sync
        sync
        sleep "${SLEEP_SHORT}"
        UnmountIMG "${UPDATED_LUBUNTU_IMG}"

        # Compact image after our file operations
        CompactIMG "${UPDATED_LUBUNTU_IMG}"
        MountIMG "${UPDATED_LUBUNTU_IMG}"
        MountIMGPartitions "${MOUNT_IMG}"

        # Remove flash-kernel hooks
        echo "Removing flash-kernel hooks"
        sudo mv /mnt/etc/kernel/postinst.d/zz-flash-kernel /mnt/etc/zz-flash-kernel-postinst
        sudo mv /mnt/etc/kernel/postrm.d/zz-flash-kernel /mnt/etc/zz-flash-kernel
        sudo mv /mnt/etc/initramfs/post-update.d//flash-kernel /mnt/flash-kernel

        sudo chroot /mnt /bin/bash <<EOF
DEBIAN_FRONTEND=noninteractive apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" update && DEBIAN_FRONTEND=noninteractive apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install lubuntu-desktop -y
EOF

        sudo chroot /mnt /bin/bash <<EOF
DEBIAN_FRONTEND=noninteractive apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" full-upgrade -y
EOF

        # Restore flash-kernel hooks
        echo "Restoring flash-kernel hooks"
        sudo mv /mnt/etc/zz-flash-kernel-postinst /mnt/etc/kernel/postrm.d/zz-flash-kernel
        sudo mv /mnt/etc/zz-flash-kernel /mnt/etc/kernel/postinst.d/zz-flash-kernel
        sudo mv /mnt/flash-kernel /mnt/etc/initramfs/post-update.d//flash-kernel

        # Run the after clean function
        CleanIMG

        # Run fsck on image then unmount and remount
        UnmountIMGPartitions
        sudo fsck.ext4 -yfv "/dev/mapper/${MOUNT_IMG}p2"
        sudo fsck.ext2 -yfv "/dev/mapper/${MOUNT_IMG}p1"
        UnmountIMG "${UPDATED_LUBUNTU_IMG}"
        CompactIMG "${UPDATED_LUBUNTU_IMG}"
    fi
}

function CreateLubuntuIMG() {
    # Build lubuntu-desktop image
    echo "Creating lubuntu-desktop image ..."
    if [ -f "${LUBUNTU_DESKTOP_IMG}" ]; then
        sudo rm -rf "${LUBUNTU_DESKTOP_IMG}"
    fi
    cp -vf "${UPDATED_LUBUNTU_IMG}" "${LUBUNTU_DESKTOP_IMG}"

    # Mount image
    MountIMG "${LUBUNTU_DESKTOP_IMG}"
    MountIMGPartitions "${MOUNT_IMG}"

    # Modify filesystem
    ModifyFilesystem

    # Modify desktop filesystem
    ModifyDesktopFilesystem

    # Run the after clean function
    CleanIMG

    # Run fsck on image then unmount and remount
    UnmountIMGPartitions
    sudo fsck.ext4 -yfv "/dev/mapper/${MOUNT_IMG}p2"
    sudo fsck.ext2 -yfv "/dev/mapper/${MOUNT_IMG}p1"
    UnmountIMG "${LUBUNTU_DESKTOP_IMG}"
    CompactIMG "${LUBUNTU_DESKTOP_IMG}"
}

##################################################################################################################

# Prepare for imaging
PrepareIMG

CreateUpdatedIMG
CreateServerIMG
ShrinkIMG "${TARGET_IMG}"

CreateUpdatedMateIMG
CreateMateIMG
ShrinkIMG "${MATE_DESKTOP_IMG}"

CreateUpdatedDesktopIMG
CreateDesktopIMG
ShrinkIMG "${DESKTOP_IMG}"

CreateUpdatedXubuntuIMG
CreateXubuntuIMG
ShrinkIMG "${XUBUNTU_DESKTOP_IMG}"

CreateUpdatedKubuntuIMG
CreateKubuntuIMG
ShrinkIMG "${KUBUNTU_DESKTOP_IMG}"

CreateUpdatedLubuntuIMG
CreateLubuntuIMG
ShrinkIMG "${LUBUNTU_DESKTOP_IMG}"

# Compress img into xz file
echo "Compressing final ubuntu-server img.xz file ..."
sudo rm -rf "$TARGET_IMGXZ"
sleep "${SLEEP_SHORT}"
tar cf "${TARGET_IMGXZ}" --use-compress-program='xz -T8 -v -9' "${TARGET_IMG}"

echo "Compressing final ubuntu-desktop img.xz file ..."
sudo rm -rf "${DESKTOP_IMGXZ}"
sleep "${SLEEP_SHORT}"
tar cf "${DESKTOP_IMGXZ}" --use-compress-program='xz -T8 -v -9' "${DESKTOP_IMG}"

echo "Compressing final mate-desktop img.xz file ..."
sudo rm -rf "${MATE_DESKTOP_IMGXZ}"
sleep "${SLEEP_SHORT}"
tar cf "${MATE_DESKTOP_IMGXZ}" --use-compress-program='xz -T8 -v -9' "${MATE_DESKTOP_IMG}"

echo "Compressing final xubuntu-desktop img.xz file ..."
sudo rm -rf "${XUBUNTU_DESKTOP_IMGXZ}"
sleep "${SLEEP_SHORT}"
tar cf "${XUBUNTU_DESKTOP_IMGXZ}" --use-compress-program='xz -T8 -v -9' "${XUBUNTU_DESKTOP_IMG}"

echo "Compressing final kubuntu-desktop img.xz file ..."
sudo rm -rf "${KUBUNTU_DESKTOP_IMGXZ}"
sleep "${SLEEP_SHORT}"
tar cf "${KUBUNTU_DESKTOP_IMGXZ}" --use-compress-program='xz -T8 -v -9' "${KUBUNTU_DESKTOP_IMG}"

echo "Compressing final lubuntu-desktop img.xz file ..."
sudo rm -rf "${LUBUNTU_DESKTOP_IMGXZ}"
sleep "${SLEEP_SHORT}"
tar cf "${LUBUNTU_DESKTOP_IMGXZ}" --use-compress-program='xz -T8 -v -9' "${LUBUNTU_DESKTOP_IMG}"

echo "Build completed"
