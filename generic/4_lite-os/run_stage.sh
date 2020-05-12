#!/bin/bash

set -e

# setup keyboard configuration
nb_chroot << EOF
debconf-set-selections <<EOFLOCALE
$(cat debconf/keyboard-debconf)
EOFLOCALE
EOF

# install Lite packages
# remove a few packages from the original Lite image in RPi-Distro/pi-gen
logger "Install all package requirements for lite OS version"
nb_chroot <<EOF
apt-get update
apt-get -o APT::Acquire::Retries=3 install -y $(echo $(cat packages/requirements.apt))
EOF

nb_chroot <<EOF
apt-get -o APT::Acquire::Retries=3 install --no-install-recommends -y $(echo $(cat packages/requirements.nr.apt))
EOF

# patch
bash patches/patch_ld.so.preload.sh
bash patches/patch_rehash.sh

logger "Set initial services, resize2fs_once, apt optimization, rc.local and others..."
# resize disk on first boot
install -m 755 init.d/resize2fs_once "${ROOTFS}/etc/init.d/"

# Standard Output
install -d "${ROOTFS}/etc/systemd/system/rc-local.service.d"
install -m 644 rc.local.service.d/ttyoutput.conf "${ROOTFS}/etc/systemd/system/rc-local.service.d/"

# apt raspi optimization
install -m 644 apt/50raspi "${ROOTFS}/etc/apt/apt.conf.d/"

# console setup
install -m 644 default/console-setup "${ROOTFS}/etc/default/"

# rc.local
install -m 755 rc.local/rc.local "${ROOTFS}/etc/"

# handle systemd services
nb_chroot << EOF
systemctl disable hwclock.sh
systemctl disable nfs-common
systemctl disable rpcbind
systemctl enable ssh
systemctl enable regenerate_ssh_host_keys
systemctl enable resize2fs_once
EOF

# handle RPi interfaces
logger "Handling RPi interfaces groups"
nb_chroot <<EOF
for GRP in input spi i2c gpio; do
	groupadd -f -r "\$GRP"
done
EOF

# give user access to interfaces if in Development mode
if [ ! -z $DEVELOPMENT ] && [ $DEVELOPMENT -eq 1 ]
then
  logger "ATTENTION: building DEVELOPMENT image...give user 'sixsq' access to RPi interfaces"
  nb_chroot << EOF
for GRP in adm dialout cdrom audio users sudo video games plugdev input gpio spi i2c netdev; do
  adduser sixsq \$GRP
done
EOF
fi

logger "Save configurations"
nb_chroot << EOF
setupcon --force --save-only -v

usermod --pass='*' root
EOF

rm -f "${ROOTFS}/etc/ssh/"ssh_host_*_key*

# apply patches
logger "Preparing to apply patches"
current=$(basename $(pwd))
export QUILT_PATCHES=$(realpath patches)
pushd "${WORKDIR}"
rm -fr .pc *-pc
mkdir -p "${current}-pc"
ln -snf "${current}-pc" .pc

quilt upgrade
RC=0
quilt push -a || RC=$?
case "$RC" in
  0|2)
    ;;
  *)
    false
    ;;
esac
popd


##############################################
# NETWORK TWEAKS
##############################################
logger "Configuring network parameters"
install -v -d "${ROOTFS}/etc/systemd/system/dhcpcd.service.d"
install -v -m 644 network/wait.conf "${ROOTFS}/etc/systemd/system/dhcpcd.service.d/"

install -v -d "${ROOTFS}/etc/wpa_supplicant"
install -v -m 600 network/wpa_supplicant.conf "${ROOTFS}/etc/wpa_supplicant/"

# Disable wifi on 5GHz models
mkdir -p "${ROOTFS}/var/lib/systemd/rfkill/"
echo 1 > "${ROOTFS}/var/lib/systemd/rfkill/platform-3f300000.mmcnr:wlan"
echo 1 > "${ROOTFS}/var/lib/systemd/rfkill/platform-fe300000.mmcnr:wlan"


##############################################
# TIMEZONE
##############################################
logger "Setting timezone"
echo "Etc/UTC" > "${ROOTFS}/etc/timezone"
rm "${ROOTFS}/etc/localtime" || echo "${ROOTFS}/etc/localtime not found...moving on"

nb_chroot << EOF
dpkg-reconfigure -f noninteractive tzdata
EOF