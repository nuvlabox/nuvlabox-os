#!/bin/bash

set -e

logger "Automate and perform system tweaks through preseed"

RELEASE=${RELEASE:-"buster"}
PRESEED="${PROFILES}/default.preseed"
wget https://www.debian.org/releases/${RELEASE}/example-preseed.txt -O "${PRESEED}"

# locale, language
logger "Setting language and location"
sed -i '/debian-installer\/language/c\d-i debian-installer\/language string en' "${PRESEED}"
sed -i '/debian-installer\/country/c\d-i debian-installer\/country string CH' "${PRESEED}"
sed -i '/debian-installer\/locale/c\d-i debian-installer\/locale string en_US.UTF-8' "${PRESEED}"
sed -i '/localechooser\/supported-locales/c\d-i localechooser\/supported-locales multiselect en_US.UTF-8' "${PRESEED}"


# set hostname
TARGET_HOSTNAME=${TARGET_HOSTNAME:-"nuvlabox-os"}

logger "Setting hostname to ${TARGET_HOSTNAME} and erase domain name"
sed -i "s/unassigned-hostname/${TARGET_HOSTNAME}/" "${PRESEED}"
sed -i "s/d-i netcfg\/get_domain/#d-i netcfg\/get_domain/" "${PRESEED}"
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
  sed -i '/passwd\/username/c\d-i passwd/username string sixsq' "${PRESEED}"
  sed -i 's/password insecure/password sixsq/' "${PRESEED}"
fi

# clock and timezone
logger "Setting clock and timezone"
sed -i 's/US\/Eastern/Etc\/UTC/' "${PRESEED}"

# partitioning
#logger "Automating partitioning"
#sed -i 's/#d-i partman-auto\/init_automatically_partition/d-i partman-auto\/init_automatically_partition/' "${PRESEED}"

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


(cd ${WORKDIR} && env -i TERM=xterm bash -l -c "build-simple-cdd --force-root --verbose --profiles default --auto-profiles default --no-do-mirror")