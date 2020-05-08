#!/bin/bash

set -e

logger "Setting up NuvlaBox Engine USB Auto-installer"

# install requirements
nb_chroot <<EOF
apt-get -o APT::Acquire::Retries=3 install -y $(echo $(cat auto-installer/requirements.apt))
EOF

sed -i 's/PrivateMounts=yes/PrivateMounts=no/' "${ROOTFS}/lib/systemd/system/systemd-udevd.service"

# set install binaries
install -m "+x" auto-installer/nuvlabox-auto-installer-usb "${ROOTFS}/usr/local/bin"

# set systemd service
install -m 644 auto-installer/systemd/nuvlabox-auto-installer-usb.service "${ROOTFS}/etc/systemd/system/nuvlabox-auto-installer-usb.service"
nb_chroot <<EOF
systemctl enable nuvlabox-auto-installer-usb
EOF
