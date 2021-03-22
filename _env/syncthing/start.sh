#!/usr/bin/env bash
set -exuo pipefail
(
  syncthing \
    -gui-address="0.0.0.0:8384"
)
