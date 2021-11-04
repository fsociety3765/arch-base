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
echo "Setup root user bash                             "
echo "-------------------------------------------------"
echo "[[ -f ~/.bashrc ]] && . ~/.bashrc" >> ${HOME}/.bash_profile
cp /arch-base/.bashrc ${HOME}/
source ${HOME}/.bashrc

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
  'cronie'
  'avahi'
  'xdg-user-dirs'
  'xdg-utils' 
  'gvfs'
  'gvfs-smb'
  'nfs-utils'
  'inetutils'
  'dnsutils'
  'alsa-utils'
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
  'snapper'
  'snap-pac'
  'ufw'
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
echo "Setup MAKEPKG config                             "
echo "-------------------------------------------------"
CPU_CORES=$(grep -c ^processor /proc/cpuinfo)
echo "You have ${CPU_CORES} cores."
echo "-------------------------------------------------"
echo "Changing the makeflags for "${CPU_CORES}" cores."
if [[  ${CPU_CORES} -gt 2 ]]; then
	sed -i "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j${CPU_CORES}\"/g" /etc/makepkg.conf
	echo "Changing the compression settings for "${CPU_CORES}" cores."
	sed -i "s/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -T ${CPU_CORES} -z -)/g" /etc/makepkg.conf
fi

echo "-------------------------------------------------"
echo "Create non-root user                             "
echo "-------------------------------------------------"
read -p "Username: " USERNAME
useradd -m ${USERNAME}
passwd ${USERNAME}
usermod -aG wheel ${USERNAME}
echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" >> "/etc/sudoers.d/${USERNAME}"
sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
echo "permit persist :wheel" >> /etc/doas.conf
echo "permit persist :${USERNAME}" >> /etc/doas.conf
echo "USERNAME=${USERNAME}" >> /arch-base/.env

echo "-------------------------------------------------"
echo "Setup Snapper snapshots                          "
echo "-------------------------------------------------"
umount /.snapshots
rm -r /.snapshots
snapper --no-dbus -c root create-config /
btrfs subvolume delete /.snapshots
mkdir /.snapshots
mount -a
chmod 750 /.snapshots
sed -i "s/ALLOW_USERS=\"\"/ALLOW_USERS=\"${USERNAME}\"/g" /etc/snapper/configs/root
sed -i "s/TIMELINE_LIMIT_YEARLY=\"10\"/TIMELINE_LIMIT_YEARLY=\"0\"/g" /etc/snapper/configs/root
sed -i "s/TIMELINE_LIMIT_MONTHLY=\"10\"/TIMELINE_LIMIT_MONTHLY=\"0\"/g" /etc/snapper/configs/root
sed -i "s/TIMELINE_LIMIT_DAILY=\"10\"/TIMELINE_LIMIT_DAILY=\"7\"/g" /etc/snapper/configs/root
sed -i "s/TIMELINE_LIMIT_HOURLY=\"10\"/TIMELINE_LIMIT_HOURLY=\"5\"/g" /etc/snapper/configs/root

echo "-------------------------------------------------"
echo "Copying arch-base repo to user directory         "
echo "-------------------------------------------------"
cp -r /arch-base/ /home/${USERNAME}/
chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/arch-base/

