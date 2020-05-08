#!/bin/bash

set -e

logger "Installing Raspberry Pi firmware packages..."
nb_chroot <<EOF
apt-get -o APT::Acquire::Retries=3 install -y raspberrypi-bootloader raspberrypi-kernel
EOF
