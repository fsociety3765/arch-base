#!/bin/bash

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
echo $ROOT_PARTITION
ROOT_PARTITION_UUID=$(blkid -o value -s UUID ${ROOT_PARTITION})
echo $ROOT_PARTITION_UUID
echo $CRYPTROOT_NAME
echo $CRYPTROOT_PATH
sed -i "s|quiet|cryptdevice=UUID=${ROOT_PARTITION_UUID}:${CRYPTROOT_NAME} root=${CRYPTROOT_PATH}|g" /etc/default/grub
sed -i 's/^#GRUB_ENABLE_CRYPTODISK/GRUB_ENABLE_CRYPTODISK/' /etc/default/grub
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

echo "-------------------------------------------------"
echo "Setting up crypttab                              "
echo "-------------------------------------------------"
echo "${CRYPTROOT_NAME}	UUID=${ROOT_PARTITION_UUID}	/crypto_keyfile.bin	luks" > /etc/crypttab

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
echo "Setup Complete                                   "
echo "-------------------------------------------------"

