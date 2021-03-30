#!/usr/bin/env bash
set -euo pipefail

PWD="$(pwd)"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

DOCKER_COMPOSE="${DIR}/docker-compose.sh"

function usage(){
cat <<EOF
up.sh env [docker-compose-arguments]: run the blog

Options:
  -h|--help               print this help
  -v|--verbose            make verbose
  -ec|--encrypt password  encrypt all .pgp files
  -dc|--decrypt password  decrypt all .pgp files

environments:
  prod    production environment
  bprod   blog production environment
  mprod   mail production environment
  dev     devlopment envrionment

Notes:
  - "up" is the default for docker-compose-arguments
EOF
}

#
# encrypt out pw
function encrypt(){
  local out="${1}" && shift
  local pw="${1}" && shift
  local in
  in="$(basename --suffix ".gpg" "${out}")"

  if [ ! -f "${in}" ]; then
    return
  fi

  ( set +x; echo "${pw}" ) \
  | gpg \
    --batch \
    --yes \
    --symmetric \
    --passphrase-fd 0 \
    --output "${out}"\
    "${in}"
}
export -f encrypt

#
# decrypt in pw
function decrypt(){
  local in="${1}" && shift
  local pw="${1}" && shift
  local out
  out="$(basename --suffix ".gpg" "${in}")"

  if [ ! -f "${in}" ]; then
    return
  fi

  ( set +x; echo "${pw}" ) \
  | gpg \
    --decrypt \
    --batch \
    --yes \
    --passphrase-fd 0 \
    --output "${out}"\
    "${in}"
}
export -f decrypt

env_development(){
  exec "${DOCKER_COMPOSE}" \
    -f docker-compose.yml \
    -f docker-compose-dev.yml \
    "${@}"
}

env_blogproduction(){
  exec "${DOCKER_COMPOSE}" \
    -f docker-compose.yml \
    -f docker-compose-prod.yml \
    "${@}"
}

env_mailproduction(){
  exec "${DOCKER_COMPOSE}" \
    -f mailcow/docker-compose.yml \
    "${@}"
}

env_production(){
  exec "${DOCKER_COMPOSE}" \
    -f docker-compose.yml \
    -f docker-compose-prod.yml \
    -f docker-compose-mailcow.yml \
    -f mailcow/docker-compose.yml \
    "${@}"
}

verbose=false

encrypt=false
encrypt_password=""
decrypt=false
decrypt_password=""

environment=false

while [[ $# -gt 0 ]]; do
  case "${1}" in
    -v|--verbose)
      verbose=true && shift
    ;;
    -h|--help)
      usage
      exit
    ;;
    -ec|--encrypt)
      encrypt=true && shift
      encrypt_password="${1?missing password}" && shift
    ;;
    -dc|--decrypt)
      decrypt=true && shift
      decrypt_password="${1?missing password}" && shift
    ;;
    --|prod|production)
      environment="env_production" && shift
      break
    ;;
    bprod|blogproduction)
      environment="env_blogproduction" && shift
      break
    ;;
    mprod|mailproduction)
      environment="env_mailproduction" && shift
      break
    ;;
    dev|development)
      environment="env_development" && shift
      break
    ;;
    *)
      echo "Invalid argument: '${1}'" >&2
      echo >&2
      usage >&2
      exit 1
    ;;
  esac
done

if [ "${environment}" == false ]; then
  echo "Missing environment" >&2
  echo >&2
  usage >&2
  exit 1
fi

if [ "${verbose}" == true ];then
  set -x
fi

if [ "${encrypt}" == true ];then
  (
    set +x
    find \
      "${DIR}/../" \
      -type f \
      -name "*.gpg" \
      -execdir bash -$- -c 'encrypt "${1}" "${2}"' _ "{}" "${encrypt_password}" \;
  )
fi

if [ "${decrypt}" == true ];then
  (
    set +x
    find \
      "${DIR}/../" \
      -type f \
      -name "*.gpg" \
      -execdir bash -$- -c 'decrypt "${1}" "${2}"' _ "{}" "${decrypt_password}" \;
  )
fi

# Run envionrment
if [[ $# -eq 0 ]]; then
  ${environment} "up"
else
  ${environment} "${@}"
fi
