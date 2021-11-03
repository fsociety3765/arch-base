# Arch-Base
A collection of bash scripts to get Arch Linux up and running with ease.

This is a slightly opinionated setup that uses an EFI boot partition and a BTRFS root partition encrypted with LUKS. There is no swap partition as I prefer to use ZRAM / ZSWAP or swapfile. 

## Minimum Recommended Hardware  
- 2 CPU Cores
- 4GB RAM  
  
Once up and running the RAM could be reduced. In testing with 2GB RAM, the install would crash during the AUR builds. So I would recommend at least 4GB RAM to run the installation. 

## Steps
1. Boot to live ISO
2. Refresh mirrors  
```pacman -Syy```
4. Install Git   
```pacman -S git --noconfirm```  
5. Clone the git repository  
```git clone https://github.com/fsociety3765/arch-base```
6. Move into the git repo and make all scripts executable  
```cd arch-base/ && chmod +x *.sh```
7. Run the `base.sh` script.  
```bash base.sh```  
8. Follow prompts until the setup is complete.
