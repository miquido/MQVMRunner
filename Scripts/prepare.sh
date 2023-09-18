#!/usr/bin/env zsh

RUNNER_PATH/MQVMRunner start "${CUSTOM_ENV_CI_JOB_IMAGE:-latest}" "${CUSTOM_ENV_CI_JOB_ID}" VM_USER AUTH --xcode "${CUSTOM_ENV_XCODE}" CACHE_MOUNT --verbose
# do not add anything after this script, otherwise thrown errors will not fail the job
