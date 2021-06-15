#!/usr/bin/env bash
set -exuo pipefail
while true; do
  (
    dehydrated \
      -c \
      --accept-terms \
      --hook /etc/dehydrated/hook.sh
  )

  echo "Sleeping"
  # Sleep
  sleep "${LETS_ENCRYPT_SLEEP_TIME}"
done
