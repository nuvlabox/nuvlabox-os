#!/bin/bash

set -e

logger "Installing Docker and Docker Compose..."

cp -f files/NUVLABOX.postinst "${PROFILES}"

sed -i "s/RELEASE/${RELEASE}/g" "${PROFILES}/NUVLABOX.postinst"
chmod +x "${PROFILES}/NUVLABOX.postinst"

(cd ${WORKDIR} && env -i TERM=xterm bash -l -c 'build-simple-cdd --force-root --verbose --profiles NUVLABOX --auto-profiles NUVLABOX')