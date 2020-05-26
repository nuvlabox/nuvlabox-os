#!/bin/bash

set -e

logger "Installing Docker and Docker Compose..."

cp -f files/default.postinst "${PROFILES}"

sed -i "s/RELEASE/${RELEASE}/g" "${PROFILES}/default.postinst"

(cd ${WORKDIR} && env -i TERM=xterm bash -l -c 'build-simple-cdd --force-root --verbose --profiles default --auto-profiles default')