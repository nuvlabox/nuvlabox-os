#!/bin/bash -ex

logger "Installing Raspberry Pi firmware packages..."
nb_chroot <<EOF
apt-get install -y raspberrypi-bootloader raspberrypi-kernel
EOF
