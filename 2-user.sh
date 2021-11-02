#!/bin/bash

echo "-------------------------------------------------"
echo "Installing Paru AUR Helper                       "
echo "-------------------------------------------------"
git clone https://aur.archlinux.org/paru.git /tmp/paru
cd /tmp/paru/;makepkg -si --noconfirm;cd
rm -rf /tmp/paru/
