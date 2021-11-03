#!/bin/bash

echo "-------------------------------------------------"
echo "Installing Paru AUR Helper                       "
echo "This may take some time... Please be patient     "
echo "-------------------------------------------------"
git clone https://aur.archlinux.org/paru.git ~/paru
cd ~/paru/;makepkg -si --noconfirm;cd ~
rm -rf paru/

echo "-------------------------------------------------"
echo "Installing AUR packages                          "
echo "This may take some time... Please be patient     "
echo "-------------------------------------------------"
PKGS=(
  'timeshift'
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

