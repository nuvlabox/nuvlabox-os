#!/bin/bash

set -xe

# umount
PARENT_DIR=$(dirname ${ROOTFS})
while mount | grep -q "$PARENT_DIR"; do
  LOCS=$(mount | grep "$PARENT_DIR" | cut -f 3 -d ' ' | sort -r)
  for loc in $LOCS; do
    umount "$loc"
  done
done

FINAL_DIR="${WORKDIR}/image"
FINAL_ROOTFS_DIR="${FINAL_DIR}/rootfs"
FINAL_IMG="${FINAL_DIR}/${IMAGE_NAME}-${IMAGE_NAME_SUFFIX}.img"

logger "Preparing to export final image ${FINAL_IMG}"

mkdir -p "${FINAL_ROOTFS_DIR}"

sync

# partially inherited from RPi-Distro/pi-gen
BOOT_SIZE="$((256 * 1024 * 1024))"
ROOT_SIZE=$(du --apparent-size -s "${ROOTFS}" --exclude var/cache/apt/archives --exclude boot --block-size=1 | cut -f 1)


# All partition sizes and starts will be aligned to this size
ALIGN="$((4 * 1024 * 1024))"
# Add this much space to the calculated file size. This allows for
# some overhead (since actual space usage is usually rounded up to the
# filesystem block size) and gives some free space on the resulting
# image.
ROOT_MARGIN="$(echo "($ROOT_SIZE * 0.2 + 200 * 1024 * 1024) / 1" | bc)"

BOOT_PART_START=$((ALIGN))
BOOT_PART_SIZE=$(((BOOT_SIZE + ALIGN - 1) / ALIGN * ALIGN))

ROOT_PART_START=$((BOOT_PART_START + BOOT_PART_SIZE))
ROOT_PART_SIZE=$(((ROOT_SIZE + ROOT_MARGIN + ALIGN  - 1) / ALIGN * ALIGN))
IMG_SIZE=$((BOOT_PART_START + BOOT_PART_SIZE + ROOT_PART_SIZE))

truncate -s "${IMG_SIZE}" "${FINAL_IMG}"

parted --script "${FINAL_IMG}" mklabel msdos
parted --script "${FINAL_IMG}" unit B mkpart primary fat32 "${BOOT_PART_START}" "$((BOOT_PART_START + BOOT_PART_SIZE - 1))"
parted --script "${FINAL_IMG}" unit B mkpart primary ext4 "${ROOT_PART_START}" "$((ROOT_PART_START + ROOT_PART_SIZE - 1))"

PARTED_OUT=$(parted -sm "${FINAL_IMG}" unit b print)
BOOT_OFFSET=$(echo "$PARTED_OUT" | grep -e '^1:' | cut -d':' -f 2 | tr -d B)
BOOT_LENGTH=$(echo "$PARTED_OUT" | grep -e '^1:' | cut -d':' -f 4 | tr -d B)

ROOT_OFFSET=$(echo "$PARTED_OUT" | grep -e '^2:' | cut -d':' -f 2 | tr -d B)
ROOT_LENGTH=$(echo "$PARTED_OUT" | grep -e '^2:' | cut -d':' -f 4 | tr -d B)

BOOT_DEV=$(losetup --show -f -o "${BOOT_OFFSET}" --sizelimit "${BOOT_LENGTH}" "${FINAL_IMG}")
ROOT_DEV=$(losetup --show -f -o "${ROOT_OFFSET}" --sizelimit "${ROOT_LENGTH}" "${FINAL_IMG}")
echo "/boot: offset $BOOT_OFFSET, length $BOOT_LENGTH"
echo "/:     offset $ROOT_OFFSET, length $ROOT_LENGTH"

ROOT_FEATURES="^huge_file"
for FEATURE in metadata_csum 64bit; do
	if grep -q "$FEATURE" /etc/mke2fs.conf; then
	    ROOT_FEATURES="^$FEATURE,$ROOT_FEATURES"
	fi
done
mkdosfs -n boot -F 32 -v "$BOOT_DEV" > /dev/null
mkfs.ext4 -L rootfs -O "$ROOT_FEATURES" "$ROOT_DEV" > /dev/null

mount -v "$ROOT_DEV" "${FINAL_ROOTFS_DIR}" -t ext4
mkdir -p "${FINAL_ROOTFS_DIR}/boot"
mount -v "$BOOT_DEV" "${FINAL_ROOTFS_DIR}/boot" -t vfat

rsync -aHAXx --exclude /var/cache/apt/archives --exclude /boot "${ROOTFS}/" "${FINAL_ROOTFS_DIR}/"
rsync -rtx "${ROOTFS}/boot/" "${FINAL_ROOTFS_DIR}/boot/"