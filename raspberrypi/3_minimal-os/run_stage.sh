#!/bin/bash -ex

# where the Debian filesystem is mounted
ROOTFS=${ROOTFS:-""}

if [ -z "${ROOTFS}" ]; then
	echo "ERROR: ROOTFS is not defined! Maybe you're missing WORKDIR from your config"
	exit 1
fi

logger "Setting up cmdline.txt and config.txt boot files for Raspberry Pi"
# Set bootfiles
install -m 644 bootfiles/cmdline.txt "${ROOTFS}/boot/"
install -m 644 bootfiles/config.txt "${ROOTFS}/boot/"

logger "Perform system tweaks"
# Set fstab
install -v -m 644 fstab/fstab "${ROOTFS}/etc/fstab"

# Set getty service
install -d "${ROOTFS}/etc/systemd/system/getty@tty1.service.d"
install -m 644 systemd/noclear.conf "${ROOTFS}/etc/systemd/system/getty@tty1.service.d/noclear.conf"

# set default user
if [ ! -z $DEVELOPMENT ] && [ $DEVELOPMENT -eq 1 ]
then
  logger "ATTENTION: building DEVELOPMENT image...adding default user 'sixsq'"
  nb_chroot << EOF
adduser --disabled-password --gecos "" sixsq

echo "sixsq:nuvlabox" | chpasswd
echo "root:root" | chpasswd
EOF
fi

# set hostname
TARGET_HOSTNAME=${TARGET_HOSTNAME:-"nuvlabox-os"}

logger "Setting hostname to ${TARGET_HOSTNAME}"
echo "${TARGET_HOSTNAME}" > "${ROOTFS}/etc/hostname"
echo "127.0.1.1		${TARGET_HOSTNAME}" >> "${ROOTFS}/etc/hosts"

# minimal network configuration
# mask udev's .link file for the default policy - for classic net interface names
ln -sf /dev/null "${ROOTFS}/etc/systemd/network/99-default.link"

# install minimal packages
logger "Installing minimal set of packages..."
nb_chroot <<EOF
apt-get install -y netbase libraspberrypi-bin libraspberrypi0 raspi-config
EOF
