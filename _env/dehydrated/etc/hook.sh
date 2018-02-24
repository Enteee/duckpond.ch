#!/usr/bin/env bash
set -ex

event="${1}" && shift

function link(){
  local from="${1}" && shift
  local name="${1}" && shift
  ln --force --symbolic \
    "${from}" \
    "$(dirname ${from})/${name}"
}

case "${event}" in
  deploy_cert)
    domain="${1}" && shift
    privkey="${1}" && shift
    cert="${1}" && shift
    fullchain="${1}" && shift
    link "${privkey}" "privkey.pem"
    link "${cert}" "cert.pem"
    link "${fullchain}" "fullchain.pem"
  ;;
  *) ;;
esac
