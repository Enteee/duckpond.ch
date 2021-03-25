#!/usr/bin/env bash
set -exuo pipefail

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Returns a list of container ids to pause
get_pause_containers(){
  docker ps \
    --filter "label=volume-sync_pause=true" \
    --format '{{.ID}}'
}
export PAUSE_CONTAINERS
PAUSE_CONTAINERS="$(get_pause_containers)"

while true; do
  if [ -n "${PAUSE_CONTAINERS}" ]; then
    echo "Pause containers"
    # shellcheck disable=SC2086
    docker pause ${PAUSE_CONTAINERS}
  fi

  echo "Backup"
  (
    cd "${SERVICE_USER_HOME}"
    HOME="${SERVICE_USER_HOME}"
    su \
      --preserve-environment \
      --shell "/bin/bash" \
      --group "${SERVICE_GROUP}" \
      "${SERVICE_USER}" \
      "${DIR}/backup.sh"
  )

  if [ -n "${PAUSE_CONTAINERS}" ]; then
    echo "UnPause containers"
    # shellcheck disable=SC2086
    docker unpause ${PAUSE_CONTAINERS}
  fi

  echo "Sleeping"
  # Sleep
  sleep 1h
done
