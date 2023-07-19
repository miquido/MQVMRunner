#!/usr/bin/env zsh

RUNNER_PATH/MQVMRunner execute "${CUSTOM_ENV_CI_JOB_ID}" VM_USER AUTH "${1}" --verbose
# do not add anything after this script, otherwise thrown errors will not fail the job
