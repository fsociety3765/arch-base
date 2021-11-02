#!/bin/bash

bash 0-preinstall.sh
arch-chroot /mnt /arch-base/1-setup.sh
arch-chroot /mnt /usr/bin/runuser -u ${username} -- /home/${username}/arch-base/2-user.sh
arch-chroot /mnt /arch-base/3-post-setup.sh
