
rpi-clone is a shell script that will back up (clone using dd and rsync)
a running Raspberry Pi file system to a destination SD card 'sdN' plugged
into a Pi USB port (via a USB card reader).
I use it to maintain backups of several Pi SD cards I have and the destination
backup SD cards can be a different size (smaller or larger) than the booted
SD card.

rpi-clone can clone the running system to a new SD card or can incrementally
rsync to existing backup Raspberry Pi SD cards.  During the clone to new SD
cards, rpi-clone gives you the opportunity to give a label name to the
partition 2 so you can keep track of which SD cards have been backed up.
Just stick a correspondingly named sticky label on each SD card you have
and you can look up the last clone date for that card in the rpi-clone log file
/var/log/rpi-clone.  My convention for my set of cards is to name 8GB cards:
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
This is done by a partial 'dd' from the running booted device /dev/mmcblk0
to the destination SD card /dev/sdN followed by a fdisk resize and mkfs.ext4
of /dev/sdN partition 2.  This creates a completed partition 1 containing
all boot files and an empty but properly sized partition 2 rootfs.
The SD card  partitions are then mounted on /mnt/clone and rsynced to the
running system.

You should avoid running other disk writing programs when running rpi-clone,
but I find rpi-clone works fine when I run it from a terminal window.
However I usually do quit my browser first because a browser can be
writing many temporary files.

rpi-clone must be run as root and you must have the rsync program installed.

After rpi-clone is finished with the clone it pauses and asks for confirmation
before unmounting the cloned to SD card.  This is so you can go look at
the clone results or make any custom final adjustments if needed.  For example,
I have a couple of Raspberry Pis and I use one as a master.  When I clone for
the benefit of the second Pi, I do a "cd /mnt/clone/etc" and fix the files
needed to customize for the second Pi.  This can be as simple as loading
new hosts and network interfaces file.  Just keep all the files on the master:

	/etc/hostname		# hostname is trivial, so don't really need the
	/etc/hostname.rpi0  # multiple copies - but I'll just list it here.
	/etc/hostname.rpi1
	/etc/hosts
	/etc/hosts.rpi0
	/etc/hosts.rpi1
	/etc/network/interfaces
	/etc/network/interfaces.rpi0
	/etc/network/interfaces.rpi1

In my case, rpi0 is my master so I really don't need the .rpi0 copies, but
I keep them just in case.  Then when cloning to update for rpi1, I just
copy the .rpi1 files over before letting rpi-clone umount everything.
But don't forget to cd out of the /mnt/clone tree before telling rpi-clone
to unmount.

rpi-clone is on github, to get it and install it to /usr/local/sbin:
Go to https://github.com/billw2/rpi-clone and download the zip file:

	$ unzip rpi-clone-master.zip
	$ cd rpi-clone-master
	$ cp rpi-clone /usr/local/sbin

or, use git to clone the repository:

	$ git clone https://github.com/billw2/rpi-clone.git 
	$ cd rpi-clone
	$ cp rpi-clone /usr/local/sbin


Bill Wilson
billw--at--gkrellm.net
