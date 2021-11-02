# Arch-Base
A collection of bash scripts to get Arch Linux up and running with ease.

This is a slightly opinionated setup that uses an EFI boot partition and a BTRFS root partition encrypted with LUKS. There is no swap partition as I prefer to use ZRAM / ZSWAP or swapfile. 

## Steps
1. Boot to live ISO
2. Refresh mirrors  
```pacman -Syy```
4. Install Git   
```pacman -S git```  
5. Clone the git repository  
```git clone https://github.com/fsociety3765/arch-base```
6. Move into the git repo and make all scripts executable  
```cd arch-base/ && chmod +x *.sh```
7. Run the `base.sh` script.  
```bash base.sh```  
8. Follow prompts until the setup is complete.
