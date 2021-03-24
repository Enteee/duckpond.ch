#!/usr/bin/env bash
set -exuo pipefail

# Ensure needed environment variables are set
export BORG_REPO="${BORG_REPO?Missing env var BORG_REPO}"
export BORG_PASSPHRASE="${BORG_PASSPHRASE?Missing env var BORG_PASSPHRASE}"
export BORG_VOLUMES="${BORG_VOLUMES?Missing env var BORG_VOLUMES}"

# Returns a list of container ids to pause
get_pause_containers(){
  docker ps \
    --filter "label=volume-sync_pause=true" \
    --format '{{.ID}}'
}


# Initialize repository if it does not exist
if ! borg info &>/dev/null; then
  echo "Init repository"
  borg init \
    --encryption repokey \
    --verbose
fi

echo "Pause containers"
# shellcheck disable=SC2046
docker pause $(get_pause_containers)

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

echo "UnPause containers"
# shellcheck disable=SC2046
docker unpause $(get_pause_containers)

echo "Check repository"
borg check \
  --verify-data

echo "Pruning repository"
borg prune \
  --list \
  --prefix '{hostname}-' \
  --show-rc \
  --keep-daily    7 \
  --keep-weekly   4 \
  --keep-monthly  6

echo "Check repository again"
borg check \
  --verify-data
