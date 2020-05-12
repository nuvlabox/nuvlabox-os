#!/bin/bash

set -e

logger "Perform system tweaks"
# Set fstab
install -v -m 644 fstab/fstab "${ROOTFS}/etc/fstab"

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
