#!/usr/bin/env bash
set -exuo pipefail
pipx run \
  --system-site-packages \
  isso -c /config/isso.conf run
