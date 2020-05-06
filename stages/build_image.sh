#!/bin/bash

set -a
source config
set +a

mkdir -p "${WORKDIR}"

logger (){
	date +"%F %T | PID $$ | $0: $*" | tee -a "${LOG_FILE}"
}
export -f logger

logger "Starting image builder for ${IMAGE_NAME} at ${WORKDIR}"

for stage in ${STAGES}
do
  logger "Running stage ${stage}"
  bash "${stage}/run_stage.sh"
done
