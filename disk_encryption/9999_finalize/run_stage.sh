#!/bin/bash

set -ex

IMAGE_DIR="${WORKDIR}/images"
FINAL_ISO="${IMAGE_NAME}-${IMAGE_NAME_SUFFIX}.iso"

pushd "${IMAGE_DIR}" > /dev/null

rm -f "${FINAL_ISO}"

ISO=$(find . -name "*.iso")

logger "Creating ISO ${FINAL_ISO}"

cp -f "${ISO}" "${FINAL_ISO}"

FINAL_IMG_ZIP="${IMAGE_NAME}-${IMAGE_NAME_SUFFIX}.zip"
rm -f "${FINAL_IMG_ZIP}"
zip "${FINAL_IMG_ZIP}" "${FINAL_ISO}"

popd > /dev/null
