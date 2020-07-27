#!/bin/bash

set -e

RELEASE=${RELEASE:-"buster"}
PRESEED="${PROFILES}/NUVLABOX.preseed"

logger "Manual LUKS (encrypted) LVM partitioning"

# Remove partition related instructions
sed -i '/partman-/d' "${PRESEED}"
sed -i '\|partman/|d' "${PRESEED}"

echo '''
# Select the first disk
d-i partman/early_command \
    string debconf-set partman-auto/disk "$(list-devices disk | head -n1)"

# Use LVM within an encrypted partition
d-i partman-auto/method string crypto

# Select partition layout (defined below)
d-i partman-auto/choose_recipe select lvm-crypto

# Mount partitions by UUID
d-i partman/mount_style select uuid

# Do not warn if the disk contain an existing RAID
d-i partman-md/device_remove_md boolean true
d-i partman-md/confirm boolean true
d-i partman-md/confirm_nooverwrite boolean true

# Do not ask if an old non-EFI system was installed
d-i partman-efi/non_efi_system boolean true

# Do not warn if the disk contain an existing LVM
d-i partman-lvm/device_remove_lvm boolean true
d-i partman-auto/purge_lvm_from_device boolean true

# Do not ask confirmation to write the lvm partitions
d-i partman-lvm/confirm boolean true

# Do not ask confirmation to overwrite lvm partitions
d-i partman-lvm/confirm_nooverwrite boolean true

# Set LVM VG name and size
d-i partman-auto-lvm/new_vg_name string nuvlabox
d-i partman-auto-lvm/guided_size string max

# Define partition layout
d-i partman-auto/expert_recipe string \
      lvm-crypto :: \
              68 269 269 free \
                    $primary{ } \
                    $iflabel{ gpt } \
                    $reusemethod{ } \
                    method{ efi } format{ } \
                    mountpoint{ /boot/efi } \
              . \
              269 2148 2148 ext2 \
                    $primary{ } \
                    $defaultignore{ } \
                    method{ format } format{ } \
                    use_filesystem{ } filesystem{ ext4 } \
                    mountpoint{ /boot } \
              . \
              537 50% 50% linux-swap \
                    $lvmok{ } \
                    lv_name{ swap } \
                    method{ swap } format{ } \
              . \
              6443 16384 21475 ext4 \
                    $lvmok{ } \
                    lv_name{ root } \
                    method{ format } format{ } \
                    use_filesystem{ } filesystem{ ext4 } \
                    mountpoint{ / } \
              . \
              6443 10738 21475 ext4 \
                    $lvmok{ } \
                    lv_name{ home } \
                    method{ format } format{ } \
                    use_filesystem{ } filesystem{ ext4 } \
                    mountpoint{ /home } \
              . \
              537 1074 4295 ext4 \
                    $lvmok{ } \
                    lv_name{ tmp } \
                    method{ format } format{ } \
                    use_filesystem{ } filesystem{ ext4 } \
                    mountpoint{ /tmp } \
              . \
              10738 34360 -1 ext4 \
                    $lvmok{ } \
                    lv_name{ var } \
                    method{ format } format{ } \
                    use_filesystem{ } filesystem{ ext4 } \
                    mountpoint{ /var } \
              . \

# Automatically partition without confirmation
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_write_new_label boolean true
d-i partman/confirm_nooverwrite boolean true
d-i partman-partitioning/confirm_write_new_label boolean true

# Skip wiping the partitions beforehand
d-i partman-auto-crypto/erase_disks boolean false

# LUKS passphrase
#d-i partman-crypto/erase_data boolean false
d-i partman-crypto/weak_passphrase boolean true
d-i partman-crypto/passphrase password secreTshoW
d-i partman-crypto/passphrase-again password secreTshoW

''' >> "${PRESEED}"

(cd ${WORKDIR} && env -i TERM=xterm bash -l -c "build-simple-cdd --force-root --verbose --profiles NUVLABOX --auto-profiles NUVLABOX --no-do-mirror --locale 'en_US.UTF-8' --keyboard us")
