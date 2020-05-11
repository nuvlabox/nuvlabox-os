#!/bin/bash

set -e

trap 'catch' ERR
catch() {
  echo "  ERROR: could not complete installation"
  exit 1
}

EXTRA_CONFIG_FILE=${1}

set -a
source config
[ ! -z "${EXTRA_CONFIG_FILE}" ] && source "${EXTRA_CONFIG_FILE}"
set +a

##### functions
logger (){
	date +"%F %T | PID $$ | $0: $*" | tee -a "${LOG_FILE}"
}
export -f logger

nb_chroot (){
  setarch "${SETARCH_ARCHITECTURE}" capsh --drop=cap_setfcap "--chroot=${ROOTFS}" -- -e "$@"
}
export -f nb_chroot

unmount(){
	if [ -z "$1" ]; then
		DIR=$PWD
	else
		DIR=$1
	fi

	while mount | grep -q "$DIR"; do
		local LOCS
		LOCS=$(mount | grep "$DIR" | cut -f 3 -d ' ' | sort -r)
		for loc in $LOCS; do
			umount "$loc"
		done
	done
}
export -f unmount

unmount_image(){
	sync
	sleep 1
	local LOOP_DEVICES
	LOOP_DEVICES=$(losetup --list | grep "$(basename "${1}")" | cut -f1 -d' ')
	for LOOP_DEV in ${LOOP_DEVICES}; do
		if [ -n "${LOOP_DEV}" ]; then
			local MOUNTED_DIR
			MOUNTED_DIR=$(mount | grep "$(basename "${LOOP_DEV}")" | head -n 1 | cut -f 3 -d ' ')
			if [ -n "${MOUNTED_DIR}" ] && [ "${MOUNTED_DIR}" != "/" ]; then
				unmount "$(dirname "${MOUNTED_DIR}")"
			fi
			sleep 1
			losetup -d "${LOOP_DEV}"
		fi
	done
}
export -f unmount_image
##### end of functions

[ -z "${IMAGE_NAME}" ] && logger "Please define IMAGE_NAME in the configuration file" && exit 1
export IMAGE_NAME_SUFFIX=$(date +"%s")

mkdir -p "${WORKDIR}"

logger "Starting image builder for ${IMAGE_NAME} at ${WORKDIR}"

for folder in ${STAGE_BUNDLES}
do
  # remove trailing slash just in case
  folder=${folder%"/"}
  logger "  #####  Running in stage bundle ${folder}"

  # check if there's an execution order for the stages, otherwise they'll be executed alphabetically
  if [ -f "${folder}/.order" ]
  then
    stages=$(cat "${folder}/.order")
  else
    stages=$(ls "${folder}")
  fi

  # Execute stages one by one
  for stage in ${stages}
  do
    export STAGE="${folder}/${stage}"
    if [ -f "${folder}/${stage}/run_stage.sh" ]
    then
      logger "  ##########  Running stage ${stage}"
      pushd "${folder}/${stage}" > /dev/null
      bash run_stage.sh
      popd > /dev/null
    else
      logger "  *x*x*x*x*x*x*x*x*  Stage ${stage} is missing the run_stage.sh executable...skipping stage"
    fi
  done
done
