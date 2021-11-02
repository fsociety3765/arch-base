#!/bin/bash

echo "-------------------------------------------------"
echo "Starting setup                                   "
echo "-------------------------------------------------"

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

echo "-------------------------------------------------"
echo "Installing system packages                       "
echo "-------------------------------------------------"
sed -i 's/^#Para/Para/' /etc/pacman.conf
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
pacman -Sy --noconfirm
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

proc_type=$(lscpu | awk '/Vendor ID:/ {print $3}')
case "$proc_type" in
	GenuineIntel)
		print "Installing Intel microcode"
		pacman -S --noconfirm intel-ucode
		proc_ucode=intel-ucode.img
		;;
	AuthenticAMD)
		print "Installing AMD microcode"
		pacman -S --noconfirm amd-ucode
		proc_ucode=amd-ucode.img
		;;
esac	

echo "-------------------------------------------------"
echo "Enabling services to start at boot               "
echo "-------------------------------------------------"
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable cups.service
systemctl enable sshd
systemctl enable avahi-daemon
systemctl enable reflector.timer
systemctl enable fstrim.timer
systemctl enable firewalld
systemctl enable acpid

echo "-------------------------------------------------"
echo "Create non-root user                             "
echo "-------------------------------------------------"
read -p "Username: " username
useradd -m ${username}
passwd ${username}
usermod -aG wheel ${username}
echo "${username} ALL=(ALL) ALL" >> "/etc/sudoers.d/${username}"

echo "-------------------------------------------------"
echo "Configuring initramfs                            "
echo "-------------------------------------------------"
sed -i 's/^MODULES=()/MODULES=(btrfs)/' /etc/mkinitcpio.conf
sed -i 's/^FILES=()/FILES=(\/crypto_keyfile.bin)/' /etc/mkinitcpio.conf
sed -i 's/block filesystems keyboard/block encrypt filesystems keyboard/' /etc/mkinitcpio.conf
mkinitcpio -p linux

echo "-------------------------------------------------"
echo "Configuring Grub                                 "
echo "-------------------------------------------------"
ROOT_PARTITION_UUID=$(blkid -o value -s UUID ${ROOT_PARTITION})
sed -i "s|quiet|cryptdevice=UUID=${ROOT_PARTITION_UUID}:${CRYPTROOT_NAME} root=${CRYPTROOT_PATH}|" /etc/default/grub
sed -i 's/^#GRUB_ENABLE_CRYPTODISK/GRUB_ENABLE_CRYPTODISK/' /etc/default/grub
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

echo "-------------------------------------------------"
echo "Setting up crypttab                              "
echo "-------------------------------------------------"
echo "${CRYPTROOT_NAME}	UUID=${ROOT_PARTITION_UUID}	/crypto_keyfile.bin	luks" > /etc/crypttab

echo "-------------------------------------------------"
echo "Install Paru AUR Helper                          "
echo "-------------------------------------------------"
cd /tmp
git clone https://aur.archlinux.org/paru.git
cd paru/;makepkg -si --noconfirm;cd

echo "-------------------------------------------------"
echo "Setup Complete                                   "
echo "You can now reboot your system                   "
echo "-------------------------------------------------"
exit
umount -a
