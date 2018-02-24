#!/usr/bin/env bash
set -x

event="${1}" && shift

case "${event}" in
  deploy_cert|unchanged_cert)
    domain="${1}" && shift
    privkey="${1}" && shift
    cert="${1}" && shift
    fullchain="${1}" && shift
  ;;
  *) ;;
esac
