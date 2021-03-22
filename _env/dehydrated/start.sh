#!/usr/bin/env bash
set -exuo pipefail
(
  dehydrated \
    -c \
    --accept-terms \
    --hook /etc/dehydrated/hook.sh
)
