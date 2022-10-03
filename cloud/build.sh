#!/bin/sh

set -e

packages='inotify-tools,curl,wget,jq,gnupg,git,debhelper,build-essential,lockfile-progs,locales,ca-certificates,coreutils,libffi-dev,libssl-dev,python3-pip,python3-setuptools,python3-dev'

build-openstack-debian-image \
    --release buster \
    --login nuvlabox \
    --password toor \
    --boot-type mbr \
    --boot-manager grub \
    --architecture amd64 \
    --extra-packages "${packages}" \
    --hook-script ${PWD}/hook-script.sh 2>&1 | tee build.log
