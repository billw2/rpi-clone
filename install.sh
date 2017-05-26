#/bin/bash

# install script for rpi-clone:
#
# - checks dependencies: rsync and fsck.vfat
# - copies rpi-clone to /usr/local/sbin & sets owner/permisions
# - copies configuration files to /etc/rpi-clone/ if they don't yet exist (will not overwrite existing configuration)


#
# check dependencies
#
# exit if not root
if [ `id -u` != 0 ]
then
	echo -e "The rpi-clone installer needs to be run as root.\n"
	exit 1
fi
# rsync check
if ! rsync --version > /dev/null
then
        echo -e "\nOoops! rpi-clone needs the rsync program but cannot find it."
        echo "Make sure rsync is installed:"
        echo "    $ sudo apt-get update"
        echo -e "    $ sudo apt-get install rsync\n"
        exit 1
fi
# fsck.vfat check
if ! test -e /sbin/fsck.vfat
then
        echo "[Note] fsck.vfat was not found."
        echo "It is recommended to install dosfstools:"
        echo "    $ sudo apt-get update"
        echo -e "    $ sudo apt-get install dosfstools\n"
	echo "NB: this is recommneded, but rpi-clone will run without it, continuing with install"
fi 

#
# get current state
#
INSTALL_RPI_CLONE=true
CUR_VERSION=0
INSTALL_CONF_DIR=true
INSTALL_CONF_FILE=true
INSTALL_EXCLUDES_FILE=true
NEW_VERSION=`sudo ./rpi-clone | grep Version | sed 's/^ *//'`
if [ -f /usr/local/sbin/rpi-clone ]; then
	CUR_VERSION=`sudo /usr/local/sbin/rpi-clone | grep Version | sed 's/^ *//'`
	if [ "$CUR_VERSION" = "$NEW_VERSION" ]; then
		INSTALL_RPI_CLONE=false
	fi
fi
if [ -d /etc/rpi-clone ]; then
	INSTALL_CONF_DIR=false
	if [ -f /etc/rpi-clone/rpi-clone.conf ]; then
		INSTALL_CONF_FILE=false
	fi
	if [ -f /etc/rpi-clone/rsync.excludes ]; then
                INSTALL_EXCLUDES_FILE=false
        fi
fi

#
# summarise and get user confirmation
#
echo
echo "Welcome to the rpi-clone installer"
echo
if [ "$INSTALL_CONF_DIR" = false -a "$INSTALL_CONF_FILE" = false -a "$INSTALL_EXCLUDES_FILE" = false -a "$INSTALL_RPI_CLONE" = false ]; then
	echo "Latest $CUR_VERSION already installed and configuration files in place"
	echo "Nothing to do - exiting!"
	echo
	exit 0
else
	echo "This will:"
	if $INSTALL_RPI_CLONE; then
		if [ "$CUR_VERSION" = 0 ]; then
			echo " - Install rpi-clone $NEW_VERSION"
		else
			echo " - Update rpi-clone from $CUR_VERSION to $NEW_VERSION"
		fi
	fi
	if $INSTALL_CONF_DIR; then
		echo " - Install missing configuration directory at /etc/rpi-clone/"
	fi
	if $INSTALL_CONF_FILE; then
		echo " - Install missing configuration file at /etc/rpi-clone/rpi-clone.conf"
	fi
	if $INSTALL_EXCLUDES_FILE; then
                echo " - Install missing rsync excludes file at /etc/rpi-clone/rsync.excludes"
        fi
fi
echo
echo "Continue with install (yes/no)?:"
read resp
if [ "$resp" != "y" ] && [ "$resp" != "yes" ]; then
	echo "Aborted!"
	echo
	exit 0
fi

#
# And finally install
#
if $INSTALL_RPI_CLONE; then
	echo "Installing rpi-clone to /usr/local/sbin/rpi-clone"
	sudo rm -f /usr/local/sbin/rpi-clone
	sudo cp ./rpi-clone /usr/local/sbin/rpi-clone
	sudo chown root:root /usr/local/sbin/rpi-clone
	sudo chmod u+x /usr/local/sbin/rpi-clone
fi

if $INSTALL_CONF_DIR; then
	echo "Creating missing configuration directory at /etc/rpi-clone"
	sudo mkdir /etc/rpi-clone
fi

if $INSTALL_CONF_FILE; then
        echo "Installing missing configuration file at /etc/rpi-clone/rpi-clone.conf"
        sudo cp ./conf/rpi-clone.conf /etc/rpi-clone/rpi-clone.conf
fi

if $INSTALL_EXCLUDES_FILE; then
        echo "Installing missing rsync excludes file at /etc/rpi-clone/rsync.excludes"
        sudo cp ./conf/rsync.excludes /etc/rpi-clone/rsync.excludes
fi
sudo chown -R root:root /etc/rpi-clone
sudo chmod -R 755 /etc/rpi-clone
echo
echo "Installation complete!"
echo
exit 0
