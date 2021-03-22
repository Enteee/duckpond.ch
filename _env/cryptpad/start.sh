#!/usr/bin/env bash
set -exuo pipefail
(
  cd "/cryptpad"
  node /cryptpad/server.js
)
