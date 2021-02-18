#!/usr/bin/env bash
# Docker compose wrapper with submodule support
# Reads all docker-compose.yaml files given with -f / --files and compiles one
# big docker-compose.yaml file before running docker-compose.
#
# This is useful when you have nested docker-compose subprojects in different
# folders which contain relative paths.
# see: https://github.com/docker/compose/issues/3874
#
# Environment:
#  - DOCKER_COMPOSE_CONFIG_VERSION: The docker-compose,yaml config file version, default: 2.1
#
# Requires:
#  - sponge (from moreutils https://joeyh.name/code/moreutils/)
#  - docker & docker-compose
#
set -euo pipefail

PWD="$(pwd)"
TMP_FILE="${PWD}/docker-compose-generated.$$.yaml"
DOCKER_COMPOSE_CONFIG_VERSION="${DOCKER_COMPOSE_CONFIG_VERSION:-2.1}"
ENV_FILE="$(readlink -f "${ENV_FILE:-.env}")"

DOCKER_COMPOSE_CMD="docker-compose --env-file ${ENV_FILE}"

finish() {
  rm "${TMP_FILE}" 2>/dev/null
}

trap finish EXIT

compose-config() {
  local dir="$(dirname "${1}")"
  local file="$(basename "${1}")"
  ${DOCKER_COMPOSE_CMD} -f "${1}" -f "${TMP_FILE}" config \
  | sponge "${TMP_FILE}"
}

args=()
files=()
verbose=false

while [[ $# -gt 0 ]]; do
  case "${1}" in
    -f|--file)
      shift
      files+=("${1}") && shift
    ;;
    --verbose)
      verbose=true
      args+=("${1}") && shift
    ;;
    *)
      args+=("${1}") && shift
    ;;
  esac
done

if [ "${verbose}" == true ]; then
  set -x
fi

echo "version: \"${DOCKER_COMPOSE_CONFIG_VERSION}\"" > ${TMP_FILE}
for f in ${files[@]}; do
  compose-config "${f}"
done

exec ${DOCKER_COMPOSE_CMD} -f "${TMP_FILE}" ${args[@]}
