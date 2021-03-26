#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
   echo "This script must be sourced"
   exit 1
fi

# Ensure needed environment variables are set
if [ -z "${BORG_REPO+x}" ]; then
  echo "Missing env var BORG_REPO" >&2
  exit 1
fi
export BORG_REPO

if [ -z "${BORG_PASSPHRASE+x}" ]; then
  echo "Missing env var BORG_PASSPHRASE" >&2
  exit 1
fi
export BORG_PASSPHRASE

if [ -z "${BORG_VOLUMES+x}" ]; then
  echo "Missing env var BORG_VOLUMES" >&2
  exit 1
fi
export BORG_VOLUMES

if [ -z "${HOSTNAME+x}" ]; then
  echo "Missing env var HOSTNAME" >&2
  exit 1
fi
export HOSTNAME

# Print the hash of all its arguments.
# This will explicitly disable debug printing.
do_hash(){
  set +x
  echo "${@}" \
  | sha256sum \
  | cut -f1 -d' '
}

# Echo's a BORG_REPO which is suffixed with the
# hash of BORG_PASSPHRASE
get_pw_sensitive_borg_repo(){
  local borg_repo_suffix
  borg_repo_suffix="$(set +x && do_hash "${BORG_PASSPHRASE}")"
  echo "${BORG_REPO}/${borg_repo_suffix}"
}

# Returns a list of container ids to pause excluding
# the container we are running in.
get_all_other_containers(){
  docker ps \
    --format '{{.ID}}' \
  | {
    grep -v "$(
      docker ps \
        --filter "id=${HOSTNAME}" \
        --format '{{.ID}}'
    )"
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
  local borg_repo
  borg_repo="$(get_pw_sensitive_borg_repo)"

  if ! borg info "${borg_repo}" &>/dev/null; then
    echo "Init repository"
    borg init \
      --encryption repokey \
      --verbose \
      "${borg_repo}"
  fi
}

# Do create the backup
create_backup(){
  local borg_repo
  borg_repo="$(get_pw_sensitive_borg_repo)"

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
      "${borg_repo}"::'{hostname}-{now}' \
      "."
  )
}

# Change owner of backup
chown_backup(){
  local borg_repo
  borg_repo="$(get_pw_sensitive_borg_repo)"

  echo "Chown Backup"
  chown \
    --recursive \
    "${SERVICE_UID}":"${SERVICE_GID}" \
    "${borg_repo}"
}

# Check and verify repository
check_repo(){
  local borg_repo
  borg_repo="$(get_pw_sensitive_borg_repo)"

  echo "Check repository"
  borg check \
    --verify-data \
    "${borg_repo}"
}

# Prune old backups
prune_repo(){
  local borg_repo
  borg_repo="$(get_pw_sensitive_borg_repo)"

  echo "Pruning repository"
  borg prune \
    --list \
    --prefix '{hostname}-' \
    --show-rc \
    --keep-daily    7 \
    --keep-weekly   4 \
    --keep-monthly  6 \
    "${borg_repo}"
}

# List available backups
list_backups(){
  local borg_repo
  borg_repo="$(get_pw_sensitive_borg_repo)"

  echo "Listing backups"
  borg list \
    "${borg_repo}"
}

# Do extract from the backup
#
# Synopsis:
# restore_backup backup_to_restore
restore_backup(){
  local backup_to_restore="${1}" && shift

  local borg_repo
  borg_repo="$(get_pw_sensitive_borg_repo)"

  echo "Starting restore"
  (
    cd "${BORG_VOLUMES}" || return 1
    borg extract \
      --verbose \
      --list \
      --show-rc \
      "${borg_repo}"::"${backup_to_restore}"
  )
}
