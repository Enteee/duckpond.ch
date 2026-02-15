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

# Echo a space-separated list of container IDs to pause, excluding:
# - the container we are running in
# - containers already paused
# - containers that do NOT have any read-write bind/volume mount
get_all_other_unpaused_containers() {
  local self_id
  local -a ids

  self_id="$(
    docker ps \
      --filter "id=${HOSTNAME}" \
      --format '{{.ID}}' \
    | head \
        --lines 1
  )"

  readarray -t ids < <(
    docker ps \
      --filter 'status=running' \
      --format '{{.ID}}' \
    | while read -r id; do
        if [ -n "$self_id" ] && [ "$id" = "$self_id" ]; then
          continue
        fi
        printf '%s\n' "$id"
      done
  )

  if [ "${#ids[@]}" -eq 0 ]; then
    return 0
  fi

  docker inspect \
    "${ids[@]}" \
    --format '{{.Id}} {{range .Mounts}}{{.Type}}:{{.RW}};{{end}}' \
  | awk '
      /(bind|volume):true/ {
        print substr($1, 1, 12)
      }
    ' \
  | tr '\n' ' '
}

# Do pause all containers
pause_containers(){
  if [ "${#}" -ne 0 ]; then
    docker pause "${@}"
  fi
}

# Do unpause all containers
unpause_containers(){
  if [ "${#}" -ne 0 ]; then
    docker unpause "${@}"
  fi
}

# Initialize repository if it does not exist
init_repo(){
  local borg_repo
  borg_repo="$(get_pw_sensitive_borg_repo)"

  # Create a .stfolder - folder in BORG_REPO
  # This enables the folder to be shared in
  # syncthing, even if syncthing has just ro
  # access.
  # Note that we use BORG_REPO here and not
  # borg_repo. This is so that we can share
  # all pw dependant repositories at once.
  mkdir -p "${BORG_REPO}/.stfolder"

  if ! borg info "${borg_repo}" &>/dev/null; then
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

  # Note: we chown BORG_BACKUP here,
  # because we also want to chown possible
  # meta-folder in BORG_BACKUP (i.e. .stfolder)
  chown \
    --recursive \
    "${SERVICE_UID}":"${SERVICE_GID}" \
    "${BORG_REPO}"
}

# Check and verify repository
check_repo(){
  local borg_repo
  borg_repo="$(get_pw_sensitive_borg_repo)"

  borg check \
    --verify-data \
    "${borg_repo}"
}

# Prune old backups
prune_repo(){
  local borg_repo
  borg_repo="$(get_pw_sensitive_borg_repo)"

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

  borg list \
    "${borg_repo}"
}

# Create list of backups
create_backup_list(){
  list_backups > "${BORG_REPO}/backup-list.txt"
}

# Do extract from the backup
#
# Synopsis:
# restore_backup backup_to_restore
restore_backup(){
  local backup_to_restore="${1}" && shift

  local borg_repo
  borg_repo="$(get_pw_sensitive_borg_repo)"

  (
    cd "${BORG_VOLUMES}" || return 1
    borg extract \
      --verbose \
      --list \
      --show-rc \
      "${borg_repo}"::"${backup_to_restore}"
  )
}
