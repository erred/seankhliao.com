# manual hetzner arch linux

## hand roll all the things, no more install magic


### _manual_ arch install on hetzner

Hetzner's root servers (bare metal servers)
come with [installimage](https://github.com/hetzneronline/installimage),
giving you an interactive auto installer for a few distros.
But their spin of Arch Linux comes with some extra cruft,
and I want to recreate the process of installing locally from a live usb,
without the usb.

#### _chroot_

Instead of booting into a live image,
boot into Hetzner's rescue system (a debian based netboot environment).
We're going to pull down a bootstrap environment,
chroot into it and use that as our install environment.

```sh
$ cd /tmp
$ curl -L https://mirror.example.com/archlinux-bootstrap-0000-00-00-x86_64.tar.gz | tar xzvf -

# enable some mirrors
$ vim root.x86_64/etc/pacman.d/mirrorlist
# comment out CheckSpace
$ vim root.x86_64/etc/pacman.conf

# chroot into the arch environment
$ ./root.x86_64/bin/arch-chroot root.x86_64

# pacman and some tools we need
$ pacman-key --init
$ pacman-key --populate archlinux
$ pacman -Sy mdadm parted reflector
$ reflector --save /etc/pacman.d/mirrorlist --threads 16 -p https -a 1 --score 5
```

#### _hardware_ setup

We (or I) need disk space, and I have 2 8TB disks for this.
I don't particularly care about safety, and instead prefer not to think about partitions.
Software RAID 0 it is.

I'm aiming for a boot partition and everything else in `/`.
The extra space is for GRUB.

```sh
# cleanup previous mdadm setup, repeat for all /dev/md*
$ mdadm --stop /dev/md0
$ mdadm --remove /dev/md0
$ mdadm --zero-superblock /dev/sda2

# repartition disks, repeat for all disks
$ parted /dev/sda
(parted) mktable gpt
(parted) mkpart primary 0 1MB
(parted) mkpart primary 1MB 1GB
(parted) mkpart primary 1GB 100%
(parted) set 1 bios_grub on
(parted) set 2 raid on
(parted) set 3 raid on
(parted) quit

$ mdadm --create --verbose --level=0 --metadata=1.2 --raid-devices=2 /dev/md/boot /dev/sda2 /dev/sdb2
$ mdadm --create --verbose --level=0 --metadata=1.2 --raid-devices=2 /dev/md/root /dev/sda3 /dev/sdb3

$ mkfs.ext4 -v -L root -b 4096 -E stride=128,stripe-width=256 /dev/md126
$ mkfs.ext4 -v -L boot -b 4096 -E stride=128,stripe-width=256 /dev/md127

$ mount /dev/md126 /mnt
$ mkdir /mnt/boot
$ mount /dev/md127 /mnt/boot
```

#### _pacstrap_

Now we can install the actual image we want onto our new disks.

```sh
$ pacstrap /mnt \
  base base-devel linux linux-firmware intel-ucode \
  grub mdadm \                                        # boot
  arch-install-scripts \                              # nice to have arch-chroot when you mess up
  openssh \                                           # it's a server, it needs this
  neovim zsh zsh-completions sudo \
  qemu-headless

$ genfstab -U /mnt >> /mnt/etc/fstab
$ mdadm --detail --scan >> /mnt/etc/mdadm.conf

$ arch-chroot /mnt

# add mdadm hooks
$ nvim /etc/mkinitcpio.conf
$ mkinitcpio -p linux
```

#### _bootable_ install

From inside our second level chroot (the actual system we'll be keeping),
we need to run some extra setup to ensure it can boot up and be connectable.

```sh
$ grub-install /dev/sda
$ grub-install /dev/sdb
# configure mdadm modules
$ nvim /etc/default/grub
$ grub-mkconfig -o /boot/grub/grub.cfg
```

#### _networking_

Our system has a static IP, but we still need to configure that.

```sh
$ echo medea > /etc/hostname
$ nvim /etc/systemd/network/10-ether.network
$ nvim /etc/resolv.conf
$ systemctl enable systemd-timesyncd systemd-networkd
```

We also want ssh

```sh
# lock it down, change port, use HostKeyAlgorithms to limit used keys
$ nvim /etc/ssh/sshd_config
# disable generation of unused keys
# /etc/systemd/system/sshdgenkeys.service.d/override.conf
# [Unit]
# ConditionPathExists=
# ConditionPathExists=|!/etc/ssh/ssh_host_ed25519_key
# ConditionPathExists=|!/etc/ssh/ssh_host_ed25519_key.pub
#
# [Service]
# ExecStart=/usr/bin/ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key
$ systemctl edit sshdgenkeys
$ systemctl enable sshd

# keys to login
$ nvim /root/.ssh/authorized_keys
```

#### _other_

```sh
# locale
$ nvim /etc/locale-gen
$ locale-gen

$ timedatectl set-timezone UTC

# set better defaults
$ chsh -s /bin/zsh
$ nvim /etc/default/useradd
$ rm /etc/skel/.bash*

# passwordless sudo
$ groupadd sudo
$ echo '%sudo ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/sudo

# my user
$ useradd -m -G sudo arccy
$ passwd arccy
```

#### _pray_

Hope I didn't get anything wrong and reboot.

If it doesn't work, reboot into rescue,
mount the raid devices into `/mnt` and `/mnt/boot`,
and use the `arch-chroot` from in there to chroot into `/mnt`
