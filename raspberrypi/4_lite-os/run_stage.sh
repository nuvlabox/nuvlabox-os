#!/bin/bash -ex

# where the Debian filesystem is mounted
ROOTFS=${ROOTFS:-""}

if [ -z "${ROOTFS}" ]; then
	echo "ERROR: ROOTFS is not defined! Maybe you're missing WORKDIR from your config"
	exit 1
fi

# install Lite packages
# remove a few packages from the original Lite image in RPi-Distro/pi-gen
logger "Install all package requirements for lite OS version"
nb_chroot <<EOF
apt-get -o APT::Acquire::Retries=3 install -y $(echo $(cat packages/requirements.apt))
EOF

nb_chroot <<EOF
apt-get install --no-install-recommends -y $(echo $(cat packages/requirements.nr.apt))
EOF

# patch ld.so.preload
bash patches/patch_ld.so.preload.sh

nb_chroot << EOF
debconf-set-selections <<EOFLOCALE
$(cat debconf/keyboard-debconf)
EOFLOCALE
EOF

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

