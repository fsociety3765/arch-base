# Arch-Base
A collection of bash scripts to get Arch Linux up and running with ease.

This is a slightly opinionated setup that uses an EFI boot partition and a BTRFS root partition encrypted with LUKS. There is no swap partition. Swap is provided using the combination of a 2GB swapfile and 1GB of ZRAM. 

## Minimum Recommended Hardware  
- 2 CPU Cores
- 4GB RAM  
- 10GB HDD

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
