#!/bin/bash
set -e

# Static in-container paths/user for deployment stability.
APP_USER="iroffer"
APP_HOME="/home/${APP_USER}"
CONFIG_DIR="${APP_HOME}/config"
DATA_DIR="${APP_HOME}/data"
LOG_DIR="${APP_HOME}/logs"
CONFIG_FILE_NAME="${IROFFER_CONFIG_FILE_NAME:-mybot.config}"

run_iroffer_as_app_user() {
  # Keep initialization as root, then drop privileges for the bot process.
  if [ "$(id -u)" -eq 0 ]; then
    exec runuser -u "${APP_USER}" -- /iroffer "$@"
  fi

  exec /iroffer "$@"
}

# allow arguments
if [ "${1:0:1}" = '-' ]; then
  echo "Arg:""$@"
  set -- /iroffer "$@"
fi

init_config() {
  # Config
  if [ ! -d "${CONFIG_DIR}" ]; then
    mkdir -p "${CONFIG_DIR}"
    if [ ! -e "${CONFIG_DIR}/${CONFIG_FILE_NAME}" ]; then
      cp /extras/sample.customized.config "${CONFIG_DIR}/${CONFIG_FILE_NAME}"
      echo "Copied fresh sample configuration to ${CONFIG_DIR}/${CONFIG_FILE_NAME}. Exiting."
      exit
    fi
    chmod -R 0755 "${CONFIG_DIR}"
    chown -R "${APP_USER}": "${CONFIG_DIR}"
  fi

  # Data
  if [ ! -d "${DATA_DIR}" ]; then
    mkdir -p "${DATA_DIR}"
    chmod -R 0750 "${DATA_DIR}"
    chown -R "${APP_USER}": "${DATA_DIR}"
  fi

  # Logs
  if [ ! -d "${LOG_DIR}" ]; then
    mkdir -p "${LOG_DIR}"
    chmod -R 0755 "${LOG_DIR}"
    chown -R "${APP_USER}": "${LOG_DIR}"
  fi
}

# Startup
if [[ -z ${1} ]]; then
# default
# prep
  init_config
  run_iroffer_as_app_user -kns -w "${APP_HOME}/" "${CONFIG_DIR}/${CONFIG_FILE_NAME}"
else
# -?|-h|-v|-c
  case "$1" in
    /iroffer|./iroffer|iroffer)
      shift
      run_iroffer_as_app_user "$@"
      ;;
    *)
      exec "$@"
      ;;
  esac
fi
