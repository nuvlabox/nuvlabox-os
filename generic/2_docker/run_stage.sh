#!/bin/bash

set -e

logger "Installing Docker and Docker Compose..."

cp -f files/core.postinst "${PROFILES}"

sed -i "s/RELEASE/${RELEASE}/g" "${PROFILES}/core.postinst"

(cd ${WORKDIR} && build-simple-cdd --force-root --profiles core)