#!/bin/bash

EXTRA_CONFIG_FILE=${1}

docker run --privileged \
          --rm --name nuvlabox-os-build \
          -v $(pwd):/tmp -w /tmp \
          debian:buster \
          bash build.sh "${EXTRA_CONFIG_FILE}"