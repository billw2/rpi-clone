## rpi-clone

Version 2 is a complete rewrite with much improved capability over
the original.  See the examples below.

rpi-clone is a shell script that is for cloning a running
Raspberry Pi booted source disk (SD card or USB disk) to a destination
disk which will be bootable. Destination disks are SD cards in the SD
card slot or a USB card reader, USB flash disks, or USB hard drives.

rpi-clone may work in SD card booted devices other than a
Raspberry Pi because when initializing a disk, rpi-clone images a
first /boot partition and boot loader setup can be captured.
But this will depend on how the boot loading is handled on each device.

I also am now using rpi-clone on my Debian desktop, but there are too many
variables in how a /etc/fstab can be set up and a desktop bootloader like
grub can be configured for this to be an officially  supported way of
using rpi-clone.

#### Clone by initialization
Source disk mounted partition types are compared to
corresponding destination disk partitions.
If the types are not compatible, then the clone is an
initialization.  First, the destination partition structure is
initialized to match the source disk.  This is is a convenience that gets
the destination disk partitioned so you can avoid manual partitioning.
All partitions are then cloned either
by imaging source unmounted partitions to corresponding destination
partitions or by doing a destination mkfs followed by a file system
sync of source mounted partitions to the destination partitions.
So to avoid file system inconsistencies, live partitions are synced
and not imaged with one exception.  If the first partition
is the /boot partition, it is imaged so that bootloader install state
can be preserved.  This is not an issue on a Pi where the GPU knows how
to boot, but could be on other systems that have a bootloader install.
A mounted /boot is rarely active so its file system
state should be consistent, just don't be doing anything to modify your
boot configuration when running rpi-clone.

#### Clone by syncing
If the file system types
are compatible, the destination partitions will be mounted and the clone
is a sync of modified files from source to destination.  After an
initialize clone, subsequent clones will be syncs.  You can skip
the initialize clone and go straight to a sync clone
if a destination disk is manually partitioned and file
systems created (mkfs) that match the mounted source partitions.  In
this case a destination disk does not need all partitions to match, only
the mounted ones.  Doing this you can have special case use of partitions on
different systems.  See my Pi3 example below.


## Install
rpi-clone is on github and is downloaded by cloning the repository.
It is a standalone script and the install is a simple copy to a
bin directory.  When run it checks its program dependencies and offers to
install needed packages.  But currently rpi-clone knows how to install
only Debian packages with apt-get.

#### On a Raspberry Pi:
```
	$ git clone https://github.com/billw2/rpi-clone.git 
	$ cd rpi-clone
	$ sudo cp rpi-clone rpi-clone-setup /usr/local/sbin
```
Run rpi-clone or rpi-clone-setup with no args to print usage.

rpi-clone-setup is for setting the hostname in /etc/hostname and /etc/hosts
files.  It is run automatically by rpi-clone if -s args are given,
but before your first clone using a -s option, test run rpi-clone-setup with:
```
      $ sudo rpi-clone-setup -t testhostname
```
And check the files under /tmp/clone-test to be sure the files have been
edited correctly.  If you need additional customizations to a clone,
add them to the rpi-clone-setup script.

#### On other OS:
  To install on another OS, rpi-clone may be renamed to suit.  For example,
  on my Debian desktop I rename:
```
	$ git clone https://github.com/billw2/rpi-clone.git 
	$ cd rpi-clone
	$ sudo cp rpi-clone /usr/local/sbin/sys-clone
	$ sudo cp rpi-clone-setup /usr/local/sbin/sys-clone-setup
```
  
If your other OS is a SD card booted system, it will possibly work.
However it currently does not work for emmc booted devices.

rpi-clone does not directly support usage on a desktop OS.
However, I do use it with my Debian desktop because my setup script
handles my /etc/grub.d/ custom menus and fstab, and the script runs
grub_install.  rpi-clone does handle editing of
PARTUUID values in /etc/fstab, but a customized setup script for
a desktop might need to handle file system UUID values or device
name editing in /etc/fstab and the bootloader config.  If these possible
issues are handled in a setup script, then rpi-clone should work fine
creating clone backup disks for a desktop.

## Usage
To get a usage screen showing available options,
run rpi-clone without any arguments:
```
pi@rpi0: $ sudo ./rpi-clone
No destination disk given.

usage: rpi-clone sdN {-v|--verbose} {-f|--force-initialize}
         {-u|--unattended} {-U|--Unattended} {-q|--quiet}
         {-s|--setup} {-e|--edit-fstab sdX }
         {-m|--mountdir dir } {-l|--leave-sd-usb-boot}
         {-a|--all-sync} {-F|--Force-sync} {-x} {-V|--version}
         {--convert-fstab-to-partuuid}

    -v      - verbose rsync, list all files as they are copied.
    -f      - force initialize the destination disk by imaging the booted disk.
    -u      - unattended clone if not initializing.  No confirmations asked,
                but abort if disk needs initializing or on error.
    -U      - unattended even if initializing. No confirmations asked,
                but abort only on errors.
    -q      - quiet mode, no output unless errors or initializing. Implies -u.
    -s host - add 'host' to args passed to script rpi-clone-setup and run it
                after cloning but before unmounting partitions. For setting
                clone disk hostname, but args can be what the script expects.
    -e sdX  - edit destination fstab to change booted device names to new
                device 'sdX'.  This is Only for fstabs that use device names.
    -m dir  - Add dir to a custom list of mounted directories to sync.  The
                root directory is always synced.  NA when initializing.
    -l      - leave SD card to USB boot alone when cloning to SD card mmcblk0
                from a USB boot.  This preserves a SD card to USB boot setup.
    -a      - Sync all partitions if types compatible, not just mounted ones.
    -F      - force file system sync even if errors.
                If source used > destination space error, do the sync anyway.
                If a source partition mount error, skip it and do other syncs.
    -x      - use set -x for very verbose bash shell script debugging
    -V      - print rpi-clone version.
```
+ See examples below for command line options usage.
+ rpi-clone version 1 briefly had a -s option that is replaced with a
  -s option that has different meaning.

## rpi-clone Example Runs
#### An aside note
You will see in one example below that the clone command will need
to be run differently depending on if device names or PARTUUID is used
in /etc/fstab.  If device names are used you will have to add a "-e sdX"
where sdX will be the "expected" disk name a USB disk is assigned during
boot.  Usually this works, but if you have multiple disk devices plugged
into USB ports it may not work.  While this may not be an issue for you now,
recent Raspbian releases now use PARTUUID as standard and in the long
run you may at some point want to convert.
So as a convenience, if you want to convert to using
PARTUUID, rpi-clone can do that for you, run:
```
$ sudo rpi-clone --convert-fstab-to-partuuid
```
You only need to ever do this once.  Subsequent rpi-clone runs will propagate
PARTUUID usage to disks that you clone to.  This also converts cmdline.txt.
But get some clone backups before doing this because this changes
your booted disk.

#### 1) First clone to a new SD card in USB card reader
In this example a new SD card in a USB card reader has been plugged in
that I want to clone to.  It shows up as sdb because I have another USB
disk sda plugged in. Look in /proc/partitions to see where yours is.
The destination disk does not have partition types matching the booted disk.

+ The clone will be an initialize because of partition types mismatch.
+ The destination last partition will be resized down in this case because
the destination disk is smaller than the booted disk.
+ rpi-clone will ask for a destination root label which I will give
so I can keep track of my clones.
+ If PARTUUID is used in fstab and cmdline.txt, those files will be edited
to use the PARTUUID of the destination SD card.  The SD card will
bootable when plugged in to the SD card slot.
+ If fstab and cmdline.txt use device names (mmcblk0), then no edits are
necessary and the card will be bootable when plugged into a SD card slot.
```
pi@rpi0: $ sudo ./rpi-clone sdb

Booted disk: mmcblk0 16.0GB                Destination disk: sdb 8.0GB
---------------------------------------------------------------------------
Part      Size    FS     Label           Part   Size    FS     Label
1 /boot   58.4MB  fat16  --              1       8.0GB  fat32  --
2 root    16.0GB  ext4   SD-RPI-s1                               
---------------------------------------------------------------------------
== Initialize: IMAGE mmcblk0 partition table to sdb - FS types mismatch ==
1 /boot     (22.5MB used)    : IMAGE     to sdb1  FSCK
2 root      (6.0GB used)     : RESIZE(8.0GB) MKFS SYNC to sdb2
---------------------------------------------------------------------------
Run setup script       : no
Verbose mode           : no
-----------------------:
** WARNING **          : All destination disk sdb data will be overwritten!
                       : The partition structure will be imaged from mmcblk0.
-----------------------:

Initialize and clone to the destination disk sdb?  (yes/no): yes
Optional destination rootfs /dev/sdb2 label (16 chars max): SD-RPI-8a
... 
```

#### 2) Subsequent clone to the same SD card in USB card reader as example 1
This time the destination partition type will match the source booted
types, and I'll add a rpi-clone-setup script -s arg to set a
different destination disk hostname.

+ The clone will be a pure sync where only modified files will be copied.
+ The setup script will set the hostnames in the destination disk files
/etc/hostname and /etc/hosts to what I give with -s, in this case rpi2.
 ```
pi@rpi0: $ sudo ./rpi-clone sdb -s rpi2

Booted disk: mmcblk0 16.0GB                Destination disk: sdb 8.0GB
---------------------------------------------------------------------------
Part      Size    FS     Label           Part   Size    FS     Label
1 /boot   58.4MB  fat16  --              1      58.4MB  fat16  --
2 root    16.0GB  ext4   SD-RPI-s1       2       8.0GB  ext4   SD-RPI-8a
---------------------------------------------------------------------------
== SYNC mmcblk0 file systems to sdb ==
/boot       (22.5MB used)    : SYNC to sdb1 (58.4MB size)
/           (6.0GB used)     : SYNC to sdb2 (8.0GB size)
---------------------------------------------------------------------------
Run setup script       : rpi-clone-setup  rpi2
Verbose mode           : no
-----------------------:

Ok to proceed with the clone?  (yes/no): 
```

#### 3) Cloning a Pi3 when fstab uses PARTUUID
If fstab and cmdline.txt use PARTUUID as is the case in recent
Raspbian distributions, rpi-clone always edits**
the destination fstab and cmdline.txt to use the PARTUUID of the
destination disk.  So the destination is always bootable.  If it
is a USB flash or hard drive it is automatically bootable on a Pi3
as a USB disk so long as the Pi3 has been USB boot enabled with
a program_usb_boot_mode=1 line in /boot/config.txt.

** There is one exception.  When using the -l option, which is used for
creating or preserving a special SD card to USB boot, the cmdline.txt
on the SD card is not edited after a clone to the SD card, see
examples 4 and 5.

#### 4) Creating a USB bootable disk for other than a USB enabled Pi3
rpi-clone can be used to create a SD card to USB boot setup and preserve
that setup when cloning from a USB boot back to the SD card slot.
With the SD card booted and a target USB disk plugged in and assuming
the USB disk shows up as sda, the initial clone command depends on
fstab usage of device names or PARTUUID.

=> Before you do this, have a backup of your booted SD card made
as in example 2 without the -l option because these steps will
change the booted SD card cmdline.txt to a USB boot.

If fstab is using PARTUUID, run:
```
$ rpi-clone -l sda
```
Or if fstab is using device names, run:
```
$ rpi-clone -l -e sda sda
```
+ Destination disk "sda" will be synced or initialized if required (or add
the -f option to force initialize).
+ After files are synced the destination sda fstab and cmdline.txt will
be edited to reference either device names or PARTUUID for the USB disk.
For the fstab uses device names case, the "-e sda" means to edit the
destination /etc/fstab to use "sda" for the root (will be sda1) and
/boot (will be sda2) lines. Also, the destination disk /boot/cmdline.txt
will be edited to use root=/dev/sda2.  It is expected that when the USB disk
is plugged in for booting to, it will be sda and this will be a cause
of boot failure if it is not.  So using PARTUUID is better because that
will reliably boot.
+ The -l option causes the SD card cmdline.txt to be backed up to
cmdline.boot and the destination USB disk cmdline.txt to be copied
to the SD card.  Since the USB cmdline.txt was edited to reference
the USB disk, the next Pi boot will start with the SD card
/boot partition, but will redirect to using the USB root partition.
Since the USB fstab was edited to reference the USB disk, the Pi will boot
with the USB partition 1 mounted on /boot.
The SD card /boot partition that initiated the boot process
is no longer in use but can remain in place for subsequent
SD card to USB boots.  To make the SD card standalone bootable
again, its cmdline.boot can be moved back to cmdline.txt.

+ If -l is not used, rpi-clone will not replace the currently booted SD card
cmdline.txt and it will need to be edited by hand for the USB boot to work.

+ Also a caution note if fstab uses device names: check your
/boot to be sure it is mounted with /dev/sda1 after booting to USB.
I have a Pi where this fails even though syslog says it mounted.
Just be sure to check when you first do this and before you try example 5.

Now when the Pi is booted from SD card to USB and the SD card is no longer
in use, the SD card slot is available for cloning to.

#### 5) Cloning back to SD cards in the SD card slot from USB boots
Whether the boot was a Pi3 straight to USB or a SD card to USB,
the SD card is not in use so it is free** to clone back to.  This
creates a standalone bootable SD card:
```
$ rpi-clone mmcblk0
```
However, for the case where the boot was SD card to USB,
this destroys the ability of the SD card to boot to USB.
To preserve that SD to USB boot setup, run:
```
$ rpi-clone -l mmcblk0
```
+ The SD card is cloned to as before.  It now has the USB /boot/cmdline.txt.
+ But the -l option prevents editing that cmdline.txt to reference the SD card.
It is left alone so that it still references the USB root partition.
So the clone has created USB disk to SD card backup  while preserving
the SD card to USB boot setup.  On the SD card a backup cmdline.boot
is created and edited to reference the SD card.  That backup can be moved
to be cmdline.txt to make the SD card standalone bootable should
you ever want to do that.
Or you could just clone to the SD card without using -l.
+ Both above mmcblk0 clone commands apply whether using PARTUUID or
device names.  When using device names and cloning to SD cards,
rpi-clone knows fstab device names need editing so "-e mmcblk0p" is assumed.
Now the SD card can be left in permanently and periodically cloned to for
backups and reboots to USB will work as you want.  Or other SD
cards can be inserted to create a set of backups.
If making a clone for another Pi that will be SD card bootable, don't use -l.
+ **Warning: this works if the original SD card to USB boot setup has edited
the USB /etc/fstab to reference USB partitions as is done by rpi-clone
when creating a USB bootable disk with -l.  If you have an existing
SD card to USB boot setup where this was not done, then your USB boot
likely has the SD card /boot partition mounted, the SD card is in use
and using rpi-clone for a clone back to the SD card slot will not work.


#### 6) Clone to smaller 4GB SD card
I happen to have an old 4GB SD card and here's a try to clone to it: 
```
root@rpi2: ~$ rpi-clone sda

Booted disk: mmcblk0 15.8GB                Destination disk: sda 4.0GB
---------------------------------------------------------------------------
Part      Size    FS     Label           Part   Size    FS     Label
1 /boot   58.4MB  fat16  --              1      58.4MB  fat16  --
2 root    15.8GB  ext4   SD-RPI-16N      2       3.9GB  ext4   --
---------------------------------------------------------------------------
== SYNC mmcblk0 file systems to sda ==
/boot       (22.5MB used)    : SYNC to sda1 (58.4MB size)
/           (5.9GB used)     : SYNC to sda2 (3.9GB size)
---------------------------------------------------------------------------
Run setup script       : no
Verbose mode           : no
-----------------------:
** FATAL **            : Partition 2: source used > destination space.
-----------------------:

Aborting!
  Use -F to override used > space fail.

```
So even if rpi-clone thinks that the sync won't work because of lack of
space, there is a -F option which will allow the clone to proceed
anyway.  The interesting thing about this case is that while this might
seem a bad idea, the sync will actually come close to succeeding.  That's
because the root used space includes a 1.8GB file system based
swap file (/var/swap) that will be excluded from the sync.  If this
clone is forced with -F, the card may boot, but there could be some missing
files if the rsync runs out of space and fails to complete and some things
would not work.
This is just a FYI.


#### 7) Creating a Pi3 bootable USB hard drive with extra partitions
I wanted to have a Pi3 hard drive USB boot with extra data partitions
and I want to be able to clone back to 2 partition SD cards for use
in other SD card booted Pis.  So when I initially clone to the hard drive
from my booted SD card I don't want the rpi-clone run to intialize the
hard drive with the SD card partition structure.
I connected my USB hard drive and it showed up as sdc.  I then
manually partitioned it with cfdisk so that it had the first two
partitions matching the partition types of the two booted SD card partitions
mmcblk0p1 and mmcblk0p2. Then I added additional partitions as I liked
and added a swap partition for possible later use since this was a
hard drive.
The requirement to make this work is getting the first two partitions
right, the sizes may be different, but the partition types have to match the
SD card and file systems must be made on the partitions.  If you forget
to make file systems, rpi-clone will fail to mount the partitions.
With the Raspbian on my SD card, the first two partition requirements are:
```
  Partition Type                   File System Type
  1: type c  W95 FAT32 (LBA)       mkfs -t vfat /dev/sdc1
  2: type 83 Linux                 mkfs.ext4 /dev/sdc2
```
Although the first partition file system could be mkfs -t vfat -F 32.
On the extra partitions I made ext4 file systems and ran mkswap on the
swap partition.
Now with the first two partitions set up as shown, I can run rpi-clone
on the disk and it will not try to initialize.  It will sync to the
first two partitions and my extra partitions 5 and 6 will not be touched.
My rpi-clone command was simply:
```
pi@rpi0: $ sudo ./rpi-clone sdc

Booted disk: mmcblk0 16.0GB                Destination disk: sdc 160.0GB
---------------------------------------------------------------------------
Part      Size    FS     Label           Part   Size    FS     Label
1 /boot   58.4MB  fat16  --              1     104.4MB  fat16  --
2 root    16.0GB  ext4   SD-RPI-s1       2      34.4GB  ext4   --
                                         3      10.7GB  swap   --
                                         4     114.8GB  EXT    --
                                         5      53.7GB  ext4   --
                                         6      61.1GB  ext4   --
---------------------------------------------------------------------------
== SYNC mmcblk0 file systems to sdc ==
/boot       (22.5MB used)    : SYNC to sdc1 (104.4MB size)
/           (6.0GB used)     : SYNC to sdc2 (34.4GB size)
---------------------------------------------------------------------------
Run setup script       : no
Verbose mode           : no
-----------------------:

Ok to proceed with the clone?  (yes/no): 
```
After running this command, I powered down the Pi, removed the SD card
and powered back on into a hard drive boot.  I had previously boot
enabled the Pi3.

## Cloning from a USB booted Pi with extra partitions
Now I have booted the USB hard drive I cloned to in example 7 and will
try a few clones.

#### 8) USB disk routine clone to 16GB SD card
For this case I haven't mounted any of the extra partitions and
the Pi has only the /boot partition mounted.  The kernel has seen my hard
drive as sdb but I'm using PARTUUID in fstab so there's no problem.
The card I want to clone to shows up as sda:
```
pi@rpi0: ~$ sudo  rpi-clone sda

Booted disk: sdb 160.0GB                   Destination disk: sda 16.0GB
---------------------------------------------------------------------------
Part      Size    FS     Label           Part   Size    FS     Label
1 /boot  104.4MB  fat16  --              1      58.4MB  fat16  --
2 root    34.4GB  ext4   --              2      16.0GB  ext4   SD-RPI-s4
3         10.7GB  swap   --                                      
4        114.8GB  EXT    --                                      
5         53.7GB  ext4   --                                      
6         61.1GB  ext4   --                                      
---------------------------------------------------------------------------
== SYNC sdb file systems to sda ==
/boot       (21.5MB used)    : SYNC to sda1 (58.4MB size)
/           (6.0GB used)     : SYNC to sda2 (16.0GB size)
---------------------------------------------------------------------------
Run setup script       : no
Verbose mode           : no
-----------------------:

Ok to proceed with the clone?  (yes/no): 
```

#### 9) USB disk with mounted partition 5 clone to 16GB SD card
Now I try the clone with one of my extra partitions mounted:
```
pi@rpi0: ~$ sudo  rpi-clone sda

Booted disk: sdb 160.0GB                   Destination disk: sda 16.0GB
---------------------------------------------------------------------------
Part         Size    FS     Label           Part   Size    FS     Label
1 /boot     104.4MB  fat16  --              1      58.4MB  fat16  --
2 root       34.4GB  ext4   --              2      16.0GB  ext4   SD-RPI-s4
3            10.7GB  swap   --                                      
4           114.8GB  EXT    --                                      
5 /mnt/mnt   53.7GB  ext4   --                                      
6            61.1GB  ext4   --                                      
---------------------------------------------------------------------------

To image the booted disk, the minimum destination disk size is 98.9GB
The destination disk is too small.

```
rpi-clone sees the mounted partition 5 and wants to clone it but finds
there's not enough space on the destination disk and won't let me.
A bigger disk is needed to clone all the way through partition 5.

#### 10) USB disk with mounted partition 5 clone to 16GB SD card try 2
I've got things I'm working on and don't want to unmount the partition
to make the clone work, so I use the -m option to tell rpi-clone to
only clone root and /boot and exclude any other directory mounts not given
with a -m option.  You don't need to specify "-m /" because root is
always included in a clone.  But you can give only one "-m /" option
and rpi-clone will clone only the root.
```
pi@rpi0: ~$ sudo  rpi-clone sda -m /boot

Booted disk: sdb 160.0GB                   Destination disk: sda 16.0GB
---------------------------------------------------------------------------
Part         Size    FS     Label           Part   Size    FS     Label
1 /boot     104.4MB  fat16  --              1      58.4MB  fat16  --
2 root       34.4GB  ext4   --              2      16.0GB  ext4   SD-RPI-s4
3            10.7GB  swap   --                                      
4           114.8GB  EXT    --                                      
5 /mnt/mnt   53.7GB  ext4   --                                      
6            61.1GB  ext4   --                                      
---------------------------------------------------------------------------
== SYNC sdb file systems to sda ==
/boot       (21.5MB used)    : SYNC to sda1 (58.4MB size)
/           (6.0GB used)     : SYNC to sda2 (16.0GB size)
---------------------------------------------------------------------------
Run setup script       : no
Verbose mode           : no
-----------------------:

Ok to proceed with the clone?  (yes/no): 

```
And the clone to the two partition SD card is a go.  But if my USB disk
root partition had used space greater than the size
of the destination partition, rpi-clone would detect that and refuse
to clone unless I were to give the -F option.

#### 11) USB disk clone to large USB disk
If you have an extra backup hard drive, you can clone to it and back up
all of your Pi hard drive partitions.  For this example I'm
plugging in a drive I happen to use for backing up my desktop,
so the partition types won't match and rpi-clone will want to do an
initialize.  The part to note is that rpi-clone will tell you the
steps it will take when doing an image clone of several partitions.
It will even make a swap partition on the destination if it is
an initialize clone. I'll also note that this example gives a clue
how rpi-clone would work if run on a Linux desktop.
```
pi@rpi0: ~$ sudo  rpi-clone sda            

Booted disk: sdb 160.0GB                   Destination disk: sda 320.1GB
---------------------------------------------------------------------------
Part         Size    FS     Label           Part   Size    FS    Label
1 /boot     104.4MB  fat16  --              1      52.4GB  ext4  --
2 root       34.4GB  ext4   --              2      52.4GB  ext4  gkrellm6-p2
3            10.7GB  swap   --              3      12.6GB  swap  --
4           114.8GB  EXT    --              4     202.6GB  EXT   --
5 /mnt/mnt   53.7GB  ext4   --              5     167.8GB  ext4  gkrellm6-p5
6            61.1GB  ext4   --              6      34.9GB  ext4  --
---------------------------------------------------------------------------
== Initialize: IMAGE sdb partition table to sda - FS types mismatch ==
1 /boot     (21.5MB used)    : IMAGE     to sda1  FSCK
2 root      (6.0GB used)     : MKFS SYNC to sda2
3                            : MKSWAP
4                            : 
5 /mnt/mnt  (54.3MB used)    : MKFS SYNC to sda5
6           (1.9GB used)     : RESIZE(221.2GB) MKFS SYNC to sda6
---------------------------------------------------------------------------
Run setup script       : no
Verbose mode           : no
-----------------------:
** WARNING **          : All destination disk sda data will be overwritten!
                       :   The partition structure will be imaged from sdb.
-----------------------:

Initialize and clone to the destination disk sda?  (yes/no): 

```
If I do this initialize clone then the next time I clone to the disk
it will be sync clone and will only want to sync whatever partitions
happen to be mounted.  But there is a "-a" option to rpi-clone that
will make it clone all partitions even if unmounted.

## Author
Bill Wilson
billw--at--gkrellm.net
