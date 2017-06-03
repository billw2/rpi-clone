#/bin/bash

# install script for rpi-clone:
#
# - updates source repo if possible
# - checks dependencies: system, rsync and fsck.vfat
# - copies rpi-clone to /usr/local/sbin & sets owner/permisions
# - copies configuration files to /etc/rpi-clone/ & sets owner/perms
# 	- only if they don't yet exist (will not overwrite existing configuration)


echo
echo "Welcome to the rpi-clone installer"
echo

# exit if not root
if [ `id -u` != 0 ]
then
        echo -e "The rpi-clone installer needs to be run as root.\n"
        exit 1
fi

#
# update repo to get latest, if possible
#
if [ -d .git ]; then
        echo "Looks like your using a git clone - we can automatically update it to get the latest version."
        echo "Perform a 'git pull origin master' now (yes/no)?:"
        read resp
        if [ "$resp" != "y" ] && [ "$resp" != "yes" ]; then
                echo "Continuing without updating the repo"
                echo
        else
                echo "Updating repo..."
		su - `logname` -c "cd `pwd` && git pull origin master"
                if [ $? = 0 ]; then
                        echo "Repo updated sucessfully"
                        echo
                else
                        echo "Problem updating repo. Aborting!"
                        echo
                        exit 1
                fi
        fi
else
        echo "Looks like you're not using a git clone, so we cannot update"
        echo "automatically. You'll need to manually download the zip to get"
        echo "latest version. If you've just done this - ignore this message!"
        echo
fi

#
# check dependencies
#
# system check
IS_RASPBIAN=`lsb_release -d | grep -i Raspbian`
if [ -z "$IS_RASPBIAN" -o ! $? = 0 ]; then
	echo "WARNING: this doesn't look like a Rapsbian system!"
	echo "Your OS is reported as:"
	lsb_release -d
	echo "Please proceed... if you know what you're doing..."
	echo
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
	echo "NB: rpi-clone can run without it, continuing with install"
	echo
fi

#
# get current state
#
INSTALL_RPI_CLONE=true
CUR_VERSION=0
INSTALL_CONF_DIR=true
INSTALL_CONF_FILE=true
INSTALL_EXCLUDES_FILE=true
NEW_VERSION=`./rpi-clone | grep Version | sed 's/^ *//'`
if [ -f /usr/local/sbin/rpi-clone ]; then
	CUR_VERSION=`/usr/local/sbin/rpi-clone | grep Version | sed 's/^ *//'`
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
	rm -f /usr/local/sbin/rpi-clone
	cp ./rpi-clone /usr/local/sbin/rpi-clone
	chown root:root /usr/local/sbin/rpi-clone
	chmod u+x /usr/local/sbin/rpi-clone
fi

if $INSTALL_CONF_DIR; then
	echo "Creating missing configuration directory at /etc/rpi-clone"
	mkdir /etc/rpi-clone
fi

if $INSTALL_CONF_FILE; then
        echo "Installing missing configuration file at /etc/rpi-clone/rpi-clone.conf"
        cp ./conf/rpi-clone.conf /etc/rpi-clone/rpi-clone.conf
fi

if $INSTALL_EXCLUDES_FILE; then
        echo "Installing missing rsync excludes file at /etc/rpi-clone/rsync.excludes"
        cp ./conf/rsync.excludes /etc/rpi-clone/rsync.excludes
fi
chown -R root:root /etc/rpi-clone
chmod -R 755 /etc/rpi-clone
echo
echo "Installation complete!"
echo
exit 0
