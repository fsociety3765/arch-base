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
  'htop'
  'wget'
  'tmux'
  'lsd'
  'zsh'
  'doas'
  'zsh-syntax-highlighting'
  'zsh-autosuggestions'
  'unzip'
  'unrar'
  'neovim'
  'nano'
  'bat'
  'btop'
  'ranger'
  'neofetch'
  'ncdu'
  'open-vm-tools'
)

for PKG in "${PKGS[@]}"; do
  echo "Installing: ${PKG}"
  pacman -S "$PKG" --noconfirm --needed
done

CPU_TYPE=$(lscpu | awk '/Vendor ID:/ {print $3}')
case "${CPU_TYPE}" in
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
echo "Create non-root user                             "
echo "-------------------------------------------------"
read -p "Username: " USERNAME
useradd -m ${USERNAME}
passwd ${USERNAME}
usermod -aG wheel ${USERNAME}
echo "${USERNAME} ALL=(ALL) ALL" >> "/etc/sudoers.d/${USERNAME}"
echo "permit persist :wheel" >> /etc/doas.conf
echo "permit persist :${USERNAME}" >> /etc/doas.conf
echo "USERNAME=${USERNAME}" >> /arch-base/.env

echo "-------------------------------------------------"
echo "Copying arch-base repo to user directory         "
echo "-------------------------------------------------"
cp -r /arch-base/ /home/${USERNAME}/
chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/arch-base/

