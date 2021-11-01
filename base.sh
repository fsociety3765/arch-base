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
echo -e "-Setting up $iso mirrors for faster downloads"
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
sgdisk -n 1::+260M --typecode=1:ef00 --change-name=1:'EFI' ${DISK}
sgdisk -n 2::-0 --typecode=2:8300 --change-name=2:'ROOT' ${DISK}

echo -e "\nCreating Filesystems...\n$HR"
if [[ ${DISK} =~ "nvme" ]]; then
  mkfs.fat -F32 -n "EFI" "${DISK}p1"
  mkfs.btrfs -L "ROOT" "${DISK}p2" -f
  mount -t btrfs "${DISK}p2" /mnt
else
  mkfs.vfat -F32 -n "EFIBOOT" "${DISK}1"
  mkfs.btrfs -L "ROOT" "${DISK}2" -f
  mount -t btrfs "${DISK}2" /mnt
fi

# Setup LUKS key file
dd bs=512 count=4 if=/dev/random of=/crypto_keyfile.bin iflag=fullblock
chmod 600 /crypto_keyfile.bin
chmod 600 /boot/initramfs-linux*
cryptsetup luksAddKey /dev/sdX# /crypto_keyfile.bin

ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
hwclock --systohc
sed -i '160s/.//' /etc/locale.gen
locale-gen
echo "LANG=en_GB.UTF-8" >> /etc/locale.conf
echo "KEYMAP=uk" >> /etc/vconsole.conf
echo "arch" >> /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 arch" >> /etc/hosts
echo root:password | chpasswd

# You can add xorg to the installation packages, I usually add it at the DE or WM install script
# You can remove the tlp package if you are installing on a desktop or vm

pacman -S grub grub-btrfs efibootmgr networkmanager network-manager-applet dialog wpa_supplicant mtools dosfstools base-devel linux-headers avahi xdg-user-dirs xdg-utils gvfs gvfs-smb nfs-utils inetutils dnsutils bluez bluez-utils cups hplip alsa-utils pipewire pipewire-alsa pipewire-pulse pipewire-jack bash-completion openssh rsync reflector acpi acpi_call bridge-utils dnsmasq vde2 openbsd-netcat iptables-nft ipset firewalld flatpak sof-firmware nss-mdns acpid os-prober ntfs-3g terminus-font

# pacman -S --noconfirm xf86-video-amdgpu
# pacman -S --noconfirm nvidia nvidia-utils nvidia-settings

#grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
#grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable cups.service
systemctl enable sshd
systemctl enable avahi-daemon
#systemctl enable tlp # You can comment this command out if you didn't install tlp, see above
systemctl enable reflector.timer
systemctl enable fstrim.timer
#systemctl enable libvirtd
systemctl enable firewalld
systemctl enable acpid

useradd -m fsociety3765
echo fsociety3765:password | chpasswd
usermod -aG wheel fsociety3765

echo "fsociety3765 ALL=(ALL) ALL" >> /etc/sudoers.d/fsociety3765

printf "\e[1;32mDone! Type exit, umount -a and reboot.\e[0m"
