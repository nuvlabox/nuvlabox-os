#!/bin/bash

set -e

IMAGE_DIR="${WORKDIR}/images"

pushd "${IMAGE_DIR}" > /dev/null

ISO=$(find . -name "*.iso")

FINAL_ISO="${IMAGE_NAME}.iso"
logger "Creating ISO ${FINAL_ISO}"

cp -f "${ISO}" "${FINAL_ISO}"

FINAL_IMG_ZIP="${IMAGE_NAME}.zip"
zip "${FINAL_IMG_ZIP}" "${FINAL_ISO}"

popd > /dev/null

