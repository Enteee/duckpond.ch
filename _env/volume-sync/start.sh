#!/usr/bin/env bash
set -exuo pipefail

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Environment
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
export VOLUME_SYNC_SLEEP_TIME="${VOLUME_SYNC_SLEEP_TIME:-4h}"

# Initial sleep: wait for stack to start
echo "Initial sleep"
sleep 3m

while true; do
  echo "Backup"
  "${DIR}/backup.sh"

  echo "Sleeping"
  # Sleep
  sleep "${VOLUME_SYNC_SLEEP_TIME}"
done
