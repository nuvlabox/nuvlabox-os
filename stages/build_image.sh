#!/bin/bash

set -a
source config
set +a

logger (){
	date +"[%T] $*" | tee -a "${LOG_FILE}"
}
export -f logger

for stage in ${STAGES}
do
  logger "Running stage ${stage}"
  bash "${stage}/run_stage.sh"
done
