#!/bin/bash

set -ex

SETARCH_ARCHITECTURE='x86_64'
LOG_FILE='hook-script.log'

DEBIAN_VERSION="${BODI_RELEASE}"
ROOTFS="${BODI_CHROOT_PATH}"

logger (){
	date +"%F %T | PID $$ | $0: $*" | tee -a "${LOG_FILE}"
}
export -f logger

nb_chroot (){
  setarch "${SETARCH_ARCHITECTURE}" capsh --drop=cap_setfcap "--chroot=${ROOTFS}" -- -e "$@"
}
export -f nb_chroot


mkdir -p "${ROOTFS}/opt/nuvlabox"

install -m "+x" files/nuvlabox-installer "${ROOTFS}/usr/local/bin/"
install -m "+x" files/sixsq.gpg_pubkey.bin "${ROOTFS}/opt/nuvlabox/gpg_pubkey.bin"
install -m "+x" files/docker_swarm_ca_rotate "${ROOTFS}/etc/cron.daily/"

logger "Add Exoscale to cloud-init datasources"
nb_chroot << EOF
sed -i 's/None/ Exoscale, None/' /etc/cloud/cloud.cfg.d/90_dpkg.cfg
EOF

logger "Downloading Docker installer"
curl -fsSL https://get.docker.com > "${ROOTFS}/tmp/install-docker.sh"

sed -i 's/9)/10)/' "${ROOTFS}/tmp/install-docker.sh"

logger "Installing Docker..."
nb_chroot <<EOF
sh /tmp/install-docker.sh
EOF

logger "Installing Docker Compose..."
nb_chroot <<EOF
export DEBIAN_FRONTEND=noninteractive
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
# apt-get install -y python3-cffi
# pip3 install wheel
# pip3 install docker-compose==1.28.6
EOF
