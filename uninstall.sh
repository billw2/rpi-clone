#/bin/sh

# uninstall script for rpi-clone:
#
# - deletes /usr/local/sbin/rpi-clone
# - deletes configuration directory and files at /etc/rpi-clone/
# - places copy of config files at /tmp/rpi-clone-bak/


#
# exit if not root
#
if [ `id -u` != 0 ]
then
    echo -e "The rpi-clone uninstaller needs to be run as root.\n"
    exit 1
fi

#
# summarise and get user confirmation
#
echo
echo "This will remove rpi-clone and it's configuration files from your system."
echo
echo "Continue with uninstall (yes/no)?:"
read resp
if [ "$resp" != "y" ] && [ "$resp" != "yes" ]; then
	echo "Aborted!"
	echo
	exit 0
fi

#
# And uninstall
#
echo
if [ -f /usr/local/sbin/rpi-clone ]; then
	rm -f /usr/local/sbin/rpi-clone
	echo "Deleted: /usr/local/sbin/rpi-clone"
fi
if [ -d /etc/rpi-clone/ ]; then
	rm -rf /tmp/rpi-clone-bak/
	cp -a /etc/rpi-clone/ /tmp/rpi-clone-bak/
	rm -rf /etc/rpi-clone
	echo "Deleted: /etc/rpi-clone/"
	echo
	echo "A copy of the config files has been place at /tmp/rpi-clone-bak/"
fi
echo
exit 0
