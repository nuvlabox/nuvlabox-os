#!/bin/bash

set -e

logger "Setting up Misc"

POSTINST="${PROFILES}/NUVLABOX.postinst"
EXTRA_FILES="${PROFILES}/NUVLABOX.extra"

logger " - Adding custom files to image"
cat >> "${EXTRA_FILES}" <<EOF
$(pwd)/files/docker_swarm_ca_rotate
EOF

logger " - Preparing post script"

cat >> "${POSTINST}" <<\EOF

# set install files
install -m "+x" "$(find /media -name docker_swarm_ca_rotate)" /etc/cron.daily/

EOF

(cd ${WORKDIR} && env -i TERM=xterm bash -l -c 'build-simple-cdd --force-root --verbose --profiles NUVLABOX --auto-profiles NUVLABOX --locale "en_US.UTF-8" --keyboard us')
