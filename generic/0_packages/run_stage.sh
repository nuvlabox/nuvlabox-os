#!/bin/bash

set -e

if [ ! -d "${PROFILES}" ]
then
  logger "ERR: cannot find 'profiles' folder in WORDKIR ${WORKDIR}"
  exit 1
fi

logger "Installing additional core packages"

cp -f files/*.packages "${PROFILES}"

(cd ${WORKDIR} && env -i TERM=xterm bash -l -c "build-simple-cdd --force-root --verbose --profiles NUVLABOX --auto-profiles NUVLABOX")