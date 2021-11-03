#!/bin/bash

echo "-------------------------------------------------"
echo "Installing Paru AUR Helper                       "
echo "This may take some time... Please be patient     "
echo "-------------------------------------------------"
git clone https://aur.archlinux.org/paru-bin.git ~/paru-bin
cd ~/paru-bin/;makepkg -si --noconfirm;cd ~
rm -rf paru-bin/

echo "-------------------------------------------------"
echo "Installing AUR packages                          "
echo "This may take some time... Please be patient     "
echo "-------------------------------------------------"
PKGS=(
  'timeshift'
  'zramd'
)

for PKG in "${PKGS[@]}"; do
    paru -S --noconfirm $PKG
done

echo "-------------------------------------------------"
echo "Setting up Timeshift snapshots                   "
echo "-------------------------------------------------"
source /arch-base/.env
sudo timeshift --create --comment "Initial" --tags D --snapshot-device ${ROOT_PARTITION} --btrfs
sudo timeshift --list --snapshot-device ${ROOT_PARTITION}

echo "-------------------------------------------------"
echo "Setting up ZRAM                                  "
echo "-------------------------------------------------"
sudo sed -i 's/# MAX_SIZE=8192/MAX_SIZE=1024/g' /etc/default/zramd
sudo systemctl enable --now zramd

