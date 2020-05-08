#!/bin/bash

set -e

logger "Patch the CA certificates...need to rehash for some reason"
nb_chroot << EOF
c_rehash
EOF