# Arch-Base
A collection of bash script to get Arch Linux up and running with ease.

This is a slightly opinionated setup that uses an EFI boot partition and a BTRFS root partition encrypted with LUKS. There is no swap partition as I prefer to use ZRAM / ZSWAP or swapfile. 

## Steps
1. Boot to live ISO
2. Refresh mirrors  
```pacman -Syy```
3. Partition the disk with an EFI boot partition of at least 260M and root partition
4. Setup LUKS on the root partition  
```cryptsetup -y -v --type luks1 luksFormat /dev/[root partition]```
5. Open the LUKS crypt volume. The opened LUKS crypt volume will be placed at `/dev/mapper/[volume name]`, the name in this case is `cryptroot` but can be anything.  
```cryptsetup open /dev/[root partition] cryptroot```
6. Format the partitions  
```mkfs.fat -F32 /dev/[efi boot partition]```  
```mkfs.btrfs /dev/mapper/cryptroot```  
7. Mount the root filesystem to `/mnt` to create the BTRFS subvolumes  
```mount /dev/mapper/cryptroot /mnt```
8. Create BTRFS subvolumes. Create at least the root (`@`) and home (`@home`) subvolumes. The rest is optional.  
```cd /mnt```  
```btrfs subvolume create @```  
```btrfs subvolume create @home```  
```btrfs subvolume create @snapshots```  
```btrfs subvolume create @log```  
```btrfs subvolume create @cache```  
9. Exit `/mnt` and unmount it  
```cd ..```  
```umount /mnt```  
10. Setup the mount points. Create directories where neccessary.  
```mount -o noatime,compress=zstd,space_cache,discard=async,subvol=@ /dev/mapper/cryptroot /mnt```  
```mkdir -p /mnt/boot/efi```  
```mkdir -p /mnt/home```  
```mkdir -p /mnt/var/log```  
```mkdir -p /mnt/var/cache```  
```mount -o noatime,compress=zstd,space_cache,discard=async,subvol=@home /dev/mapper/cryptroot /mnt/home```  
```mount -o noatime,compress=zstd,space_cache,discard=async,subvol=@log /dev/mapper/cryptroot /mnt/var/log```  
```mount -o noatime,compress=zstd,space_cache,discard=async,subvol=@cache /dev/mapper/cryptroot /mnt/var/cache```  
```mount /dev/[efi boot partition] /mnt/boot/efi```  
11. Install the base packages to `/mnt`  
```pacstrap /mnt base linux linux-firmware git vim intel-ucode (or amd-ucode)```
12. Generate the FSTAB file  
```genfstab -U /mnt >> /mnt/etc/fstab```
13. Chroot into the installation  
```arch-chroot /mnt```
14. Clone the git repository  
```git clone https://github.com/fsociety3765/arch-base```
