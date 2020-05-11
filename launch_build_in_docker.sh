#!/bin/bash

EXTRA_CONFIG_FILE=${1}

docker run --privileged \
          --name nuvlabox-os-build \
          -v $(pwd):/tmp -w /opt \
          -e CONFIG="${EXTRA_CONFIG_FILE}" \
          debian:buster \
          bash -e -o pipefail -c "cp -fr /tmp/* /opt/ &&
                                  ./build.sh \"${EXTRA_CONFIG_FILE}\" &&
                                  cp -fr *zip /tmp/"