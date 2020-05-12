#!/bin/bash

set -e

logger "Installing Docker..."
nb_chroot <<EOF
apt-get update
apt-get -o APT::Acquire::Retries=3 install -y $(echo $(envsubst < packages/requirements.apt))
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
add-apt-repository \
   "deb [arch=$ARCHITECTURE] https://download.docker.com/linux/debian \
   $RELEASE \
   stable"
apt-get update
apt-get install docker-ce docker-ce-cli containerd.io
EOF

logger "Installing Docker Compose..."
nb_chroot <<EOF
pip3 install $(echo $(cat packages/requirements.pip))
EOF