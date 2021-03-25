#!/usr/bin/env bash
set -exuo pipefail

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Ensure needed environment variables are set
export BORG_REPO="${BORG_REPO?Missing env var BORG_REPO}"
export BORG_PASSPHRASE="${BORG_PASSPHRASE?Missing env var BORG_PASSPHRASE}"
export BORG_VOLUMES="${BORG_VOLUMES?Missing env var BORG_VOLUMES}"

# Returns a list of container ids to pause
get_pause_containers(){
  # shellcheck disable=SC2046
  docker ps \
    --format '{{.ID}}' \
  | grep -v $(
    docker ps \
      --filter "label=volume-sync_pause=false" \
      --format '{{.ID}}'
  )
}
export PAUSE_CONTAINERS
PAUSE_CONTAINERS="$(get_pause_containers)"

# Do pause all containers
pause_containers(){
  if [ -n "${PAUSE_CONTAINERS}" ]; then
    echo "Pause containers"
    # shellcheck disable=SC2086
    docker pause ${PAUSE_CONTAINERS}
  fi
}

# Do unpause all containers
unpause_containers(){
  if [ -n "${PAUSE_CONTAINERS}" ]; then
    echo "UnPause containers"
    # shellcheck disable=SC2086
    docker unpause ${PAUSE_CONTAINERS}
  fi
}

# Initialize repository if it does not exist
init_repo(){
  if ! borg info &>/dev/null; then
    echo "Init repository"
    borg init \
      --encryption repokey \
      --verbose
  fi
}

# Do create the backup
create_backup(){
  echo "Starting backup"
  borg create \
    --verbose \
    --filter AME \
    --list \
    --stats \
    --show-rc \
    --compression lz4 \
    --exclude-caches \
    ::'{hostname}-{now}' \
    "${BORG_VOLUMES}"
}

# Change owner of backup
chown_backup(){
  echo "Chown Backup"
  chown \
    --recursive \
    "${SERVICE_UID}":"${SERVICE_GID}" \
    "${BORG_REPO}"
}

# Check and verify repository
check_repo(){
  echo "Check repository"
  borg check \
    --verify-data
}

# Prune old backups
prune_repo(){
  echo "Pruning repository"
  borg prune \
    --list \
    --prefix '{hostname}-' \
    --show-rc \
    --keep-daily    7 \
    --keep-weekly   4 \
    --keep-monthly  6
}

#
# Main
#
pause_containers
init_repo
create_backup
check_repo
prune_repo
chown_backup
unpause_containers
