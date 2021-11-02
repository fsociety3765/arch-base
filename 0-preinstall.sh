#!/bin/bash

echo "-------------------------------------------------"
echo "Starting Pre-install                             "
echo "-------------------------------------------------"
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
iso=$(curl -4 ifconfig.co/country-iso)
timedatectl set-ntp true

echo -e "-----------------------------------------------"
echo -e "Setting up $iso mirrors for faster downloads   "
echo -e "-----------------------------------------------"
sed -i 's/^#Para/Para/' /etc/pacman.conf
mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
reflector -a 48 -c $iso -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist

echo "-------------------------------------------------"
echo "-------select your disk to format----------------"
echo "-------------------------------------------------"
lsblk
read -p "Please enter disk to work on: (example /dev/sda): " DISK
echo "THIS WILL FORMAT AND DELETE ALL DATA ON THE DISK"
read -p "Are you sure you want to continue (Y/N):" formatdisk
case $formatdisk in
	y|Y|yes|Yes|YES)
		echo "-------------------------------------------------"
		echo -e "\nFormatting disk...\n$HR"
		echo "-------------------------------------------------"
		sgdisk -Z ${DISK}
		sgdisk -a 2048 -o ${DISK}
		sgdisk -n 1::+260M --typecode=1:ef00 ${DISK}
		sgdisk -n 2::-0 --typecode=2:8300 ${DISK}

		if [[ ${DISK} =~ "nvme" ]]; then
		  EFI_PARTITION="${DISK}p1"
		  export ROOT_PARTITION="${DISK}p2"
		else
		  EFI_PARTITION="${DISK}1"
		  export ROOT_PARTITION="${DISK}2"
		fi

		echo "-------------------------------------------------"
		echo "Setting up LUKS encryption                       "
		echo "-------------------------------------------------"
		cryptsetup -y -v --type luks1 luksFormat ${ROOT_PARTITION}

		echo "-------------------------------------------------"
		echo "Opening LUKS volume                              "
		echo "-------------------------------------------------"
		export CRYPTROOT_NAME="cryptroot"
		export CRYPTROOT_PATH="/dev/mapper/${CRYPTROOT_NAME}"
		cryptsetup open ${ROOT_PARTITION} ${CRYPTROOT_NAME}

		echo "-------------------------------------------------"
		echo "Creating filesystem                              "
		echo "-------------------------------------------------"
		mkfs.fat -F32 ${EFI_PARTITION}
		mkfs.btrfs ${CRYPTROOT_PATH}
		mount ${CRYPTROOT_PATH} /mnt
		btrfs subvolume create /mnt/@
		btrfs subvolume create /mnt/@home
		btrfs subvolume create /mnt/@snapshots
		btrfs subvolume create /mnt/@log
		btrfs subvolume create /mnt/@cache
		umount /mnt
esac

echo "-------------------------------------------------"
echo "Setting up mount points                          "
echo "-------------------------------------------------"
mount -o noatime,compress=zstd,space_cache,discard=async,subvol=@ ${CRYPTROOT_PATH} /mnt
mkdir -p /mnt/boot/efi
mkdir -p /mnt/home
mkdir -p /mnt/var/log
mkdir -p /mnt/var/cache
mount -o noatime,compress=zstd,space_cache,discard=async,subvol=@home ${CRYPTROOT_PATH} /mnt/home
mount -o noatime,compress=zstd,space_cache,discard=async,subvol=@log ${CRYPTROOT_PATH} /mnt/var/log
mount -o noatime,compress=zstd,space_cache,discard=async,subvol=@cache ${CRYPTROOT_PATH} /mnt/var/cache
mount ${EFI_PARTITION} /mnt/boot/efi

if ! grep -qs '/mnt' /proc/mounts; then
    echo "-------------------------------------------------"
    echo "!!! ERROR setting up mount points !!!            "
    echo "!!! Cannot continue with installation !!!        "
    echo "-------------------------------------------------"
    echo "Rebooting in 3 Seconds ..." && sleep 1
    echo "Rebooting in 2 Seconds ..." && sleep 1
    echo "Rebooting in 1 Second ..." && sleep 1
    reboot now
fi

echo "-------------------------------------------------"
echo "Installing base packages                         "
echo "-------------------------------------------------"
pacstrap /mnt base linux linux-firmware btrfs-progs git vim --noconfirm --needed

echo "-------------------------------------------------"
echo "Generating fstab file                            "
echo "-------------------------------------------------"
genfstab -U /mnt >> /mnt/etc/fstab

echo "-------------------------------------------------"
echo "Setting up LUKS keyfile                          "
echo "-------------------------------------------------"
dd bs=512 count=4 if=/dev/random of=/mnt/crypto_keyfile.bin iflag=fullblock
chmod 600 /mnt/crypto_keyfile.bin
chmod 600 /mnt/boot/initramfs-linux*

echo "-------------------------------------------------"
echo "Adding the LUKS keyfile                          "
echo "Enter your disk encryption password when prompted"
echo "-------------------------------------------------"
cryptsetup luksAddKey ${ROOT_PARTITION} /mnt/crypto_keyfile.bin

echo "-------------------------------------------------"
echo "Copying Arch-Base scripts to installation        "
echo "-------------------------------------------------"
cp -R ${SCRIPT_DIR} /mnt/
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

echo "-------------------------------------------------"
echo "Pre-install Complete                             "
echo "-------------------------------------------------"
