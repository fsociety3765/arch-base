#!/bin/bash

echo "-------------------------------------------------"
echo "Installing Paru AUR Helper                       "
echo "-------------------------------------------------"
git clone https://aur.archlinux.org/paru.git
cd paru/;makepkg -si --noconfirm;cd
rm -rf paru/

