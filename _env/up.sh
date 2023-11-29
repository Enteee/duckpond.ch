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

Environments:
  prod    production environment
  bprod   blog production environment
  mprod   mail production environment
  dev     devlopment envrionment
  noop    do not start an environment

Notes:
  - "up" is the default for docker-compose-arguments

Examples:
  - Clean start production environment:
    ./up.sh -v --decrypt PASSWORD prod up --build --force-recreate

  - Run cryptpad only:
    ./up.sh prod up cryptpad nginx-https

  - Build cryptpad:
    ./up.sh prod build cryptpad

  - Backup restore:
    1.  In .env change VOLUME_SYNC_MOUNT to rw
    2.  ./up.sh dev up syncthing
    3.  docker exec -ti duckpondch-syncthing-1 ./start.sh
    4.  Go to syncthing web ui: https://127.0.0.1:8384
    5.  Connect to sync network
    6.  Wait for full sync
    7.  Stop syncthing
    8.  ./up.sh -v dev up volume-sync
    9.  docker exec -ti duckpondch-volume-sync-1 ./restore.sh [backup-to-restore]
    10. In .env change VOLUME_SYNC_MOUNT to ro
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

env_noop(){
  :;
}

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
    -f mailcow/docker-compose.yml \
    -f docker-compose.yml \
    -f docker-compose-prod.yml \
    -f docker-compose-mailcow.yml \
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
    noop|nooperation)
      environment="env_noop" && shift
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

# Build base image
"${DOCKER_COMPOSE}" \
  -f docker-compose-base.yml \
  "build"

# Run envionrment
if [[ $# -eq 0 ]]; then
  ${environment} "up"
else
  ${environment} "${@}"
fi
