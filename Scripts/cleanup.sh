#!/usr/bin/env zsh

RUNNER_PATH/MQVMRunner stop "${CUSTOM_ENV_CI_JOB_ID}" --verbose
# do not add anything after this script, otherwise thrown errors will not fail the job
