## rpi-clone

Version 2 is a complete rewrite with much improved capability over
the original.  See the examples below.

rpi-clone is a shell script that is for cloning a running
Raspberry Pi booted source disk (SD card or USB disk) to a destination
disk which will be bootable. Destination disks are SD cards in a
USB card reader, USB flash disks, or USB hard drives.

rpi-clone may work in SD card booted devices other than a
Raspberry Pi because when initializing a disk, rpi-clone images a
first /boot partition and boot loader setup can be captured.
But this will depend on how the boot loading is handled on each device.

I also am now using rpi-clone on my Debian desktop, but there are too many
variables in how a /etc/fstab can be set up and a desktop bootloader like
grub can be configured for this to be an officially  supported way of
using rpi-clone.

#### Clone by initialization
Source disk mounted partition file system types are compared to
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
See the examples below.  To get a usage screen showing available options,
run rpi-clone without any arguments:
```
pi@rpi0: $ sudo ./rpi-clone
No destination disk given.

usage: rpi-clone sdN {-v|--verbose} {-f|--force-initialize}
         {-u|--unattended} {-U|--Unattended}
         {-s|--setup} {-e|--edit-fstab name }
         {-m|--mountdir dir }
         {-a|--all-sync} {-F|--Force-sync} {-x} {-V|--version}

    -v      - list all files as they are copied.
    -f      - force initialize the destination disk by imaging the booted disk.
    -u      - unattended clone if not initializing.  No confirmations asked,
                but abort if disk needs initializing or on error.
    -U      - unattended even if initializing. No confirmations asked,
                but abort only on errors.
    -s host - add 'host' to args passed to script rpi-clone-setup and run it
                after cloning but before unmounting partitions. For setting
                clone disk hostname, but args can be what the script expects.
    -e sdX  - edit fstab to change booted device names to new device 'sdX'.
                Only for device names.  Don't use if fstab uses PARTUUID, etc.
    -m dir  - Add dir to a custom list of mounted directories to sync.  The
                root directory is always synced.  NA when initializing.
    -a      - Sync all partitions if types compatible, not just mounted ones.
    -F      - force file system sync even if errors.
                If source used > destination space error, do the sync anyway.
                If a source partition mount error, skip it and do other syncs.
    -x      - use set -x for very verbose bash shell script debugging
    -V      - print rpi-clone version.
```
+ If /etc/fstab uses device names:
	+ SD card to bootable USB flash or hard disk clones: use "-e sdX"
      to set up the destination fstab and cmdline.txt.
	+ USB disk to SD card slot (mmcblk0) clones: "-e mmcblk0p" is assumed.
+ rpi-clone version 1 briefly had a -s option that is replaced with a
  -s option that has different meaning.

## Raspberry Pi SD Card Booted Examples
#### First clone to a new SD card
The destination SD card is in a USB card reader which when plugged in to
my Pi shows up as sdb because I have another USB disk sda plugged in.
Look in /proc/partitions to see where yours is.  The SD card does not
have matching partition types, so the clone is an initialize where
the source partition structure is cloned to the destination.  Because
the destination is smaller, the last partition will be resized down.
When disks are initialized a label can be given for the
destination root file system.  I do that so I can keep track of
my cloned cards.  When you run rpi-clone, it tells you what it will do:
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

#### Subsequent clone to the same card
This is a pure sync clone because now the SD card has matching partition
and file system types.  Only modified files will be copied from the
source disk to the destination.  Also, now I want to setup the clone to
have another hostname to use on another Pi, so I give the -s option.
The rpi-clone-setup script will be called and it will edit /etc/hosts
and /etc/hostname.
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
...
```
#### Clone to manually partitioned hard drive
I wanted to have a Pi3 hard drive USB boot with extra data partitions
and I want to be able to clone back to 2 partition SD cards for use
in other SD card booted Pis.  So my USB connected hard drive, which
was showing up as sdc, was manually partitioned with partitions of
the appropriate types and file systems made with mkfs.

Raspbian on the Raspberry Pi needs for the first two partitions to be:
```
  Partition Type                   File System Type
  1: type c  W95 FAT32 (LBA)       mkfs -t vfat /dev/sdc1
  2: type 83 Linux                 mkfs.ext4 /dev/sdc2
```
Although the first partition file system could be mkfs -t vfat -F 32.
I made the extra partitions mkfs.ext4 and I made a swap partition for
possible later use (since this is a hard drive and not a flash drive).
Now when rpi-clone is run it will see that the destination disk has
matching types for the booted partitions 1 and 2, so it will do a
sync clone without trying to initialize the destination and my extra
partitions 5 and 6 will not be touched.  This will be the first clone
attempt to my manually partitioned disk.  The partition types match so
rpi-clone will go straight to a sync clone.

Notes:
+ When manually preparing partitions like this and you make partition types
match, don't forget that you must also make the matching file systems.
rpi-clone won't know if you've forgotten that until it tries to mount the
partitions.
+ What I say here applies generally, not just for manually partitioned
drives. The clone to create a bootable USB disk can work without
any additional steps beyond the rpi-clone run I show in
this example if you are on a Pi3 that uses PARTUUID in cmdline.txt and fstab
because rpi-clone automatically edits those.
But if you are using device names and are setting up to have a
system that SD card boots but uses a USB root, then you have to add an
argument to the rpi-clone run:
	+ Use the "-e sdX" option and rpi-clone will edit the destination
      /etc/fstab and /boot/cmdline.txt to reference sdX partition names
      instead of the SD card mmcblk0p partition names.
	+ Once you boot your system and are running with a USB root, then the
      SD card slot is available and you can put a SD card into it and clone
      the running USB disk back to it.  In that case you would
      run: "rpi-clone mmcblk0".  If you do this, rpi-clone assumes you want
      to make the SD card standalone bootable and assumes "-e mmcblk0p"
      and you don't have to explicitly add the argument.
	+ But rpi-clone will not edit the currently booted SD card cmdline.txt.
      You must do that yourself.

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

## Raspberry Pi USB Hard Drive Booted Examples
Now I have booted the USB hard drive I cloned to in the example just
above.  I'm going to show several examples here because things get
interesting with rpi-clone's flexibility.

#### Routine USB disk clone to 16GB SD card
For this case the Pi is booted and only the /boot partition is mounted.
Nothing much to see here, I'll just type "yes" and only the /boot and
root partitions will be synced.
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

#### USB disk with mounted partition 5 clone to 16GB SD card
Now I have one of my extra partitions mounted and happen to want to
clone to a SD card for another Pi.  So here's what I get:
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
there's not enough space on the destination drive and won't let me.
A bigger disk is needed to clone all the way through partition 5.

#### USB disk with mounted partition 5 clone to 16GB SD card try 2
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

#### USB disk clone to 4GB SD card
I happen to have an old 4GB SD card and here's a try to clone to it: 
```
pi@rpi0: ~$ sudo  rpi-clone sda -m /boot

Booted disk: sdb 160.0GB                   Destination disk: sda 4.0GB
---------------------------------------------------------------------------
Part         Size    FS     Label           Part   Size    FS     Label
1 /boot     104.4MB  fat16  --              1      58.4MB  fat16  --
2 root       34.4GB  ext4   --              2       3.9GB  ext4   --
3            10.7GB  swap   --                                      
4           114.8GB  EXT    --                                      
5 /mnt/mnt   53.7GB  ext4   --                                      
6            61.1GB  ext4   --                                      
---------------------------------------------------------------------------
== SYNC sdb file systems to sda ==
/boot       (21.5MB used)    : SYNC to sda1 (58.4MB size)
/           (6.0GB used)     : SYNC to sda2 (3.9GB size)
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
anyway.  Maybe not a good idea, but the interesting thing about
this case is that the sync will actually succeed.  That's
because the root used space includes an almost 2GB file system based
swap file (/var/swap) that will be excluded from the sync.  I haven't
yet switched to using the hard disk swap partition.
This is just a FYI.

#### USB disk clone to large USB disk
If you have an extra backup hard drive, you can clone to it and back up
all of your Pi hard drive partitions.  For this example I'm
plugging in a drive I happen to use for backing up my desktop,
so the partition types won't match and rpi-clone will want to do an
initialize.  The part to note is that rpi-clone will tell you the
steps it will take when doing an image clone of several partitions.
It will even make a swap partition on the destination. So, I'll also
note that this example gives a clue if you want to try using rpi-clone
on a desktop.
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
