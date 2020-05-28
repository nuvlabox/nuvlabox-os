#!/bin/bash

set -e

logger "Setting up NuvlaBox Engine USB Auto-installer"

POSTINST="${PROFILES}/NUVLABOX.postinst"
EXTRA_FILES="${PROFILES}/NUVLABOX.extra"

logger "Adding custom files to image"
cat >> "${EXTRA_FILES}" <<EOF
$(pwd)/auto-installer/nuvlabox-auto-installer-usb
$(pwd)/auto-installer/systemd/nuvlabox-auto-installer-usb.service
EOF
# TODO: add $(pwd)/files/nuvlabox-auto-installer-feedback

logger "Preparing post script to install NuvlaBox Engine Auto-installer service"
cat >> "${POSTINST}" <<EOF

# scripts from ${STAGE}
sed -i 's/PrivateMounts=yes/PrivateMounts=no/' /lib/systemd/system/systemd-udevd.service

systemctl daemon-reload
systemctl restart systemd-udevd

install -m "+x" nuvlabox-auto-installer-usb /usr/local/bin
install -m 644 nuvlabox-auto-installer-usb.service /etc/systemd/system/nuvlabox-auto-installer-usb.service

systemctl enable nuvlabox-auto-installer-usb

# TODO: add feedback scripts
#install -m "+x" nuvlabox-auto-installer-feedback /usr/local/bin

systemctl start nuvlabox-auto-installer-usb
EOF

(cd ${WORKDIR} && env -i TERM=xterm bash -l -c 'build-simple-cdd --force-root --verbose --profiles NUVLABOX --auto-profiles NUVLABOX --locale "en_US.UTF-8" --keyboard us')