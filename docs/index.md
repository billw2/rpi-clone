---
# Feel free to add content and custom Front Matter to this file.
# To modify the layout, see https://jekyllrb.com/docs/themes/#overriding-theme-defaults

layout: home
---
`rpi-clone` is a shell script for cloning a running Raspberry Pi booted source
disk (SD card or USB disk) to a destination disk which will be bootable.

Destinations include:

  - SD cards in the SD card slot or a USB card reader
  - USB flash drives
  - USB hard drives and SSDs
  - NVMe drives attached directly to the Pi PCIe bus

## Quick Start Guide

Install `rpi-clone`:

```
curl https://raw.githubusercontent.com/geerlingguy/rpi-clone/master/install | sudo bash
```

> Alternatively, you can manually install from source if you don't trust the `curl | sudo bash` install script:
> 
> ```
> git clone https://github.com/geerlingguy/rpi-clone.git
> cd rpi-clone
> sudo cp rpi-clone rpi-clone-setup /usr/local/sbin
> ```

If booting off an internal microSD card, clone to an external USB drive:

```
sudo rpi-clone sda
```

If booting off an external USB drive, clone to the internal microSD card:

```
sudo rpi-clone mmcblk0
```

If booting off an internal microSD card, clone to a PCIe NVMe SSD (note: you [may need to change EEPROM settings to boot off NVMe SSDs](https://www.jeffgeerling.com/blog/2023/nvme-ssd-boot-raspberry-pi-5)):

```
sudo rpi-clone nvme0n1
```

For an exhaustive list of options and usage scenarios, read [this project's README](https://github.com/geerlingguy/rpi-clone).

## Uninstall

Assuming you used the `install` script with the `curl | sudo bash` installation method, the following command will remove both files that were downloaded:

```
sudo rm -rf /usr/local/sbin/rpi-clone*
```

## Code and License

The code for `rpi-clone` is maintained on GitHub:

[https://github.com/geerlingguy/rpi-clone](https://github.com/geerlingguy/rpi-clone).

The code is licensed under the `BSD 3-Clause License`.

## Author

This project was originally authored by [@billw2](https://github.com/billw2/rpi-clone), and is now maintained by [@geerlingguy](https://www.jeffgeerling.com), based on many patches by [@framp](https://www.linux-tips-and-tricks.de/en/).
