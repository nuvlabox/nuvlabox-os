#!/bin/bash

set -e

# which Debian release to use
RELEASE=${RELEASE:-"buster"}

logger "Configuring APT sources..."
install -m 644 sources/sources.list "${ROOTFS}/etc/apt/"
sed -i "s/RELEASE/${RELEASE}/g" "${ROOTFS}/etc/apt/sources.list"

logger "Updating sources..."
nb_chroot << EOF
apt-get update
EOF