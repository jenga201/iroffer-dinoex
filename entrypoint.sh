#!/bin/bash
set -e

# Static in-container paths/user for deployment stability.
APP_USER="iroffer"
APP_HOME="/home/${APP_USER}"
CONFIG_DIR="${APP_HOME}/config"
DATA_DIR="${APP_HOME}/data"
LOG_DIR="${APP_HOME}/logs"
CONFIG_FILE_NAME="iroffer.config"
BOT_NAME="${IROFFER_BOT_NAME:-}"
PORT_RANGE_OVERRIDE="${PORT_RANGE:-}"

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
  # Config: ensure directory exists, then ensure config file exists.
  if [ ! -d "${CONFIG_DIR}" ]; then
    mkdir -p "${CONFIG_DIR}"
    chmod -R 0755 "${CONFIG_DIR}"
    chown -R "${APP_USER}": "${CONFIG_DIR}"
  fi

  if [ ! -e "${CONFIG_DIR}/${CONFIG_FILE_NAME}" ]; then
    cp /extras/sample.customized.config "${CONFIG_DIR}/${CONFIG_FILE_NAME}"
    echo "Copied fresh sample configuration to ${CONFIG_DIR}/${CONFIG_FILE_NAME}."
    chmod -R 0755 "${CONFIG_DIR}/${CONFIG_FILE_NAME}"
    chown -R "${APP_USER}": "${CONFIG_DIR}/${CONFIG_FILE_NAME}"
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

apply_bot_name_override() {
  local config_path="${CONFIG_DIR}/${CONFIG_FILE_NAME}"

  if [ -z "${BOT_NAME}" ] || [ ! -f "${config_path}" ]; then
    return
  fi

  # Escape replacement-sensitive characters for sed.
  local escaped_bot_name
  escaped_bot_name=$(printf '%s' "${BOT_NAME}" | sed 's/[\\&|]/\\&/g')

  if grep -q '^user_nick[[:space:]]' "${config_path}"; then
    sed -i -E "s|^user_nick[[:space:]].*$|user_nick ${escaped_bot_name}|" "${config_path}"
  else
    printf '\nuser_nick %s\n' "${BOT_NAME}" >> "${config_path}"
  fi

  chown "${APP_USER}": "${config_path}"
}

apply_port_range_override() {
  local config_path="${CONFIG_DIR}/${CONFIG_FILE_NAME}"

  if [ -z "${PORT_RANGE_OVERRIDE}" ] || [ ! -f "${config_path}" ]; then
    return
  fi

  local range_start range_limit
  range_start=${PORT_RANGE_OVERRIDE%%-*}
  range_limit=${PORT_RANGE_OVERRIDE##*-}

  if ! [[ "${range_start}" =~ ^[0-9]+$ && "${range_limit}" =~ ^[0-9]+$ ]]; then
    echo "Invalid PORT_RANGE '${PORT_RANGE_OVERRIDE}'. Expected format: START-END (e.g. 30000-31000)." >&2
    exit 1
  fi

  if [ "${range_start}" -lt 1 ] || [ "${range_limit}" -gt 65535 ] || [ "${range_start}" -gt "${range_limit}" ]; then
    echo "Invalid PORT_RANGE '${PORT_RANGE_OVERRIDE}'. Valid range is 1-65535 and START <= END." >&2
    exit 1
  fi

  # iroffer uses tcprangelimit as the maximum port number, not a count.
  if grep -q '^#\?tcprangestart[[:space:]]' "${config_path}"; then
    sed -i -E "s|^#?tcprangestart[[:space:]].*$|tcprangestart ${range_start}|" "${config_path}"
  else
    printf '\ntcprangestart %s\n' "${range_start}" >> "${config_path}"
  fi

  if grep -q '^#\?tcprangelimit[[:space:]]' "${config_path}"; then
    sed -i -E "s|^#?tcprangelimit[[:space:]].*$|tcprangelimit ${range_limit}|" "${config_path}"
  else
    printf 'tcprangelimit %s\n' "${range_limit}" >> "${config_path}"
  fi

  chown "${APP_USER}": "${config_path}"
}

# Startup
if [[ -z ${1} ]]; then
# default
# prep
  init_config
  apply_bot_name_override
  apply_port_range_override
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
