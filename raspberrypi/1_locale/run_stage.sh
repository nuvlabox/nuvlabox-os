#!/bin/bash

set -e

logger "Installing locales..."
nb_chroot <<EOF
apt-get install -y locales
EOF

nb_chroot << EOF
debconf-set-selections <<EOFLOCALE
$(cat debconf/locales-debconf)
EOFLOCALE
EOF