#!/usr/bin/env bash
set -ex

event="${1}" && shift

function link(){(
  local file="${1}" && shift
  local to="${1}" && shift

  dir=$(dirname "${file}")
  from=$(basename "${file}")

  cd "${dir}"
  ln --force --symbolic \
    "${from}" "${to}"
)}

case "${event}" in
  deploy_cert|unchanged_cert)
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
