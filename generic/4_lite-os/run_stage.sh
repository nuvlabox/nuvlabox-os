#!/bin/bash

set -e

# setup keyboard configuration
nb_chroot << EOF
debconf-set-selections <<EOFLOCALE
$(cat debconf/keyboard-debconf)
EOFLOCALE
EOF

# install Lite packages
# remove a few packages from the original Lite image in RPi-Distro/pi-gen
logger "Install all package requirements for lite OS version"
nb_chroot <<EOF
apt-get update
echo "grub-pc grub-pc/install_devices_empty   boolean true" | debconf-set-selections
DEBIAN_FRONTEND=noninteractive apt-get -o APT::Acquire::Retries=3 install -y $(echo $(envsubst < packages/requirements.apt))
EOF


# handle systemd services
nb_chroot << EOF
systemctl enable ssh
EOF


##############################################
# NETWORK TWEAKS
##############################################
logger "Configuring network parameters"

install -v -m 644 network/interfaces "${ROOTFS}/etc/network/interfaces"

##############################################
# TIMEZONE
##############################################
logger "Setting timezone"
echo "Etc/UTC" > "${ROOTFS}/etc/timezone"
rm "${ROOTFS}/etc/localtime" || echo "${ROOTFS}/etc/localtime not found...moving on"

nb_chroot << EOF
dpkg-reconfigure -f noninteractive tzdata
EOF