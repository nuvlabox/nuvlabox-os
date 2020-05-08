#!/bin/bash

EXTRA_CONFIG_FILE=${1}

docker run --privileged \
          --rm --name nuvlabox-os-build \
          -v $(pwd):/opt -w /opt \
          debian:buster \
          ./build.sh "${EXTRA_CONFIG_FILE}"