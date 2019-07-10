#!/usr/bin/env bash
set -euo pipefail
set -x

PWD="$(pwd)"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

DOCKER_COMPOSE="${DIR}/docker-compose.sh"

function usage(){
cat <<EOF
up.sh: run the blog

Options:
  -h|--help       print this help
  -d|--develop    develop mode
EOF
}

function decrypt(){
  local in="${1}" && shift
  local pw="${1}" && shift
  local out="$(basename --suffix ".gpg" "${in}")"

  echo "${pw}" \
  | gpg \
    --decrypt \
    --batch \
    --yes \
    --passphrase-fd 0 \
    --output "${out}"\
    "${in}"
}

function encrypt(){
  local in="${1}" && shift
  local pw="${1}" && shift
  local out="${in}.gpg"
  echo "${pw}" \
  | gpg \
    --batch \
    --yes \
    --symmetric \
    --passphrase-fd 0 \
    --output "${out}"\
    "${in}"
}

develop=false
encrypt=false
encrypt_password=""
decrypt=false
decrypt_password=""

while [[ $# -gt 0 ]]; do
  case "${1}" in
    -d|--develop)
      DEVELOP=true && shift
      ;;
    -h|--help)
      usage
      exit
      ;;
    -ec|--encrypt)
      encrypt=true && shift
      encrypt_password="${1}" && shift
      ;;
    -dc|--decrypt)
      decrypt=true && shift
      decrypt_password="${1}" && shift
      ;;
    ?)
      echo "Invalid argument: '${1}'" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [ "${encrypt}" == true ];then
  find
    "${DIR}" \
    --name "*.gpg" \
    --type f \
    --execdir encrypt "{}" "${encrypt_password}" \;
fi


if [ $DEVELOP = true ]; then
    exec "${DOCKER_COMPOSE}" \
      -f docker-compose.yml \
      -f docker-compose-dev.yml \
      -f _env/mailcow/docker-compose.yml \
      --verbose \
      up
fi

exec "${DOCKER_COMPOSE}" \
  -f docker-compose.yml \
  -f docker-compose-prod.yml \
  up
