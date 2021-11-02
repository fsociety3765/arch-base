#!/bin/bash

echo "-------------------------------------------------"
echo "Installing Paru AUR Helper                       "
echo "This may take some time... Please be patient     "
echo "-------------------------------------------------"
git clone https://aur.archlinux.org/paru.git ~/paru
cd ~/paru/;makepkg -si --noconfirm;cd ~
rm -rf paru/

