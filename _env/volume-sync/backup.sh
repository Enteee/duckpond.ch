#!/usr/bin/env bash
set -exuo pipefail

if [[ $EUID -eq 0 ]]; then
   echo "This script must not be run as root"
   exit 1
fi

# Ensure needed environment variables are set
export BORG_REPO="${BORG_REPO?Missing env var BORG_REPO}"
export BORG_PASSPHRASE="${BORG_PASSPHRASE?Missing env var BORG_PASSPHRASE}"
export BORG_VOLUMES="${BORG_VOLUMES?Missing env var BORG_VOLUMES}"

# Initialize repository if it does not exist
if ! borg info &>/dev/null; then
  echo "Init repository"
  borg init \
    --encryption repokey \
    --verbose
fi

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
