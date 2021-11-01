#!/bin/bash

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
echo "-------------------------------------------------"
echo "Setting up mirrors for optimal download          "
echo "-------------------------------------------------"
iso=$(curl -4 ifconfig.co/country-iso)
timedatectl set-ntp true
sed -i 's/^#Para/Para/' /etc/pacman.conf
pacman -S --noconfirm reflector
mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak

echo -e "-----------------------------------------------"
echo -e "Setting up $iso mirrors for faster downloads   "
echo -e "-----------------------------------------------"
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
  ROOT_PARTITION="${DISK}p2"
else
  EFI_PARTITION="${DISK}1"
  ROOT_PARTITION="${DISK}2"
fi

echo "-------------------------------------------------"
echo "Setting up LUKS encryption                       "
echo "-------------------------------------------------"
cryptsetup -y -v --type luks1 luksFormat ${ROOT_PARTITION}

echo "-------------------------------------------------"
echo "Opening LUKS volume                              "
echo "-------------------------------------------------"
CRYPTROOT_NAME="cryptroot"
CRYPTROOT_PATH="/dev/mapper/${CRYPTROOT_NAME}"
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

echo "-------------------------------------------------"
echo "Installing base packages                         "
echo "-------------------------------------------------"
pacstrap /mnt base linux linux-firmware btrfs-progs git vim --noconfirm --needed

echo "-------------------------------------------------"
echo "Generating fstab file                            "
echo "-------------------------------------------------"
genfstab -U /mnt >> /mnt/etc/fstab

echo "-------------------------------------------------"
echo "Entering the installation                        "
echo "-------------------------------------------------"
arch-chroot /mnt

echo "-------------------------------------------------"
echo "Setting up LUKS keyfile                          "
echo "-------------------------------------------------"
dd bs=512 count=4 if=/dev/random of=/crypto_keyfile.bin iflag=fullblock
chmod 600 /crypto_keyfile.bin
chmod 600 /boot/initramfs-linux*

echo "-------------------------------------------------"
echo "Adding the LUKS keyfile                          "
echo "Enter your disk encryption password when prompted"
echo "-------------------------------------------------"
cryptsetup luksAddKey ${ROOT_PARTITION} /crypto_keyfile.bin

echo "-------------------------------------------------"
echo "Setting up locales                               "
echo "-------------------------------------------------"
ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
hwclock --systohc
sed -i '160s/.//' /etc/locale.gen
locale-gen
echo "LANG=en_GB.UTF-8" >> /etc/locale.conf
echo "KEYMAP=uk" >> /etc/vconsole.conf

echo "-------------------------------------------------"
echo "Configuring hostname and hosts file              "
echo "-------------------------------------------------"
echo "arch" >> /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 arch" >> /etc/hosts

echo "-------------------------------------------------"
echo "Set root password                                "
echo "-------------------------------------------------"
passwd root

# You can add xorg to the installation packages, I usually add it at the DE or WM install script
# You can remove the tlp package if you are installing on a desktop or vm
echo "-------------------------------------------------"
echo "Installing system packages                       "
echo "-------------------------------------------------"
PKGS=(
  'grub'
  'grub-btrfs'
  'efibootmgr' 
  'networkmanager' 
  'network-manager-applet' 
  'dialog' 
  'wpa_supplicant' 
  'mtools'
  'dosfstools'
  'base-devel'
  'linux-headers'
  'avahi'
  'xdg-user-dirs'
  'xdg-utils' 
  'gvfs'
  'gvfs-smb'
  'nfs-utils'
  'inetutils'
  'dnsutils'
  'bluez'
  'bluez-utils'
  'cups'
  'hplip'
  'alsa-utils'
  'pipewire'
  'pipewire-alsa'
  'pipewire-pulse'
  'pipewire-jack'
  'bash-completion'
  'openssh'
  'rsync'
  'reflector'
  'acpi'
  'acpi_call'
  'bridge-utils'
  'dnsmasq'
  'vde2'
  'openbsd-netcat'
  'iptables-nft'
  'ipset'
  'firewalld'
  'flatpak'
  'sof-firmware'
  'nss-mdns'
  'acpid'
  'os-prober'
  'ntfs-3g'
  'terminus-font'
)

for PKG in "${PKGS[@]}"; do
  echo "Installing: ${PKG}"
  pacman -S "$PKG" --noconfirm --needed
done

# pacman -S --noconfirm xf86-video-amdgpu
# pacman -S --noconfirm nvidia nvidia-utils nvidia-settings

#grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
#grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable cups.service
systemctl enable sshd
systemctl enable avahi-daemon
systemctl enable reflector.timer
systemctl enable fstrim.timer
systemctl enable firewalld
systemctl enable acpid

useradd -m fsociety3765
echo fsociety3765:password | chpasswd
usermod -aG wheel fsociety3765

echo "fsociety3765 ALL=(ALL) ALL" >> /etc/sudoers.d/fsociety3765

printf "\e[1;32mDone! Type exit, umount -a and reboot.\e[0m"
