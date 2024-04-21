#!/usr/bin/env bash
set -exuo pipefail
pipx run \
  isso -c /config/isso.conf run
