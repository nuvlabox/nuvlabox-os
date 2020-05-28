#!/bin/bash

set -e

logger "Automate and perform system tweaks through preseed"

RELEASE=${RELEASE:-"buster"}
PRESEED="${PROFILES}/NUVLABOX.preseed"
wget https://www.debian.org/releases/${RELEASE}/example-preseed.txt -O "${PRESEED}"


# automate and prioritize installation
logger "Configuring automated Debian Installer"
echo 'd-i debconf/priority string critical' >> "${PRESEED}"
echo 'd-i console-setup/ask_detect boolean false' >> "${PRESEED}"

# locale, language
logger "Setting language and location"
sed -i '/debian-installer\/language/c\d-i debian-installer\/language string en' "${PRESEED}"
sed -i '/debian-installer\/country/c\d-i debian-installer\/country string CH' "${PRESEED}"
sed -i '/debian-installer\/locale/c\d-i debian-installer\/locale string en_US.UTF-8' "${PRESEED}"
sed -i '/localechooser\/supported-locales/c\d-i localechooser\/supported-locales multiselect en_US.UTF-8' "${PRESEED}"
echo 'd-i keymap select us' >> "${PRESEED}"
echo 'd-i keyboard-configuration/layoutcode string us' >> "${PRESEED}"
echo 'd-i keyboard-configuration/variantcode string' >> "${PRESEED}"

# set hostname
TARGET_HOSTNAME=${TARGET_HOSTNAME:-"nuvlabox-os"}

logger "Setting hostname to ${TARGET_HOSTNAME} and erase domain name"
sed -i "s/unassigned-hostname/${TARGET_HOSTNAME}/" "${PRESEED}"
sed -i "s/unassigned-domain/nuvlabox/" "${PRESEED}"
sed -i "s/somehost/${TARGET_HOSTNAME}/" "${PRESEED}"

# disable prompt to load_firmware
logger "Force load_firmware"
sed -i '/hw-detect\/load_firmware/c\d-i hw-detect\/load_firmware boolean true' "${PRESEED}"

# set mirror conf
logger "Setting mirror parameters"
sed -i '/d-i mirror\/country/c\d-i mirror\/country string Switzerland' "${PRESEED}"

# login configurations
logger "Disable root login"
sed -i '/passwd\/root-login/c\d-i passwd\/root-login boolean false' "${PRESEED}"

if [ ! -z $DEVELOPMENT ] && [ $DEVELOPMENT -eq 1 ]
then
  logger "ATTENTION: building DEVELOPMENT image...adding default user 'sixsq', with password 'sixsq'"
  sed -i '/passwd\/user-fullname/c\d-i passwd/user-fullname string SixSq' "${PRESEED}"
  sed -i '/passwd\/username/c\d-i passwd/username string sixsq' "${PRESEED}"
  sed -i '/passwd\/user-password password/c\d-i passwd\/user-password password sixsq' "${PRESEED}"
  sed -i '/passwd\/user-password-again/c\d-i passwd\/user-password-again password sixsq' "${PRESEED}"
fi

# clock and timezone
logger "Setting clock and timezone"
sed -i 's/US\/Eastern/Etc\/UTC/' "${PRESEED}"

# partitioning
logger "Automating partitioning"
echo 'd-i grub-installer/bootdev  string /dev/sda' >> "${PRESEED}"
echo 'd-i grub-installer/bootdev  string default' >> "${PRESEED}"

# TODO: it's not right to hardcode /dev/sda, as in some cases, we might have multiple disks.
# TODO: should probably be replaced by a custom partitioning script (partman-auto/expert_recipe_file), or left manual
echo 'd-i partman-auto/disk string /dev/sda' >> "${PRESEED}"

sed -i 's/#d-i partman-auto\/init_automatically_partition/d-i partman-auto\/init_automatically_partition/' "${PRESEED}"

# Force EFI install even non-EFI OS detected.
logger "Forcing EFI boot"
echo 'd-i partman-efi/non_efi_system boolean true' >> "${PRESEED}"

# additional software
logger "Setting initial software packs"
sed -i '/tasksel tasksel\/first/c\tasksel tasksel/first multiselect standard' "${PRESEED}"

# apt
logger "Configuring APT"
sed -i 's/#d-i apt-setup\/services-select/d-i apt-setup\/services-select/' "${PRESEED}"
sed -i 's/#d-i apt-setup\/security_host/d-i apt-setup\/security_host/' "${PRESEED}"
sed -i 's/#d-i pkgsel\/upgrade/d-i pkgsel\/upgrade/' "${PRESEED}"

# popularity contest
logger "Disable popularity contest participation"
sed -i 's/#popularity-contest/popularity-contest/' "${PRESEED}"

# eject media after installation
logger "Tweaking media ejection after installation"
sed -i '/cdrom-detect\/eject/c\d-i cdrom-detect\/eject boolean true' "${PRESEED}"


(cd ${WORKDIR} && env -i TERM=xterm bash -l -c "build-simple-cdd --force-root --verbose --profiles NUVLABOX --auto-profiles NUVLABOX --no-do-mirror --locale 'en_US.UTF-8' --keyboard us")