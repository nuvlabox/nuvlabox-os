#!/bin/bash

set -a
source config
set +a

logger (){
	date +"[%T] $*" | tee -a "${LOG_FILE}"
}
export -f logger

#for stage in ${STAGES}
#do
#  bash
#done
