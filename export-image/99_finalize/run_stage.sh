#!/bin/bash

set -e

FINAL_DIR="${WORKDIR}/image"
FINAL_ROOTFS_DIR="${FINAL_DIR}/rootfs"
FINAL_IMG="${FINAL_DIR}/${IMAGE_NAME}-${IMAGE_NAME_SUFFIX}.img"
FINAL_IMG_ZIP="${FINAL_DIR}/${IMAGE_NAME}-${IMAGE_NAME_SUFFIX}.zip"

ROOTFS="${FINAL_ROOTFS_DIR}"

logger "Allow re-run"
if [ ! -x "${ROOTFS}/usr/bin/qemu-arm-static" ]; then
	cp /usr/bin/qemu-arm-static "${ROOTFS}/usr/bin/"
fi

if [ -e "${ROOTFS}/etc/ld.so.preload" ]; then
	mv "${ROOTFS}/etc/ld.so.preload" "${ROOTFS}/etc/ld.so.preload.disabled"
fi


logger "Cleaning up final image and upgrade distro"
nb_chroot <<EOF
apt-get update
apt-get -y dist-upgrade
apt-get clean
EOF

logger "Add resolv.conf - $(cat network/resolve.conf)"
install -m 644 network/resolv.conf "${ROOTFS}/etc/"

logger "Set partuuid"

IMGID="$(dd if="${FINAL_IMG}" skip=440 bs=1 count=4 2>/dev/null | xxd -e | cut -f 2 -d' ')"
BOOT_PARTUUID="${IMGID}-01"
ROOT_PARTUUID="${IMGID}-02"

sed -i "s/BOOTDEV/PARTUUID=${BOOT_PARTUUID}/" "${ROOTFS}/etc/fstab"
sed -i "s/ROOTDEV/PARTUUID=${ROOT_PARTUUID}/" "${ROOTFS}/etc/fstab"

sed -i "s/ROOTDEV/PARTUUID=${ROOT_PARTUUID}/" "${ROOTFS}/boot/cmdline.txt"


############
# FINISH
############
INFO_FILE="${FINAL_DIR}/${IMAGE_NAME}-${IMAGE_NAME_SUFFIX}.info"

nb_chroot <<EOF
if [ -x /etc/init.d/fake-hwclock ]; then
	/etc/init.d/fake-hwclock stop
fi
if hash hardlink 2>/dev/null; then
	hardlink -t /usr/share/doc
fi
EOF

if [ -d "${ROOTFS}/home/sixsq/.config" ]; then
	chmod 700 "${ROOTFS}/home/${ROOTFS}/.config"
fi

rm -f "${ROOTFS}/etc/apt/apt.conf.d/51cache"
rm -f "${ROOTFS}/usr/bin/qemu-arm-static"
rm -f "${ROOTFS}/etc/network/interfaces.dpkg-old"
rm -f "${ROOTFS}/etc/apt/sources.list~"
rm -f "${ROOTFS}/etc/apt/trusted.gpg~"
rm -f "${ROOTFS}/etc/passwd-"
rm -f "${ROOTFS}/etc/group-"
rm -f "${ROOTFS}/etc/shadow-"
rm -f "${ROOTFS}/etc/gshadow-"
rm -f "${ROOTFS}/etc/subuid-"
rm -f "${ROOTFS}/etc/subgid-"
rm -f "${ROOTFS}"/var/cache/debconf/*-old
rm -f "${ROOTFS}"/var/lib/dpkg/*-old
rm -f "${ROOTFS}"/usr/share/icons/*/icon-theme.cache
rm -f "${ROOTFS}/var/lib/dbus/machine-id"

true > "${ROOTFS}/etc/machine-id"

ln -nsf /proc/mounts "${ROOTFS}/etc/mtab"

find "${ROOTFS}/var/log/" -type f -exec cp /dev/null {} \;

rm -f "${ROOTFS}/root/.vnc/private.key"
rm -f "${ROOTFS}/etc/vnc/updateid"

echo -e "NuvlaBox OS for Raspberry Pi from $(date +%Y-%m-%d) with reference ${IMAGE_NAME_SUFFIX}\nCustom SixSq build from $(git config --get remote.origin.url), $(git rev-parse HEAD), inspired by pi-gen, https://github.com/RPi-Distro/pi-gen" > "${ROOTFS}/etc/rpi-issue"

install -m 644 "${ROOTFS}/etc/rpi-issue" "${ROOTFS}/boot/issue.txt"

cp "${ROOTFS}/etc/rpi-issue" "$INFO_FILE"


{
	if [ -f "${ROOTFS}/usr/share/doc/raspberrypi-kernel/changelog.Debian.gz" ]; then
		firmware=$(zgrep "firmware as of" \
			"$ROOTFS/usr/share/doc/raspberrypi-kernel/changelog.Debian.gz" | \
			head -n1 | sed  -n 's|.* \([^ ]*\)$|\1|p')
		printf "\nFirmware: https://github.com/raspberrypi/firmware/tree/%s\n" "$firmware"

		kernel="$(curl -s -L "https://github.com/raspberrypi/firmware/raw/$firmware/extra/git_hash")"
		printf "Kernel: https://github.com/raspberrypi/linux/tree/%s\n" "$kernel"

		uname="$(curl -s -L "https://github.com/raspberrypi/firmware/raw/$firmware/extra/uname_string7")"
		printf "Uname string: %s\n" "$uname"
	fi

	printf "\nPackages:\n"
	dpkg -l --root "$ROOTFS"
} >> "$INFO_FILE"

ROOT_DEV="$(mount | grep "${ROOTFS} " | cut -f1 -d' ')"

unmount "${ROOTFS}"
zerofree "${ROOT_DEV}"

unmount_image "${FINAL_IMG}"

pushd "${FINAL_DIR}" > /dev/null
zip "${FINAL_IMG_ZIP}" "${FINAL_IMG}"

popd > /dev/null
