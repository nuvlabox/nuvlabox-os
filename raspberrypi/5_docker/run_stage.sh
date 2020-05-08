#!/bin/bash

set -e

logger "Downloading Docker installer"
curl -fsSL https://get.docker.com > "${ROOTFS}/tmp/install-docker.sh"

sed -i 's/9)/10)/' "${ROOTFS}/tmp/install-docker.sh"

logger "Installing Docker..."
nb_chroot <<EOF
sh /tmp/install-docker.sh
EOF

logger "Installing Docker Compose..."
nb_chroot <<EOF
apt-get -o APT::Acquire::Retries=3 install -y $(echo $(cat packages/requirements.apt))

pip3 install $(echo $(cat packages/requirements.pip))
EOF