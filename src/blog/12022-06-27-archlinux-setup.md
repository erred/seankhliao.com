# archlinux setup

## new laptop, new opinions

### _arch_ linux setup

Work said: here's a laptop, go set it up.

1. partitioning
   1. `parted /dev/nvme0n1p1`
   2. `mktable gpt`
   3. `mkpart efi 0 1G`
   4. `set 1 esp on`
   5. `mkpart primary 1G 100%`
2. encrypted root partition
   1. `cryptsetup luksFormat /dev/nvme0n1p1 root`
   2. `cryptsetup open /dev/nvme0n1p2`
   3. `mkfs.ext4 -i 1024 //dev/mapper/root`
   4. `mount /dev/mapper/root /mnt`
3. boot partition
   1. `mkfs.fat -F 32 /dev/nvme0n1p2`
   2. `mkdir /mnt/boot`
   3. `mount /dev/nvme0n1p1 /mnt/boot`
4. network
   1. `timedatectl set-ntp true`
   2. `iwctl station wlan0 scan`
   3. `iwctl station wlan0 connect $AP_NAME`
   4. `reflector --save /etc/pacman.d/mirrorlist -f 5 -p https`
5. install
   1. `pacstrap /mnt base base-devel linux linux-firmware intel-ucode iwd zsh zsh-completions terminus-font git neovim pam-u2f`
   2. `genfstab -U /mnt >> /mnt/etc/fstab`
   3. `arch-chroot /mnt`
6. user management
   1. `passwd`
   2. `chsh -s /bin/zsh`
   3. `rm /etc/skel/.bash*`
   4. `groupadd sudo`
   5. `echo '%sudo ALL=(ALL) ALL' > /etc/sudoers.d/sudo`
   6. `useradd -m -G adm,sudo -s /bin/zsh sean`
   7. `passwd sean`
7. encrypted root
   1. `echo "root /dev/nvme0n1p2 none password-echo=no,fido2-device=auto" >> /etc/crypttab`
   2. `mv /etc/crypttab /etc/crypttab.initramfs`
   3. `echo "/dev/mapper/root / ext4 rw,noatime 0 0" >> /etc/fstab`
   4. remove existing root mount in `/etc/fstab`
   5. in `/etc/mkinitcpio.conf` set `HOOKS=(base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt filesystems fsck)`
   6. `systemd-cryptenroll --fido2-device=auto /dev/nvme0n1p2`
8. other settings
   1. `echo $HOSTNAME > /etc/hostname`
   2. `sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen`
   3. `locale-gen`
   4. `echo LANG=en_US.UTF-8 > /etc/locale.conf`
   5. `echo FONT=ter-128n > /etc/vconsole.conf`
   6. networkd
      1. `echo '[Match]' >> /etc/systemd/network/12-wifi.network`
      2. `echo 'Name = wl*' >> /etc/systemd/network/12-wifi.network`
      3. `echo '[Network]' >> /etc/systemd/network/12-wifi.network`
      4. `echo 'DHCP = ipv4' >> /etc/systemd/network/12-wifi.network`
      5. `echo 'IPForward = yes' >> /etc/systemd/network/12-wifi.network`
   7. yubikeys
      1. for `/etc/pam.d/system-auth` set `auth sufficient pam_u2f.so cue origin=pam://$HOSTNAME appid=pam://$HOSTNAME authfile=/etc/u2f_keys`
      2. `pamu2fcfg -u sean -o pam://$HOSTNAME -i pam://$HOSTNAME >> /etc/u2f_keys` 1st key
      3. `pamu2fcfg -n -o pam://$HOSTNAME -i pam://$HOSTNAME >> /etc/u2f_keys` additional keys
9. boot setup
10. `mkinitcpio -p linux`
11. `bootctl install`
12. loader config
    1. `echo default arch >> /boot/loader/loader.conf`
    2. `echo timeout 0 >> /boot/loader/loader.conf`
    3. `echo console-mode max >> /boot/loader/loader.conf`
13. loader entry
    1. `echo title Arch Linux >> /boot/loader/entries/arch.conf`
    2. `echo linux /vmlinuz-linux >> /boot/loader/entries/arch.conf`
    3. `echo initrd /intel-ucode.img >> /boot/loader/entries/arch.conf`
    4. `echo initrd /initramfs-linux.img >> /boot/loader/entries/arch.conf`
    5. `echo options root=/dev/mapper/root quiet rw >> /boot/loader/entries/arch.conf`
14. reboot
15. more setup
    1. `timedatectl set-timezone Europe/London`
    2. `systemcctl enable --now systemd-{networkd,resolved,timesyncd} iwd`
    3. `iwctl station wlan0 scan`
    4. `iwctl station wlan0 connect $AP_NAME`

### _user_ environment setup

1. config
   1. `git clone https://github.com/seankhliao/.config`
   2. adjust `.config/git/config`
   3. `nvim`
2. other tools
   1. `pacman -S bat exa fzf git-delta htop jq openssh ripgrep rsync unzip xsv zip`
   2. curl ... yay
   3. `./yay -S yay-bin`
3. security
   1. `ssh-keygen -t ed25519`
4. desktop
   1. `pacman -S sway swaylock swaybg slurp grim mako i3status noto-fonts{,-cjk,-emoji} pipewire{,-pulse} pulsemixer wl-clipboard-x11 xdg-desktop-portal-wlr`
   2. `systemctl enable --user --now pipewire{,-pulse}`
   3. `systemctl enable --now bluetooth`
