#!/bin/bash

set -e

logger "Setting up NuvlaBox Engine USB Auto-installer feedback for Revolution Pi"

# set install binaries
install -m "+x" files/nuvlabox-auto-installer-feedback "${ROOTFS}/usr/local/bin"
