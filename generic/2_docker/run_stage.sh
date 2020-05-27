#!/bin/bash

set -e

logger "Installing Docker and Docker Compose..."

cp -f files/nuvlabox.postinst "${PROFILES}"

sed -i "s/RELEASE/${RELEASE}/g" "${PROFILES}/nuvlabox.postinst"
chmod +x "${PROFILES}/nuvlabox.postinst"

(cd ${WORKDIR} && env -i TERM=xterm bash -l -c 'build-simple-cdd --force-root --verbose --profiles nuvlabox --auto-profiles nuvlabox')