#!/usr/bin/env nix-shell
#!nix-shell -i bash -p bubblewrap firefox
#shellcheck shell=bash
#
# This script provides a way to locally test the infra with firefox
# all known domains will be resolve to localhost
#
set -exuo pipefail

PWD="$(pwd)"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

DOMAINS_FILE="${DIR}/dehydrated/etc/domains.txt"
readarray -t -d' ' DOMAINS < "${DOMAINS_FILE}"
TMP_HOSTS="$(mktemp)"
FIREFOX="$(realpath "$(which "firefox")")"

do_exit(){
  rm -rf "${TMP_HOSTS}"
}
trap do_exit EXIT

# Create fake hosts file
cat > "${TMP_HOSTS}" <<EOF
127.0.0.1 localhost
::1 localhost
EOF
# add all domains
for d in "${DOMAINS[@]}"; do
  echo "127.0.0.1 ${d}" >> "${TMP_HOSTS}"
  echo "::1 ${d}" >> "${TMP_HOSTS}"
done

bwrap \
  --dev-bind /dev /dev \
  --ro-bind /nix /nix \
  --dir /run/user/"$(id -u)" \
  --ro-bind /etc/ssl /etc/ssl \
  --ro-bind /etc/static /etc/static \
  --ro-bind "${TMP_HOSTS}" "/etc/hosts" \
  --tmpfs "${HOME}" \
  --ro-bind "$HOME/.Xauthority" "$HOME/.Xauthority" \
  --proc /proc \
  --tmpfs /tmp \
  --unshare-all \
  --share-net \
  --die-with-parent \
  "${FIREFOX}" \
    --new-instance \
    "${DOMAINS[@]}"

