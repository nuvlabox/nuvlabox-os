#!/bin/bash

set -e

if [ "$(id -u)" != "0" ]; then
	echo "ERROR: need to run as root!"
	exit 1
fi


# ARCH should be in the env
ARCHITECTURE=${ARCHITECTURE:-$(dpkg --print-architecture)}

# which Debian release to use
RELEASE=${RELEASE:-"buster"}

# which Debian mirror to use
MIRROR=${MIRROR:-"https://deb.debian.org/debian/"}


apt-get update
# what method to use for the build
if [ -z "${BUILD_WITH}" ] || [ "${BUILD_WITH}" == "debootstrap" ]
then
  logger "Building OS with debootstrap"

  # program architecture for setarch
  SETARCH_ARCHITECTURE=${SETARCH_ARCHITECTURE:-"linux32"}

  # DBOOTSTRAP can have additional args, based on the target image
  DBOOTSTRAP_EXTRA_ARGS=${DBOOTSTRAP_EXTRA_ARGS:-""}

  logger "Installing package dependencies for stage ${STAGE}"

  apt-get -y install --no-install-recommends git vim parted quilt coreutils qemu-user-static debootstrap \
                                            zerofree zip dosfstools bsdtar libcap2-bin rsync grep udev xz-utils \
                                            curl xxd file kmod bc binfmt-support ca-certificates gnupg

  DBOOTSTRAP_BINARY=qemu-debootstrap

  DBOOTSTRAP_ARGS=" --arch ${ARCHITECTURE}"
  DBOOTSTRAP_ARGS+=" --components \"main,contrib,non-free\""
  #DBOOTSTRAP_ARGS+=" --keyring "${STAGE_DIR}/files/raspberrypi.gpg")
  DBOOTSTRAP_ARGS+=" ${DBOOTSTRAP_EXTRA_ARGS}"
  DBOOTSTRAP_ARGS+=" ${RELEASE} ${ROOTFS} ${MIRROR}"

  DBOOTSTRAP_CMD="${DBOOTSTRAP_BINARY} ${DBOOTSTRAP_ARGS}"

  logger "Setting architecture ${SETARCH_ARCHITECTURE} and launching dbootstrap at ${ROOTFS}"
  setarch "${SETARCH_ARCHITECTURE}" capsh --drop=cap_setfcap -- -c "${DBOOTSTRAP_CMD}"

  logger "Mounting ${ROOTFS}..."
  # Mount
  mount -t proc /proc "${ROOTFS}/proc"
  mount --bind /sys "${ROOTFS}/sys"
  mount --bind /dev "${ROOTFS}/dev"
  mount --bind /dev/pts "${ROOTFS}/dev/pts"

elif [ "${BUILD_WITH}" == "simple-cdd" ]
then
  logger "Building OS with simple-cdd"

  apt-get -y install simple-cdd zip

  (cd "${WORKDIR}" && env -i TERM=xterm ARCHES="${ARCHITECTURE}" \
            bash -l -c "build-simple-cdd --force-root --verbose --dist ${RELEASE} --debian-mirror ${MIRROR} --locale 'en_US.UTF-8' --keyboard us")

  mkdir -p "${PROFILES}"
else
  logger "ERR: unrecognized BUILD tool ${BUILD_WITH}"
  exit 1
fi
