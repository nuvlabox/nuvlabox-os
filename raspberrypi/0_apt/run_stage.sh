#!/bin/bash -ex

# which Debian release to use
RELEASE=${RELEASE:-"buster"}

# where the Debian filesystem is mounted
ROOTFS=${ROOTFS:-""}

if [ -z "${ROOTFS}" ]; then
	echo "ERROR: ROOTFS is not defined! Maybe you're missing WORKDIR from your config"
	exit 1
fi

logger "Configuring APT sources..."
install -m 644 sources/sources.list "${ROOTFS}/etc/apt/"
install -m 644 sources/raspi.list "${ROOTFS}/etc/apt/sources.list.d/"
sed -i "s/RELEASE/${RELEASE}/g" "${ROOTFS}/etc/apt/sources.list"
sed -i "s/RELEASE/${RELEASE}/g" "${ROOTFS}/etc/apt/sources.list.d/raspi.list"

curl -fsSL 'https://raw.githubusercontent.com/RPi-Distro/pi-gen/d347d8d5f7c1fae250322265dad83ae5825bf50e/stage0/00-configure-apt/files/raspberrypi.gpg.key' | nb_chroot apt-key add -

logger "Upgrading distribution..."
nb_chroot << EOF
apt-get update
apt-get dist-upgrade -y
EOF