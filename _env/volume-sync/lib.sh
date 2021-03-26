#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
   echo "This script must be sourced"
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
  | {
    grep -v $(
      docker ps \
        --filter "label=volume-sync_pause=false" \
        --format '{{.ID}}'
    ) || true
  } \
  | tr '\n' ' '
}

# Do pause all containers
pause_containers(){
  if [ "${#}" -ne 0 ]; then
    echo "Pause containers"
    docker pause "${@}"
  fi
}

# Do unpause all containers
unpause_containers(){
  if [ "${#}" -ne 0 ]; then
    echo "UnPause containers"
    docker unpause "${@}"
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
  (
    cd "${BORG_VOLUMES}" || return 1
    borg create \
      --verbose \
      --filter AME \
      --list \
      --stats \
      --show-rc \
      --compression lz4 \
      --exclude-caches \
      ::'{hostname}-{now}' \
      "."
  )
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

# List available backups
list_backups(){
  echo "Listing backups"
  borg list
}

# Do extract from the backup
#
# Synopsis:
# restore_backup backup_to_restore
restore_backup(){
  local backup_to_restore="${1}" && shift

  echo "Starting restore"
  (
    cd "${BORG_VOLUMES}" || return 1
    borg extract \
      --verbose \
      --list \
      --show-rc \
      ::"${backup_to_restore}"
  )
}
