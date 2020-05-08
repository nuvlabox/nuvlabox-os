#!/bin/bash -e

if [ -f "${ROOTFS}/etc/ld.so.preload" ]; then
  mv "${ROOTFS}/etc/ld.so.preload" "${ROOTFS}/etc/ld.so.preload.disabled"
fi