# rpi-clone

rpi-clone is a shell script that will back up (clone using dd and rsync)
a running Raspberry Pi file system to a destination SD card 'sdN' plugged
into a Pi USB port (via a USB card reader).


## Prerequisites

rpi-clone works on Raspberry Pi distributions which have a VFAT boot
partition 1 and a Linux root partition 2.  Tested on Raspbian but should
work on other distributions which have this same two partition structure.

**PLEASE NOTE: rpi-clone does not work with NOOBS.**

rpi-clone requires rsync and it is recommended you also have dosfstools


## Installing / Updating

Clone this repo (or download the zip) and run the installer as root...

```
$ git clone https://github.com/billw2/rpi-clone.git
$ cd rpi-clone
$ sudo ./install.sh
```

This will;
+ install or update rpi-clone as necessary and advise you of any missing 
dependencies / recommendations.
+ If you have cloned the repo, the installer can automatically perform a 
`git pull origin master` to update itself to latest version. If you have 
cloned from another source you may or may not want to do this.
+ If you downloaded the zip, you will be prompted to update it manually
+ The installer will not overwrite existing configuration files - if you 
need to install latest config files fresh, simply uninstall/install
+ The rpi-clone command script is installed at `/usr/local/sbin/` and the 
configuration files are installed at `/etc/rpi-clone/`   


## Uninstalling

Run the uninstaller to remove rpi-clone and configuration files.

```
$ sudo ./uninstall.sh
```

The uninstaller will place a backup of the configuration files at
`/tmp/rpi-clone-bak/` in case you need to restore them.


## Usage

rpi-clone must be run as root

You will need to know the device identifier of your SD card. 
rpi-clone cannot (yet) determine this for you, but run the following command
to identify all attached disks...

```
$ sudo fdisk -l
```

A couple of tips and a couple warnings when identifying your device;

+ the first disk will be the current booted Raspberry Pi SD card `mmcblk0p1 / 
mmcblk0p2` - i.e. the disk you will be *cloning from* not *cloning to*
+ size is normally the easiest way to identify particular SD cards
+ using the incorrect device identifier will likely result in data loss on that disk
+ depending on the system setup, the device identifier *can change* between reboots, 
so you should always confirm the correct disk before running rpi-clone

### Examples

Usage info:
```
$ sudo rpi-clone --help
```

To clone to card at sdb:
```
$ sudo rpi-clone sdb
```

To clone card at sdb and force initialization of the disk:
```
$ sudo rpi-clone sdb -f
```
As above but also list files as they are synced:
```
$ sudo rpi-clone sdb -f -v
```

NB: rpi-clone takes command line switches as individual arguments,
they cannot be combined as you may do for other linux commands, eg: `-fv`


## Use cases

I use it to maintain backups of several Pi SD cards I have and the destination
backup SD cards can be a different size (smaller or larger) than the booted
SD card.

rpi-clone can clone the running system to a new SD card or can incrementally
rsync to existing backup Raspberry Pi SD cards.  During the clone to new SD
cards, rpi-clone gives you the opportunity to give a label name to the
partition 2 so you can keep track of which SD cards have been backed up.
Just stick a correspondingly named sticky label on each SD card you have
and you can look up the last clone date for that card in the rpi-clone log file
`/var/log/rpi-clone`.  My convention for my set of cards is to name 8GB cards:
	SD-RPI-8A, SD-RPI-8B, ...
and similarly, 4GB cards:
	SD-RPI-4A, ...

If the destination SD card has an existing partition 1 and partition 2
matching the running partition types, rpi-clone assumes (unless using the
-f option) that the SD card is an existing backup with the partitions
properly sized and set up for a Raspberry Pi.  All that is needed
is to mount the partitions and rsync them to the running system.

If these partitions are not found (or -f), then rpi-clone will ask
if it is OK to initialize the destination SD card partitions.
This is done by a partial 'dd' from the running booted device `/dev/mmcblk0`
to the destination SD card `/dev/sdN` followed by a fdisk resize and mkfs.ext4
of `/dev/sdN` partition 2.  This creates a completed partition 1 containing
all boot files and an empty but properly sized partition 2 rootfs.
The SD card  partitions are then mounted on `/mnt/clone` and rsynced to the
running system.

You should avoid running other disk writing programs when running rpi-clone,
but I find rpi-clone works fine when I run it from a terminal window.
However I usually do quit my browser first because a browser can be
writing many temporary files.

rpi-clone will not cross filesystem boundaries by default - this is normally
desirable. If you wish to include your mounted drive(s) in the clone,
use the -c switch.  But use this option with caution since any disk mounted
under /mnt or /media will be included in the clone.

After rpi-clone is finished with the clone it pauses and asks for confirmation
before unmounting the cloned to SD card.  This is so you can go look at
the clone results or make any custom final adjustments if needed.  For example,
I have a couple of Raspberry Pis and I use one as a master.  When I clone for
the benefit of the second Pi, I do a `cd /mnt/clone/etc` and fix the files
needed to customize for the second Pi (well, actually I do that with a
script that takes my desired Pi hostname as an argument).  Either way, you
typically might need to change at least these files:

```
/etc/hostname			# I have one of rpi0, rpi0, ...
/etc/hosts			# The localhost line should probably be changed
/etc/network/interfaces		# If you need to set up a static IP or alias
```

If you cd into the `/mnt/clone/` tree to make some of these customizations
or just to look around, don't forget to cd out of the `/mnt/clone` tree
before telling rpi-clone to unmount.


## Configuration
rpi-clone utilises configuration files at `/etc/rpi-clone/`
These can be edited to tune rpi-clone for your system.
Notes on each of the configurable items are included in the files.

+ **rpi-clone.conf** - main configuration file
+ **rsync.excludes** - files/directories to be excluded from the rsync process


## Additional Notes
For a French translation of rpi-clone by Mehdi HAMIDA, go to:
+ https://github.com/idem2lyon/rpi-clone

GTR2Fan on the Pi forums has instructions for putting rpi-clone into
the menu of the desktop GUI:
+ https://www.raspberrypi.org/forums/viewtopic.php?f=29&t=137693&p=914109#p914109


## Authors
+ **Bill Wilson** - *Original developer* (billw--at--gkrellm.net)
+ **Paul Fernihough** - *Contributer* (paul--at--spoddycoder.com)
