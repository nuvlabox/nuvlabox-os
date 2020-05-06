#!/bin/bash

if [ "$(id -u)" != "0" ]; then
	echo "ERROR: need to run as root!"
	exit 1
fi

# ARCH should be in the env
ARCHITECTURE=${ARCHITECTURE:-$(dpkg --print-architecture)}

# program architecture for setarch
SETARCH_ARCHITECTURE=${SETARCH_ARCHITECTURE:-"linux32"}

# DBOOTSTRAP can have additional args, based on the target image
DBOOTSTRAP_EXTRA_ARGS=${DBOOTSTRAP_EXTRA_ARGS:-""}

# which Debian release to use
RELEASE=${RELEASE:-"buster"}

# which Debian mirror to use
MIRROR=${MIRROR:-"https://deb.debian.org/debian/"}

# which Debian release to use
WORKDIR=${WORKDIR}


if [ -z "${WORKDIR}" ]; then
	echo "ERROR: WORKDIR is not defined!"
	exit 1
fi

sudo apt-get update
sudo apt-get install -y debootstrap qemu-user-static

DBOOTSTRAP_BINARY=qemu-debootstrap

DBOOTSTRAP_ARGS=" --arch ${ARCHITECTURE}"
DBOOTSTRAP_ARGS+=" --components \"main,contrib,non-free\""
#DBOOTSTRAP_ARGS+=" --keyring "${STAGE_DIR}/files/raspberrypi.gpg")
DBOOTSTRAP_ARGS+=" ${DBOOTSTRAP_EXTRA_ARGS}"
DBOOTSTRAP_ARGS+=" ${RELEASE} ${WORKDIR} ${MIRROR}"

BOOTSTRAP_CMD="${DBOOTSTRAP_BINARY} '${DBOOTSTRAP_ARGS}'"

setarch "${SETARCH_ARCHITECTURE}" capsh --drop=cap_setfcap -- -c "'${BOOTSTRAP_CMD}'"
