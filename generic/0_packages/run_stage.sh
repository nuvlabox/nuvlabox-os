#!/bin/bash

set -e

# which Debian release to use
PROFILES="${WORKDIR}/profiles"

if [ ! -d "${PROFILES}" ]
then
  logger "ERR: cannot find 'profiles' folder in WORDKIR ${WORKDIR}"
  exit 1
fi

logger "Installing additional core packages"

cp -f files/core.packages "${PROFILES}"

(cd ${WORKDIR} && build-simple-cdd --force-root --profiles core)