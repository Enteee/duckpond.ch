#!/usr/bin/env bash
set -exuo pipefail

CRYPTPAD_GID="${CRYPTPAD_GID:-4001}"
CRYPTPAD_UID="${CRYPTPAD_UID:-4001}"

USER_DIRS=("blob" "block" "customize" "data" "datastore")

# Always recreate user & group
if getent passwd cryptpad; then
  userdel cryptpad
fi
if getent group cryptpad; then
  groupdel cryptpad
fi

groupadd \
  cryptpad \
  --force \
  -g "${CRYPTPAD_GID}"

useradd \
  cryptpad \
  -u "${CRYPTPAD_UID}" \
  -g "${CRYPTPAD_GID}" \
  -d /cryptpad

(
  cd "/cryptpad"
  mkdir -p "${USER_DIRS[@]}"
  chown -R cryptpad:cryptpad "${USER_DIRS[@]}"
  su -g cryptpad cryptpad -c "$(which node) /cryptpad/server.js"
)
