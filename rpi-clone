#!/bin/bash

# rpi-clone is Copyright (c) 2018-2019 Bill Wilson
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted under the conditions of the BSD LICENSE file at
# the rpi-clone github source repository:
#    https://github.com/billw2/rpi-clone


version=2.0.22

# setup trusted paths for dependancies (like rsync, grub, fdisk, etc)
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# auto run grub-install if grub detected
grub_auto=1

PGM=`basename $0`
setup_command="$PGM-setup"

rsync_options="--force -rltWDEHXAgoptx"

if [ `id -u` != 0 ]
then
    echo -e "$PGM needs to be run as root.\n"
    exit 1
fi

raspbian=0
raspbian_buster=0
if [ -f /etc/os-release ]
then
	pretty=`cat /etc/os-release | grep PRETTY`
	if [[ "$pretty" == *"Raspbian"* ]]
	then
		raspbian=1
	fi
	if ((raspbian)) && [[ "$pretty" == *"buster"* ]]
	then
		raspbian_buster=1
	fi
fi

confirm()
	{
	if ((unattended || (initialize && Unattended) ))
	then
		return 0
	fi
	printf "\n%s  (yes/no): " "$1"
	read resp
	if [ "$resp" = "y" ] || [ "$resp" = "yes" ]
	then
		return 0
	fi
	if [ "$2" == "abort" ]
	then
		echo -e "Aborting!\n"
		exit 0
	fi
	return 1
	}

# sfdisk is in fdisk package
commands="rsync parted fdisk findmnt column fsck.vfat"
packages="rsync parted util-linux mount bsdmainutils dosfstools"
need_packages=""

idx=1
for cmd in $commands
do
	if ! command -v $cmd > /dev/null
	then
		pkg=$(echo "$packages" | cut -d " " -f $idx)
		printf "%-30s %s\n" "Command not found: $cmd" "Package required: $pkg"
		need_packages="$need_packages $pkg"
	fi
	((++idx))
done

if [ "$need_packages" != "" ]
then
	confirm "Do you want to apt-get install the packages?" "abort"
	apt-get install -y --no-install-recommends $need_packages
fi

clone=/mnt/clone
clone_src=/mnt/clone-src
clone_log=/var/log/$PGM.log

HOSTNAME=`hostname`


usage()
	{
	echo $"
usage: $PGM sdN {-v|--verbose} {-f|--force-initialize} {-f2}
         {-p|--p1-size size} {-u|--unattended} {-U|--Unattended} {-q|--quiet}
         {-s|--setup host} {-e|--edit-fstab sdX } {-m|--mountdir dir }
         {-L|--label-partitions label} {-l|--leave-sd-usb-boot}
         {-a|--all-sync} {-F|--Force-sync} {-x} {-V|--version}
         {--convert-fstab-to-partuuid}
         {--exclude=PATTERN} {--exclude-from=FILE}

    -v	    - verbose rsync, list all files as they are copied.
    -f	    - force initialize the destination disk by imaging the booted disk
                partition structure.  File systems are then synced or imaged.
    -f2	    - force initialize only the first 2 partitions to the destination.
                So a multi partition USB boot can initialize clone back to
                a 2 partition SD card.
    -p size - resize destination partition 1 to 'size' bytes. For two partition
                initialize (when first clone to blank disk or using -f2 or -f).
                Use 'sizeM' for MiB size units. eg -p 256M equals -p 268435456
    -u	    - unattended clone if not initializing.  No confirmations asked,
                but abort if disk needs initializing or on error.
    -U      - unattended even if initializing. No confirmations asked,
                but abort only on errors.
    -q      - quiet mode, no output unless errors or initializing. Implies -u.
    -s host - add 'host' to args passed to script rpi-clone-setup and run it
                after cloning but before unmounting partitions. For setting
                clone disk hostname, but args can be what the script expects.
                You can give multiple '-s arg' options.
    -e sdX  - edit destination fstab to change booted device names to new
      	        device 'sdX'.  This is Only for fstabs that use device names.
                Used for setting up a USB bootable disk.
    -m dir  - Add dir to a custom list of mounted directories to sync.  Then
                the custom list will be synced instead of the default of all
                mounted directories.  The root directory is always synced.
                Not for when initializing.
    -L lbl  - label for ext type partitions.  If 'lbl' ends with '#', replace
                '#' with a partition number and label all ext partitions.
                Otherwise, apply label to root partition only.
    -l      - leave SD card to USB boot alone when cloning to SD card mmcblk0
                from a USB boot.  This preserves a SD card to USB boot setup
                by leaving the SD card cmdline.txt using the USB root.	When
                cloning to USB from SD card this option sets up the SD card
                cmdline.txt to boot to the USB disk.
    -a      - Sync all partitions if types compatible, not just mounted ones.
    -F      - force file system sync or image for some errors. eg:
                If source used > destination space error, do the sync anyway.
                If a source partition mount error, skip it and do other syncs.
    -x      - use set -x for very verbose bash shell script debugging
    -V      - print rpi-clone version.

  Clone a booted file system to a destination disk which is bootable.

  The destination disk is a SD card (USB card reader) or USB disk 'sdN' plugged
  into a USB port.  The 'sdN' name should be a full disk name like sda and not
  a partition name like sda1.  $PGM works on a Raspberry Pi and can work on
  other systems.  For a destination disk that shows up as sda, run:

    $ sudo rpi-clone sda

  Clones can be from a booted SD card or USB disk.  For a description, example
  clone runs and example usage of above options, see the README.md at:

      https://github.com/billw2/rpi-clone

  A line logging a $PGM run is written to $clone_log.

  Download:
    git clone https://github.com/billw2/rpi-clone
"
	exit 1
	}

readable_MiB()
	{
	val=$1
	if [ "$val" == "" ]
	then
		result="   ??"
	else
		blk_size=$2
		val=$((val / 1024 * blk_size))

		if ((val < 1024 * 1024))
		then
			result=$(echo $val \
			| awk '{ byte =$1 /1024; printf "%.1f%s", byte, "M" }')
		elif ((val < 1024 * 1024 * 1024))
		then
			result=$(echo $val \
			| awk '{ byte =$1 /1024/1024; printf "%.1f%s", byte, "G" }')
		else
			result=$(echo $val \
			| awk '{ byte =$1 /1024/1024/1024; printf "%.1f%s", byte, "T" }')
		fi
	fi
	printf -v "${3}" "%s" "$result"
	}

readable_MB()
	{
	val=$1
	if [ "$val" == "" ]
	then
		result="   ??"
	else
		blk_size=$2
		val=$((val / 1000 * blk_size))

		if ((val < 1000 * 1000))
		then
			result=$(echo $val \
			| awk '{ byte =$1 /1000; printf "%.1f%s", byte, "MB" }')
		elif ((val < 1000 * 1000 * 1000))
		then
			result=$(echo $val \
			| awk '{ byte =$1 /1000/1000; printf "%.1f%s", byte, "GB" }')
		else
			result=$(echo $val \
			| awk '{ byte =$1 /1000/1000/1000; printf "%.1f%s", byte, "TB" }')
		fi
	fi
	printf -v "${3}" "%s" "$result"
	}

qecho()
	{
    if ((!quiet))
	then
    	echo "$@"
    fi
	}
	
qprintf()
	{
    if ((!quiet))
	then
    	printf "$@"
    fi
	}

unmount_or_abort()
	{
	if [ "$1" == "" ]
	then
		return
	fi
	qprintf "\n  $2\n  The clone cannot proceed unless it is unmounted."

	if confirm "Do you want to unmount $1?" "abort"
	then
		if ! umount $1
		then
			echo "$PGM could not unmount $1."
			echo -e "Aborting!\n"
			exit 0
		fi
	fi
	}

unmount_list()
	{
	if [ "$1" == "" ]
	then
		return
	fi
	for dir in $1
	do
		qecho "  unmounting $dir"
		if ! umount $dir
		then
			qecho "  Failed to unmount: $dir"
		fi
	done
	}

mount_partition()
	{
	qecho "  Mounting $1 on $2"

	if ! mount $1 $2
	then
		echo "    Mount failure of $1 on $2."
		if [ "$3" != "" ]
		then
			unmount_list $3
		fi
		echo "Aborting!"
		exit 1
	fi
	}

rsync_file_system()
	{
	src_dir="$1"
	dst_dir="$2"

	qprintf "  => rsync $1 $2 $3 ..."

	if [ "$3" == "with-root-excludes" ]
	then
		rsync $rsync_options --delete \
			$exclude_useropt \
			$exclude_swapfile \
			--exclude '.gvfs' \
			--exclude '/dev/*' \
			--exclude '/mnt/clone/*' \
			--exclude '/proc/*' \
			--exclude '/run/*' \
			--exclude '/sys/*' \
			--exclude '/tmp/*' \
			--exclude 'lost\+found/*' \
		$src_dir \
		$dst_dir
	else
		rsync $rsync_options --delete \
			$exclude_useropt \
			--exclude '.gvfs' \
			--exclude 'lost\+found/*' \
		$src_dir \
		$dst_dir
	fi
	qecho ""
	}

print_partitions()
	{
	if ((quiet)) && ((!initialize))
	then
		return
	fi
	n_parts=$(( (n_src_parts >= n_dst_parts) ? n_src_parts : n_dst_parts ))

	readable_MB $src_disk_size "512" src_size_readable
	readable_MB $dst_disk_size "512" dst_size_readable

	printf "\n%-43s%s" "Booted disk: $src_disk $src_size_readable" \
				"Destination disk: $dst_disk $dst_size_readable"
	echo $"
---------------------------------------------------------------------------"
	out=$'Part, Size,FS,Label         ,Part, Size,FS,Label\n'
	for ((p = 1; p <= n_parts; p++))
	do
		if ((p <= n_src_parts && src_exists[p]))
		then
			readable_MiB ${src_size_sectors[p]} "512" tmp
			printf -v sectors_readable "%7s" $tmp
			pname="$p ${src_name[p]}"
			out=${out}$"$pname,$sectors_readable,${src_fs_type[p]},${src_label[p]},"
		else
			out=${out}$"  ,  ,  ,  ,"
		fi

		if ((p <= n_dst_parts && dst_exists[p]))
		then
			readable_MiB ${dst_size_sectors[p]} "512" tmp
			printf -v sectors_readable "%7s" $tmp
			out=${out}$"$p,$sectors_readable,${dst_fs_type[p]},${dst_label[p]},"
		else
			out=${out}$"  ,  ,  ,  ,"
		fi
		out=${out}$'\n'
	done

	echo $"$out" | column -t -s ','

	if ((alt_root_part_num > 0))
	then
		echo $"
** Assuming destination root partition for the clone is $dst_part_base$root_part_num
   The root FS mount is not from booted $src_disk.  It is ${src_root_dev#/dev/}"

	fi
	echo $"---------------------------------------------------------------------------"
	}

print_sync_actions()
	{
	if ((quiet))
	then
		return
	fi
	for ((p = 1; p <= n_src_parts; p++))
	do
		if ((!src_exists[p]))
		then
			continue
		fi
		if ((p == root_part_num && alt_root_part_num > 0))
		then
			part=${src_root_dev#/dev/}
			flow="$part to $dst_part_base$p"
		else
			flow="to $dst_part_base$p"
		fi
		if ((src_sync_part[p]))
		then
			if [ "${src_mounted_dir[p]}" != "" ]
			then
				src_label="${src_mounted_dir[p]}"
				action_label="SYNC"
			else
				src_label="/dev/${src_partition[p]}"
				action_label="MOUNT SYNC"
			fi
			readable_MiB ${src_used_sectors[p]} "512" used
			readable_MiB ${dst_size_sectors[p]} "512" size
			printf "%-22s%-14s : %s %s\n" \
					"$src_label" "(${used} used)" "$action_label" \
					"$flow (${size} size)"
		fi
	done
	}

print_image_actions()
	{
	for ((p = 1; p <= n_src_parts; p++))
	do
		if ((!src_exists[p]))
		then
			continue
		fi
		pname="$p ${src_name[p]}"
		fs_type=${src_fs_type[$p]}

		if ((p == root_part_num && alt_root_part_num > 0))
		then
			part=${src_root_dev#/dev/}
			flow="$part to $dst_part_base$p"
		else
			flow="to $dst_part_base$p"
		fi

		action=""
		if ((p <= n_image_parts))
		then
			if ((p == 1))
			then
				if ((p1_size_new > 0))
				then
					action="RESIZE  MKFS  SYNC $flow"
				else
					action="MKFS  SYNC $flow"
				fi
			elif [ "$fs_type" == "swap" ]
			then
				action="MKSWAP"
			elif ((p != ext_part_num))
			then
				if [ "${src_mounted_dir[p]}" != "" ] || ((p == n_src_parts))
				then
					if ((p < n_src_parts || last_part_space || force_sync))
					then
						action="MKFS  SYNC $flow"
					else
						action="MKFS  **NO SYNC**"
					fi
				else
					action="IMAGE $flow"
				fi
			fi
		fi

		if ((p == n_image_parts))
		then
			readable_MiB ${src_used_sectors[n_image_parts]} "512" used
			printf "%-22s%-14s : RESIZE  %s\n" \
						"$pname" "(${used} used)" "$action"
		elif ((src_used_sectors[$p] > 0 && p < n_image_parts))
		then
			readable_MiB ${src_used_sectors[p]} "512" used
			printf "%-22s%-14s : $action\n" "$pname" "(${used} used)"
		elif [ "$action" != "" ]
		then
			printf "%-36s : $action\n" "$pname"
		fi
	done
	}

print_options()
	{
	if ((quiet))
	then
		return
	fi
	echo $"---------------------------------------------------------------------------"

	if ((force_sync))
	then
		printf "%-22s : %s\n" "-F" \
				"forcing clone to skip some errors."
	fi

	if ((force_2_parts))
	then
		printf "%-22s : %s\n" "-f2" \
				"force initialize to first two partitions only."
	fi

	if ((p1_size_new > 0))
	then
		printf "%-3s%-19s : %s %s %s\n" "-p " "$p1_size_arg" \
				"resize /boot to" "$p1_size_new" "blocks of 512 Bytes."
	fi

	if [ "$edit_fstab_name" != "" ]
	then
		printf "%-22s : %s\n" "-e clone fstab edit" \
				"edit $src_part_base device entries to $edit_fstab_name."
	fi

	if [ "$ext_label" != "" ]
	then
		rep="${ext_label: -1}"
		if [ "$rep" == "#" ]
		then
			msg="all ext partition types"
		else
			msg="root partition only"
		fi
		printf "%-22s : %s\n" "-L $ext_label" \
				"volume label for $msg."
	fi

	if ((leave_sd_usb_boot))
	then
		if ((SD_slot_dst))
		then
			msg="leave SD card cmdline.txt bootable to USB."
		elif ((SD_slot_boot))
		then
			msg="install boot to USB cmdline.txt on SD card."
		else
			msg="-l ignored.  Src or dst is not a SD card slot."
		fi
		printf "%-22s : %s\n" "-l SD to USB boot mode" "$msg"
	fi

	if [ "$setup_args" != "" ]
	then
		printf "%-22s : %s\n" "Run setup script" "$setup_command $setup_args"
	else
		printf "%-22s : no.\n" "Run setup script"
	fi

	if ((have_grub))
	then
		printf "%-22s : %s\n" "Run grub" \
			"grub-install --root-directory=$clone /dev/$dst_disk"
	fi
	printf "%-22s : %s.\n" "Verbose mode" "$verbose"
	printf "%-23s:\n" "-----------------------"
	}

ext_label()
	{
	pnum=$1
	fs_type=$2
	flag=$3
	label_arg=""

	if [ "$ext_label" != "" ] && [[ "$fs_type" == *"ext"* ]]
	then
		rep="${ext_label: -1}"
		if [ "$rep" == "#" ]
		then
			label_arg=${ext_label:: -1}
			label_arg="$flag $label_arg$pnum"
		elif ((pnum == root_part_num))
		then
			label_arg="$flag $ext_label"
		fi
	fi
	printf -v "${4}" "%s" "$label_arg"
	}

get_src_disk()
	{
	partition=${1#/dev/}
	disk=${partition:: -1}
	num="${partition: -1}"
	if [[ $disk == *"mmcblk"* ]]
	then
		SD_slot_boot=1
		disk=${disk:0:7}
		src_part_base=${disk}p
	fi
	printf -v "${2}" "%s" "$disk"
	printf -v "${3}" "%s" "$num"
	}


# ==== source (booted) disk info and default mount list
#
src_boot_dev=`findmnt /boot -o source -n | grep "/dev/"`
src_root_dev=`findmnt / -o source -n | grep "/dev/"`
SD_slot_boot=0
SD_slot_dst=0
src_part_base=""

boot_part_num=0
alt_root_part_num=0


if [ "$src_boot_dev" == "" ]
then
	get_src_disk "$src_root_dev" "src_disk" "unused"
else
	get_src_disk "$src_boot_dev" "src_disk" "boot_part_num"
fi

get_src_disk "$src_root_dev" "src_root_disk" "root_part_num"

if [ "$src_disk" == "" ]
then
	echo "Cannot find booted device."
	exit 1
fi

if [ "$src_part_base" == "" ]
then
	src_part_base=$src_disk
fi

if [ "$src_disk" != "$src_root_disk" ]
then
	if ((SD_slot_boot))
	then
		# Handle SD card boots with root on different USB disk device.
		# But will assume SD card has a root partition just above its root.
		#
		alt_root_part_num="$root_part_num"
		root_part_num=$((boot_part_num + 1))
	else
		echo $"
Boot and root are on different disks and it's not a SD card boot.
Don't know how to partition the destination disk!"
		exit 1
	fi
fi

# src_root_dev, if on device other than booted, is not in src_partition_table
# and src_fdisk_table, but is in src_df_table and src_mount_table
#
src_partition_table=$(parted -m "/dev/$src_disk" unit s print | tr -d ';')
src_fdisk_table=$(fdisk -l /dev/$src_disk | grep "^/dev/")

tmp=$(df | grep -e "^/dev/$src_disk" -e "^/dev/root" -e "$src_root_dev" \
			| tr -s " ")
dev=${src_root_dev#/dev/}
src_df_table=$(echo "$tmp" | sed "s/root/$dev/")

n_src_parts=$(echo "$src_partition_table" | tail -n 1 | cut -d ":" -f 1)
src_disk_size=$(echo "$src_partition_table" \
				| grep "^/dev/$src_disk" | cut -d ":" -f 2 | tr -d 's')

line=$(fdisk -l /dev/$src_disk | grep "Disk identifier:")
src_disk_ID=${line#*x}

src_mount_table=$(findmnt -o source,target -n -l \
				| grep -e "^/dev/$src_disk" -e "^$src_root_dev" | tr -s " ")
n_mounts=$(echo "$src_mount_table" | wc -l)

if ((alt_root_part_num > 0 && n_src_parts < 2))
then
	echo $"
Booted disk has only one partition and the root is from another device.
Don't know how to partition the destination disk!
"
	exit 1
fi


line=$(echo "$src_fdisk_table" | grep "Extended")
if [ "$line" != "" ]
then
	dev=$(echo "$line" | cut -d " " -f 1)
	ext_part_num="${dev: -1}"
else
	ext_part_num=0
fi


for ((p = 1; p <= n_src_parts; p++))
do
	line=$(echo "$src_partition_table" | grep -e "^${p}:")
	if [ "$line" == "" ]
	then
		src_exists[p]=0
		continue
	fi
	src_exists[p]=1

	if ((p == root_part_num))
	then
		src_partition[p]=${src_root_dev#/dev/}
		src_device[p]=$src_root_dev
	else
		src_partition[p]="${src_part_base}${p}"
		src_device[p]="/dev/${src_partition[p]}"
	fi

	# parted sectors are 512 bytes
	src_start_sector[p]=$(echo "$line" | cut -d ":" -f 2 | tr -d 's')
	src_size_sectors[p]=$(echo "$line" | cut -d ":" -f 4 | tr -d 's')

	part_type=$(echo "$line" | cut -d ":" -f 5)

	src_mounted_dir[p]=$(echo "$src_mount_table" \
						| grep -m 1 -e "^${src_device[p]}" | cut -d " " -f 2)
	if [ "${src_mounted_dir[p]}" != "" ]
	then
		src_sync_part[p]=1
	else
		src_sync_part[p]=0
	fi

	src_name[p]=""
	if [ "$part_type" != "" ]
	then
		src_fs_type[p]="$part_type"
	else
		src_fs_type[p]="--"
	fi
	src_label[p]="--"

	if [ "${src_mounted_dir[p]}" == "/" ]
	then
		src_name[p]="root"
	#
	# If root on device other than booted SD card, root_part_num assumed to be
	# booted /boot part_num + 1 and alt_root_part_num  is from root device.
	#
	elif ((p == root_part_num)) && ((alt_root_part_num > 0))
	then
		src_name[p]="root**"
	elif ((p == ext_part_num))
	then
		src_fs_type[p]="EXT"
	elif [[ "$part_type" == *"linux-swap"* ]]
	then
		src_fs_type[p]="swap"
	elif [ "${src_mounted_dir[p]}" != "" ]
	then
		src_name[p]="${src_mounted_dir[p]}"
	fi

	if [[ "$part_type" == *"ext"* ]]
	then
		label=`e2label ${src_device[p]} 2> /dev/null`
		if [ "$label" != "" ]
		then
			src_label[p]="$label"
		fi
	fi
done


# command line
#
setup_args=""
edit_fstab_name=""
ext_label=""
verbose="no"

force_initialize=0
force_2_parts=0
force_sync=0
all_sync=0
usage_error=0
unattended=0
Unattended=0
quiet=0
custom_sync=0
leave_sd_usb_boot=0
convert_to_partuuid=0
p1_size_new=0

while [ "$1" ]
do
	case "$1" in
		-v|--verbose)
			verbose="yes"
			rsync_options=${rsync_options}v
			;;
		-u|--unattended)
			unattended=1
			;;
		-U|--Unattended-init)
			unattended=1
			Unattended=1
			;;
		-q|--quiet)
			unattended=1
			quiet=1
			rsync_options=${rsync_options}q
			;;
		--exclude=*|--exclude-from=*)
			exclude_useropt="${exclude_useropt} $1"
			;;
		-s|--setup)
			shift
			if ! command -v $setup_command > /dev/null
			then
				echo "Cannot find script $setup_command for setup arg \"$1\"."
				usage_error=1
			fi
			if [ "$setup_args" == "" ]
			then
				setup_args="$1"
			else
				setup_args="$setup_args $1"
			fi
			;;
		-e|--edit-fstab)
			shift
			edit_fstab_name=$1
			;;
		-f|--force-initialize)
			force_initialize=1
			;;
		-f2)
			force_initialize=1
			force_2_parts=1
			;;
		-p|--p1-size)
			shift
			p1_size_arg=$1
			p1_size_new=$1
			if [[ $p1_size_arg =~ ^[0-9MG]+$ ]]
			then
				if [[ $p1_size_new == *"M" ]]
				then
					size=$(echo $p1_size_new | cut -d M -f 1)
					p1_size_new=$(($size * 1024 * 1024 / 512))
				elif [[ $p1_size_new == *"G" ]]
				then
					size=$(echo $p1_size_new | cut -d G -f 1)
					p1_size_new=$(($size * 1024 * 1024 * 1024 / 512))
				fi

				if [[ $p1_size_new =~ ^[0-9]+$ ]]
				then
					if ((!force_sync && p1_size_new < 200 * 1024))
					then
						echo "Setting /boot partition size less than 100 MB seems wrong so will not try."
						echo "    Use -F before -p to override."
						exit 1
					fi
				else
					echo "Confused by -p $p1_size_arg."
					exit 1
				fi
			else
				echo "Invalid character in -p size.  Use digits + M or G like: -p 256M"
				exit 1
			fi
			;;
		-x)
			set -x
			;;
		-a|--all-sync)
			all_sync=1
			;;
		-m|--mountdir)
			shift
			mount_ok=0
			for ((p = 1; p <= n_src_parts; p++))
			do
				if ((!src_exists[p]))
				then
					continue
				fi
				if ((!custom_sync)) && ((p != root_part_num))
				then
					src_sync_part[p]=0
				fi
				if [ "${src_mounted_dir[p]}" == "$1" ]
				then
					src_sync_part[p]=1
					mount_ok=1
				fi
			done
			if ((!mount_ok))
			then
				echo "Asking to clone directory \"$1\", but it is not mounted."
				usage_error=1
			fi
			custom_sync=1
			;;
		-L|--label_partitions)
			shift
			ext_label=$1
			;;
		-l|--leave-sd-usb-boot)
			leave_sd_usb_boot=1
			;;
		-F|--Force-sync)
			force_sync=1
			;;
		--convert-fstab-to-partuuid)
			convert_to_partuuid=1
			;;
		-V|--version)
			echo $PGM Version: $version
			exit 0
			;;
		-h|--help)
			usage
			;;
		*)
			if [ "$dst_disk" != "" ]
			then
				echo "Bad arg: $1"
				echo "Run $PGM with -h or no args for usage."
				exit 1
			fi
			dst_disk=$1
			dir=`expr substr $dst_disk 1 5`
			if [ "$dir" == "/dev/" ]
			then
				dst_disk=${dst_disk#/dev/}
			fi
			;;
	esac
	shift
done

if ((custom_sync)) && ((all_sync))
then
	echo "-m and -a options at the same time conflict."
	exit 1
fi
if ((custom_sync)) && ((force_initialize))
then
	echo "-m and -f options at the same time conflict."
	exit 1
fi
if [[ "$verbose" == "yes" ]] && ((quiet))
then
	echo "-q and -v options at the same time conflict."
	exit 1
fi

if ((usage_error))
then
	echo ""
    exit 1
fi

if ((convert_to_partuuid))
then
	unattended=0
	Unattended=0

	fstab=/etc/fstab
	fstab_tmp=/tmp/fstab
	fstab_save=${fstab}.${PGM}-save
	confirm "This will change your $fstab, are you sure?" "abort"

	cp $fstab $fstab_tmp
	printf "\nConverting $fstab from device names to PARTUUID\n"
	count=0
	for ((p = 1; p <= n_src_parts; p++))
	do
		if grep -q "^/dev/${src_partition[p]}" $fstab_tmp
		then
			partuuid=$(lsblk -n -o PARTUUID /dev/${src_partition[p]})
			sed -i "s/\/dev\/${src_partition[p]}/PARTUUID=$partuuid/" $fstab_tmp
			printf "  Editing $fstab, changing /dev/${src_partition[p]} to $partuuid\n"
			((++count))
		fi
	done
	if ((count))
	then
		cp $fstab $fstab_save
		cp $fstab_tmp $fstab
		printf "Your original fstab is backed up to $fstab_save\n"

		cmdline_txt=/boot/cmdline.txt
		cmdline_save=$cmdline_txt.${PGM}-save
		if [ -f $cmdline_txt ] && grep -q "$src_root_dev" $cmdline_txt
		then
			root_part=${src_partition[root_part_num]}
			partuuid=$(lsblk -n -o PARTUUID $src_root_dev)
			if [ "$partuuid" != "" ]
			then
				cp $cmdline_txt $cmdline_save
				sed -i "s/\/dev\/$root_part/PARTUUID=$partuuid/" $cmdline_txt
				printf "  Editing $cmdline_txt, changing root=$src_root_dev to root=PARTUUID=$partuuid\n"
				printf "Your original cmdline.txt is backed up to $cmdline_save\n"
			fi
		fi
	else
		printf "Could not find any $src_disk partition names in $fstab, nothing changed.\n"
	fi
	rm $fstab_tmp
	echo ""
	exit 0
fi

# dst_mount_flag enumerations:
live=1
temp=2
fail=3

for ((p = 1; p <= n_src_parts; p++))
do
	if ((!src_exists[p]))
	then
		continue
	fi
	blocks=0
	dst_mount_flag[p]=0

	if [ "${src_mounted_dir[p]}" != "" ]
	then		# df blocks are 1024 bytes
		dst_mount_flag[p]=$live
		blocks=$(echo "$src_df_table" \
					| grep -m 1 "^${src_device[p]}" | cut -d " " -f 3)
	# in case intializing, get n_src_parts to compare to dest space
	elif   ((p == n_src_parts)) \
	    || ((all_sync)) \
		&& [ "${src_fs_type[p]}" != "EXT" ] \
		&& [ "${src_fs_type[p]}" != "swap" ] \
		&& [ "${src_fs_type[p]}" != "" ]
	then
		if mount ${src_device[p]} $clone
		then
			sleep 1
			blocks=$(df | grep "^${src_device[p]}" \
						| tr -s " " | cut -d " " -f 3)
			umount $clone
			dst_mount_flag[p]=$temp
			if ((all_sync))
			then
				src_sync_part[p]=1
			fi
		else
			dst_mount_flag[p]=$fail
		fi
	fi
	src_used_sectors[p]=$((blocks * 2))
done

# ==== destination disk checks
#
if [ "$dst_disk" = "" ]
then
	echo "No destination disk given."
	usage
fi

chk_disk=`cat /proc/partitions | grep -m 1 $dst_disk`

if [ "$chk_disk" == "" ]
then
	echo $"
  Cannot find '$dst_disk' in the partition table.  The partition table is:"
	cat /proc/partitions
	exit 1
fi

dst_part_base=$dst_disk

if [[ ${chk_disk: -1} =~ ^[0-9]$ ]]
then
	if [[ $dst_disk == *"mmcblk"* ]]
	then
		SD_slot_dst=1
		dst_part_base=${dst_disk}p
		if    [ "$edit_fstab_name" == "" ] \
		   && ! grep -q "^PARTUUID=" /etc/fstab
		then
			edit_fstab_name=$dst_part_base
			assumed_fstab_edit=1
		else
			assumed_fstab_edit=0
		fi
	else
		qecho $"
  Target disk $dst_disk ends with a digit so may be a partition.
  $PGM requires disk names like 'sda' and not partition names like 'sda1'."

		confirm "Continue anyway?" "abort"
	fi
fi

if [ "$src_disk" == "$dst_disk" ]
then
	echo "Destination disk $dst_disk is the booted disk.  Cannot clone!"
	exit 1
fi

dst_partition_table=$(parted -m "/dev/$dst_disk" unit s print | tr -d ';')
n_dst_parts=$(echo "$dst_partition_table" | tail -n 1 | cut -d ":" -f 1)
if [ "$n_dst_parts" == "/dev/$dst_disk" ]
then
	n_dst_parts=0
fi

dst_disk_size=$(echo "$dst_partition_table" \
				| grep "^/dev/$dst_disk" | cut -d ":" -f 2 | tr -d 's')
dst_root_dev=/dev/${dst_part_base}${root_part_num}

dst_mount_table=$(findmnt -o source,target -n -l \
				| grep "^/dev/$dst_disk" | tr -s " ")

dst_fdisk_table=$(fdisk -l /dev/$dst_disk | grep "^/dev/")
line=$(echo "$dst_fdisk_table" | grep "Extended")
if [ "$line" != "" ]
then
	dev=$(echo "$line" | cut -d " " -f 1)
	ext_num="${dev: -1}"
else
	ext_num=0
fi

for ((p = 1; p <= n_dst_parts; p++))
do
	line=$(echo "$dst_partition_table" | grep -e "^${p}:")
	if [ "$line" == "" ]
	then
		dst_exists[p]=0
		continue
	fi
	dst_exists[p]=1

	part="${dst_part_base}${p}"
	dst_partition[p]="$part"
	dst_device[p]="/dev/$part"

	dst_start_sector[p]=$(echo "$line" | cut -d ":" -f 2 | tr -d 's')
	dst_size_sectors[p]=$(echo "$line" | cut -d ":" -f 4 | tr -d 's')

	part_type=$(echo "$line" | cut -d ":" -f 5)
	if [ "$part_type" != "" ]
	then
		dst_fs_type[p]="$part_type"
	else
		dst_fs_type[p]="--"
	fi
	dst_label[p]="--"

	if [[ "$part_type" == *"linux-swap"* ]]
	then
		dst_fs_type[p]="swap"
	elif [[ "$part_type" == *"ext"* ]]
	then
		label=`e2label ${dst_device[p]} 2> /dev/null`
		if [ "$label" != "" ]
		then
			dst_label[p]="$label"
		fi
	elif ((p == ext_num))
	then
		dst_fs_type[p]="EXT"
	fi
done

fs_match=1
root_part_match=0
first_part_mismatch=0

initialize=$((force_initialize))

for ((p = 1; p <= n_src_parts; p++))
do
	if ((!src_exists[p]))
	then
		continue
	fi
	stype=${src_fs_type[p]}
	dtype=${dst_fs_type[p]}
	if [ "$stype" != "$dtype" ]
	then
		tmp_match=0
		if [[ "$stype" == *"fat"* ]] && [[ "$dtype" == *"fat"* ]]
		then
			tmp_match=1
		elif [[ "$stype" == *"ext"* ]] && [[ "$dtype" == *"ext"* ]]
		then
			tmp_match=1
		fi
		if ((tmp_match && p == root_part_num))
		then
			root_part_match=1
		fi
		if ((!tmp_match)) && ((src_sync_part[p]))
		then
			first_part_mismatch=$p
			fs_match=0
			break
		fi
	fi
done


if ((!fs_match))
then
	initialize=1
	fs_match_string="do not match"
else
	fs_match_string="OK, they match"
fi

if ((initialize)) && ((quiet))
then
	echo "Quiet mode asked for but an initialize is required - can't clone!"
	exit 1
fi

if ((!initialize && p1_size_new > 0))
then
	echo "Cannot specify a -p size for partition 1 unless initializing."
	echo "    Use -f or -f2"
	exit 1
fi

if ((initialize && p1_size_new > 0 && n_image_parts > 2))
then
	echo "Cannot specify a -p size for partition 1 unless cloning to only 2 partitions."
	echo "    Use -f2"
	exit 1
fi

if ((!force_sync && p1_size_new > dst_disk_size * 8 / 10))
then
	echo "-p1 size > 80% of destination disk size seems wrong so will not try."
	echo "    Use -F to override."
	exit 1
fi

for ((p = n_dst_parts; p >= 1; --p))
do
	if ((!dst_exists[p]))
	then
		continue
	fi
	dir=$(echo "$dst_mount_table" \
				| grep -e "^${dst_device[p]}" | cut -d " " -f 2)
	unmount_or_abort "$dir" \
"Destination disk partition ${dst_device[p]} is mounted on $dir."
done

mounted_dev=$(findmnt $clone -o source -n)
unmount_or_abort "$mounted_dev" \
			"Directory $clone is already mounted with $mounted_dev."

mounted_dev=$(findmnt $clone_src -o source -n)
unmount_or_abort "$mounted_dev" \
			"Directory $clone_src is already mounted with $mounted_dev."

mounted_dev=$(findmnt /mnt -o source -n)
unmount_or_abort "$mounted_dev" "$mounted_dev is currently mounted on /mnt."


if [ ! -d $clone ]
then
	mkdir $clone
fi
if [ ! -d $clone_src ]
then
	mkdir $clone_src
fi

# Do not include a dhpys swapfile in rsync.  It regenerates at boot.
#
if [ -f /etc/dphys-swapfile ]
then
	swapfile=`cat /etc/dphys-swapfile | grep ^CONF_SWAPFILE | cut -f 2 -d=`
	if [ "$swapfile" = "" ]
	then
		swapfile=/var/swap
	fi
	exclude_swapfile="--exclude $swapfile"
fi

if ((grub_auto)) && [ -d /boot/grub ] && command -v grub-install
then
	have_grub=1
else
	have_grub=0
fi

print_partitions

if ((initialize))
then
	if ((unattended && !Unattended))
	then
		echo $"
Unattended -u option not allowed when initializing.
Use -U for unattended even if initializing.
"
		exit 1
	fi

	n_image_parts=$((force_2_parts ? 2 : n_src_parts))

	if ((force_initialize))
	then
		reason="forced by option"
	elif ((n_dst_parts < n_image_parts))
	then
		reason="partition number mismatch: $n_image_parts -> $n_dst_parts"
	else
		reason="FS types conflict"
	fi

	start_sector=${src_start_sector[$n_image_parts]}
	last_part_sectors=$((dst_disk_size - start_sector))
	last_part_used=${src_used_sectors[$n_image_parts]}
	last_part_space=$(( (last_part_sectors > last_part_used) ? 1 : 0 ))

	if ((last_part_sectors < 7812))
	then
		printf "%-22s : %s\n" "** FATAL **" \
					"Initialize needed - $reason"
		printf "%-22s : %s %s %s\n" "" \
					"But destination is too small to clone" "$n_image_parts" "partitions."
		readable_MiB $((start_sector + 7812)) "512" min_size
		printf "%-22s : %s\n" "" \
					"Minimum destination size required is $min_size."
		if ((n_image_parts > 2))
		then
			printf "%-22s : %s\n" " " \
						"Possible options:"
			if ((raspbian))
			then
				printf "%-22s : %s\n" " " \
						"    Use -f2 to force a two partition initialize clone."
			fi
			printf "%-22s : %s\n" " " \
						"    Use -m to limit partitions to clone."
			printf "%-22s : %s\n" " " \
						"    Manually create custom partitions that can work."
			printf "%-22s : %s\n" " " \
						"    Larger destination disk.."
		fi
		printf "%-23s:\n" "-----------------------"
		exit 1
	fi

	readable_MiB $((last_part_sectors + 7812)) "512" image_space_readable

	echo "== Initialize: IMAGE partition table - $reason ==" 
	print_image_actions
	print_options

	printf "%-22s : %s\n" "** WARNING **" \
			"All destination disk $dst_disk data will be overwritten!"

	if ((raspbian_buster && p1_size_new == 0 && src_size_sectors[1] < 400000))
	then
		printf "%-22s : %s\n" "** WARNING **" \
			"Your source /boot partition is smaller than the"
		printf "%-22s : %s\n" "" \
			"  Raspbian Buster 256M standard.  Consider using"
		printf "%-22s : %s\n" "" \
			"  the '-p 256M' option to avoid /boot clone errors."
	fi

	abort=0
	if ((!last_part_space))
	then
		readable_MiB $last_part_used "512" used_readable
		printf "%-22s : %s\n" "** WARNING **" \
				"Destination last partition resize to $image_space_readable"
		printf "%-22s : %s\n" "" \
				"  is too small to hold source used $used_readable."
		if [ "$n_image_parts" == "$root_part_num" ] && ((!force_sync))
		then
			printf "%-22s : %s\n" "** FATAL **" \
					"This is the root partition, so aborting!"
			printf "%-22s : %s\n" "" \
					"  Use -F to override."
			abort=1
		elif ((!force_sync))
		then
			printf "%-22s : %s\n" "" \
					"  The partition SYNC is skipped, use -F to override."
		else
			printf "%-22s : %s\n" "" \
					"  ** Syncing anyway as you asked with -F. **"
		fi
	fi
	printf "%-23s:\n" "-----------------------"
	if ((abort))
	then
		exit 1
	fi
	confirm "Initialize and clone to the destination disk ${dst_disk}?" "abort"

	if ((!Unattended)) && [ "$ext_label" == "" ]
	then
		printf "Optional destination ext type file system label (16 chars max): "
		read ext_label
	fi

	start_time=`date '+%H:%M:%S'`
	start_sec=$(date '+%s')

	image_to_sector=${src_start_sector[1]}
	count=$((image_to_sector / 2 / 1024 + 4))  # in MiB blocks for dd bs=1M

	printf "\nInitializing\n"
	printf "  Imaging past partition 1 start.\n"
	sync
	printf "  => dd if=/dev/$src_disk of=/dev/$dst_disk bs=1M count=$count ..."
	dd if=/dev/$src_disk of=/dev/$dst_disk bs=1M count=$count &> /tmp/$PGM-output
	if [ "$?" != 0 ]
	then
		printf "\n  dd failed.  See /tmp/$PGM-output.\n"
		printf "  Try running $PGM again.\n\n"
		exit 1
	fi
	echo ""
	sync
	sleep 1
	sfd0=$(sfdisk -d /dev/$src_disk)
	if ((force_2_parts && (n_src_parts > n_image_parts)))
	then
		remove_part_start=${src_partition[3]}
		sfd0=$(echo "$sfd0" | sed -e "/\/dev\/$remove_part_start/,\$d")
	fi

	part="${src_part_base}$n_image_parts"
	sfd1=$(echo "$sfd0" | sed "\/dev\/$part/s/size=[^,]*,//")

	if ((ext_part_num > 0 && !force_2_parts))
	then
		part="${src_part_base}$ext_part_num"
		sfd1=$(echo "$sfd1" | sed "\/dev\/$part/s/size=[^,]*,//")
	fi

	if ((p1_size_new > 0))
	then
		p1_size_orig=$(echo $sfd1 | grep -Po "size= \K[^ ,]*")
		p2_start_orig=$(echo $sfd1 | grep -Po "\/dev\/${src_part_base}2 : start= \K[^ ,]*")
		p2_start_new=$((p2_start_orig + p1_size_new - p1_size_orig))
		tmp=$(echo "$sfd1" | sed -e "s/$p2_start_orig/$p2_start_new/")
		sfd1=$(echo "$tmp" | sed -e "s/$p1_size_orig/$p1_size_new/")
		printf "  Resizing both destination disk partitions ..."
	else
		printf "  Resizing destination disk last partition ..."
	fi

	for ((x = 0; x < 3; ++x))
	do
		sleep $((x + 1))
		sfdisk --force /dev/$dst_disk &> /tmp/$PGM-output <<< "$sfd1"
		if [ "$?" == 0 ]
		then
			break
		fi
		if ((x == 2))
		then
			printf "\n====$PGM\n==orig:\n%s\n\n==edited:\n%s\n" \
					"$sfd0" "$sfd1" >> /tmp/$PGM-output
			printf "\n    Resize failed.  See /tmp/$PGM-output.\n"
			printf "    Try running $PGM again.\n\n"

			# Don't let dst disk keep source disk ID.  Can lead to remounts.
			new_id=$(od -A n -t x -N 4 /dev/urandom | tr -d " ")
			qprintf "x\ni\n0x$new_id\nr\nw\nq\n" | fdisk /dev/$dst_disk > /dev/null
			exit 1
		fi
	done
	printf "\n    Resize success.\n"
	printf "  Changing destination Disk ID ..."
	sync
	sleep 2

	new_id=$(od -A n -t x -N 4 /dev/urandom | tr -d " ")
	qprintf "x\ni\n0x$new_id\nr\nw\nq\n" | fdisk /dev/$dst_disk > /dev/null
	sync
	sleep 2
	partprobe "/dev/$dst_disk"
	sleep 2
	echo ""

	for ((p = n_image_parts + 1; p <= n_src_parts; p++))
	do
		src_sync_part[p]=0
	done

	for ((p = 1; p <= n_image_parts; p++))
	do
		if ((!src_exists[p]))
		then
			continue
		fi
		dst_dev=/dev/${dst_part_base}${p}
		fs_type=${src_fs_type[$p]}
		if    ((p == ext_part_num)) \
		   || [ "$fs_type" == "--" ]
		then
			continue
		fi

		if [ "$fs_type" == "fat16" ]
		then
			mkfs_type="vfat"
		elif [ "$fs_type" == "fat32" ]
		then
			mkfs_type="vfat -F 32"
		else
			mkfs_type=$fs_type
		fi

		if [ "${src_mounted_dir[p]}" == "/boot" ] && ((p == 1))
		then
			ext_label $p "$fs_type" "-L" label
			printf "  => mkfs -t $mkfs_type $label $dst_dev ..."
			yes | mkfs -t $mkfs_type $label $dst_dev &>> /tmp/$PGM-output
			echo ""
		else
			if [ "$fs_type" == "swap" ]
			then
				printf "  => mkswap $dst_dev\n"
				mkswap $dst_dev &>> /tmp/$PGM-log
			elif ((p != ext_part_num))
			then
				if [ "${src_mounted_dir[p]}" != "" ] || ((p == n_image_parts))
				then
					ext_label $p $fs_type "-L" label
					printf "  => mkfs -t $mkfs_type $label $dst_dev ..."
					yes | mkfs -t $mkfs_type $label $dst_dev &>> /tmp/$PGM-output
					echo ""
					if ((p == n_image_parts))
					then
						if ((!last_part_space))
						then
							src_sync_part[p]=$force_sync
						else
							src_sync_part[p]=1
						fi
					fi					
				else
					printf "  => dd if=${src_device[$p]} of=$dst_dev bs=1M ..."
					dd if=${src_device[$p]} of=$dst_dev bs=1M &>> /tmp/$PGM-output
					if [ "$?" != 0 ]
					then
						printf "\n  dd failed.  See /tmp/$PGM-output.\n"
					else
						echo ""
					fi
					ext_label $p $fs_type "" label
					if [ "$label" != "" ]
					then
						echo "     e2label $dst_dev $label"
						e2label $dst_dev $label
					fi
				fi
			fi
		fi
	done
	ext_label=""
else
	qecho "== SYNC $src_disk file systems to $dst_disk =="
	print_sync_actions
	print_options

	informed=0
	space_ok=1
	all_sync_mount_ok=1
	if ((force_sync))
	then
		err="WARNING"
	else
		err="FATAL"
	fi
	for ((p = 1; p <= n_src_parts; p++))
	do
		if ((!src_exists[p] || !dst_exists[p]))
		then
			continue
		fi
		if    ((${dst_size_sectors[p]} < ${src_used_sectors[p]})) \
		   && ((src_sync_part[p]))
		then
			qprintf "%-22s : %s\n" "** $err **" \
			"Partition $p: source used > destination space."
			space_ok=$force_sync
			informed=1
		fi
		if ((all_sync && dst_mount_flag[p] == fail))
		then
			qprintf "%-22s : %s\n" "** $err **" \
			"Partition $p: mount failed, cannot sync."
			all_sync_mount_ok=$force_sync
			informed=1
		fi
	done
	if ((informed))
	then
		qprintf "%-23s:" "-----------------------"
	fi

	if ((!space_ok || !all_sync_mount_ok))
	then
		printf "\nAborting!\n"
		if ((!space_ok))
		then
			printf "  Use -F to override used > space fail or -m to select mounts to clone.\n"
		fi
		if ((!all_sync_mount_ok))
		then
			printf "  Use -a -F to sync all except failed mounts.\n"
		fi
		exit 1
	fi

	if ((raspbian_buster && dst_size_sectors[1] < 500000))
	then
		qprintf "%-22s : %s\n" "** WARNING **" \
			"Your destination /boot partition is smaller than the"
		qprintf "%-22s : %s\n" "" \
			"  Raspbian Buster 256M standard. Consider initializing"
		if ((n_dst_parts <= 2))
		then
			qprintf "%-22s : %s\n" "" \
				"  with '-f' or '-f2' along with the '-p 256M' options."
		else
			qprintf "%-22s : %s\n" "" \
				"  destination disk (gparted) with new partition sizes."
		fi
		qprintf "%-23s:\n" "-----------------------"
	fi

	confirm "Ok to proceed with the clone?" "abort"
	start_time=`date '+%H:%M:%S'`
	start_sec=$(date '+%s')
fi

line=$(fdisk -l /dev/$dst_disk | grep "Disk identifier:")
dst_disk_ID=${line#*x}
if [ "$dst_disk_ID" == "$src_disk_ID" ]
then
	qecho "Destination disk has same Disk ID as source, changing it."
	new_id=$(od -A n -t x -N 4 /dev/urandom | tr -d " ")
	qprintf "x\ni\n0x$new_id\nr\nw\nq\n" | fdisk /dev/$dst_disk | grep changed
	sync
	sleep 2
	partprobe "/dev/$dst_disk"
	sleep 2

	line=$(fdisk -l /dev/$dst_disk | grep "Disk identifier:")
	dst_disk_ID=${line#*x}
	if [ "$dst_disk_ID" == "$src_disk_ID" ]
	then
		qecho "  Failed to set a new Disk ID."
	fi
fi

sync
qprintf "\nSyncing file systems (can take a long time)\n"

sync_msg_done=0
for ((p = 1; p <= n_src_parts; p++))
do
	if ((!src_exists[p]))
	then
		continue
	fi
	if ((src_sync_part[p] && dst_mount_flag[p] == temp))
	then
		if ((!sync_msg_done))
		then
			qprintf "Syncing unmounted partitions:\n"
		fi
		sync_msg_done=1
		dst_dev=/dev/${dst_part_base}${p}
		fs_type=${src_fs_type[$p]}
		ext_label $p $fs_type "" label
		if [ "$label" != "" ]
		then
			qecho "     e2label $dst_dev $label"
			e2label $dst_dev $label
		fi

		mount_partition ${src_device[p]} $clone_src ""
		mount_partition $dst_dev $clone "$clone_src"
		unmount_list="$clone_src $clone"
		rsync_file_system "${clone_src}/" "${clone}" ""
		unmount_list "$unmount_list"
	fi
done

qprintf "Syncing mounted partitions:\n"

fs_type=${src_fs_type[$root_part_num]}
ext_label $root_part_num $fs_type "" label
if [ "$label" != "" ]
then
	qecho "     e2label $dst_root_dev $label"
	e2label $dst_root_dev $label
fi

mount_partition $dst_root_dev $clone ""
unmount_list="$clone"

rsync_file_system "//" "$clone" "with-root-excludes"

for ((p = 1; p <= n_src_parts; p++))
do
	if ((!src_exists[p]))
	then
		continue
	fi
	if ((p != root_part_num && src_sync_part[p] && dst_mount_flag[p] == live))
	then
		dst_dir=$clone${src_mounted_dir[p]}
		if [ ! -d $dst_dir ]
		then
			mkdir -p $dst_dir
		fi

		dst_dev=/dev/${dst_part_base}${p}
		fs_type=${src_fs_type[$p]}
		ext_label $p $fs_type "" label
		if [ "$label" != "" ]
		then
			qecho "     e2label $dst_dev $label"
			e2label $dst_dev $label
		fi

		mount_partition "$dst_dev" "$dst_dir" "$unmount_list"
		rsync_file_system "${src_mounted_dir[p]}/" "${dst_dir}" ""
		unmount_list="$dst_dir $unmount_list"
	fi
done
qecho ""

# Fix PARTUUID or device name references in cmdline.txt and fstab
#
fstab=${clone}/etc/fstab
cmdline_txt=${clone}/boot/cmdline.txt

if [ -f $cmdline_txt ]
then
	if ((leave_sd_usb_boot && SD_slot_dst))
	then
		qecho "Leaving SD to USB boot alone."
		cp $cmdline_txt ${clone}/boot/cmdline.boot
		cmdline_txt=${clone}/boot/cmdline.boot
	fi
	if grep -q $src_disk_ID $cmdline_txt
	then
		qecho "Editing $cmdline_txt PARTUUID to use $dst_disk_ID"
		sed -i "s/${src_disk_ID}/${dst_disk_ID}/" "$cmdline_txt"
	elif [ "$edit_fstab_name" != "" ] && grep -q ${src_part_base} $cmdline_txt
	then
		qecho "Editing $cmdline_txt references from $src_part_base to $edit_fstab_name"
		sed -i "s/${src_part_base}/$edit_fstab_name/" "$cmdline_txt"
	fi
	if ((leave_sd_usb_boot && SD_slot_boot))
	then
		qecho "Copying USB cmdline.txt to SD card to set up USB boot."
		cp /boot/cmdline.txt /boot/cmdline.boot
		cp $cmdline_txt /boot/cmdline.txt
	fi
fi

if grep -q $src_disk_ID $fstab
then
	qecho "Editing $fstab PARTUUID to use $dst_disk_ID"
	sed -i "s/${src_disk_ID}/${dst_disk_ID}/g" "$fstab"
elif [ "$edit_fstab_name" != "" ] && grep -q ${src_part_base} $fstab
then
	qecho "Editing $fstab references from $src_part_base to $edit_fstab_name"
	sed -i "s/${src_part_base}/${edit_fstab_name}/" "$fstab"
fi


rm -f $clone/etc/udev/rules.d/70-persistent-net.rules

dst_root_vol_name=`e2label $dst_root_dev`

if [ "$dst_root_vol_name" = "" ]
then
	dst_root_vol_name="no label"
fi

if ((have_grub))
then
	qecho "grub-install --root-directory=$clone /dev/$dst_disk"
	if ((quiet))
	then
		grub-install --root-directory=$clone /dev/$dst_disk &> /dev/null
	else
		grub-install --root-directory=$clone /dev/$dst_disk
	fi
fi

if [ "$setup_args" != "" ]
then
	qprintf "\nRunning setup script: $setup_command $setup_args\n"
	$setup_command $setup_args
fi

date=`date '+%F %H:%M'`
echo "$date  $HOSTNAME $PGM : clone to $dst_disk ($dst_root_vol_name)" \
		>> $clone_log
echo "$date  $HOSTNAME $PGM : clone to $dst_disk ($dst_root_vol_name)" \
		>> ${clone}${clone_log}


stop_sec=$(date '+%s')
clone_sec=$((stop_sec - start_sec))

stop_time=`date '+%H:%M:%S'`

qecho "==============================="
qecho "Done with clone to /dev/$dst_disk"
qprintf "   Start - %s    End - %s    Elapsed Time - %d:%02d\n" \
		"$start_time" "$stop_time" "$((clone_sec / 60))" "$((clone_sec % 60))"

if ((!unattended))
then
	echo -n $"
Cloned partitions are mounted on $clone for inspection or customizing. 

Hit Enter when ready to unmount the /dev/$dst_disk partitions ..."

	read resp
fi

unmount_list "$unmount_list"
qprintf "===============================\n\n"

exit 0
