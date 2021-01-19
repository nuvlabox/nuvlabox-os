#!/bin/bash

set -e

logger "Install nuvlabox-auto-installer-feedback"

POSTINST="${PROFILES}/NUVLABOX.postinst"
EXTRA_FILES="${PROFILES}/NUVLABOX.extra"

logger "Adding custom files to image"
cat >> "${EXTRA_FILES}" <<EOF
$(pwd)/files/nuvlabox-auto-installer-feedback
EOF

logger "Preparing post script to install NuvlaBox Engine Auto-installer service"

cat >> "${POSTINST}" <<\EOF
# install feedback binary
install -m "+x" "$(find /media -name nuvlabox-auto-installer-feedback)" /usr/local/bin
EOF

(cd ${WORKDIR} && env -i TERM=xterm bash -l -c 'build-simple-cdd --force-root --verbose --profiles NUVLABOX --auto-profiles NUVLABOX --locale "en_US.UTF-8" --keyboard us')
