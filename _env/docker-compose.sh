#!/usr/bin/env bash
# Docker compose wrapper with submodule support
# Reads all docker-compose.yaml files given with -f / --files and compiles one
# big docker-compose.yaml file before running docker-compose.
#
# This is useful when you have nested docker-compose subprojects in different
# folders which contain relative paths.
# see: https://github.com/docker/compose/issues/3874
#
# Requires:
#  - sponge (from moreutils https://joeyh.name/code/moreutils/)
#  - docker & docker-compose
#
set -euo pipefail

PWD="$(pwd)"
TMP_FILE="${PWD}/docker-compose-generated.$$.yaml"
ENV_FILE="$(readlink -f "${ENV_FILE:-.env}")"

DOCKER_COMPOSE_CMD=("docker" "compose" "--env-file" "${ENV_FILE}")

finish() {
  rm "${TMP_FILE}" 2>/dev/null
}

trap finish EXIT

compose-config() {
  local new_file="${1}" && shift
  local new_file_dir
  new_file_dir="$(dirname "${new_file}")"
  "${DOCKER_COMPOSE_CMD[@]}" \
    --project-directory "${new_file_dir}" \
    --file "${TMP_FILE}" \
    --file "${new_file}" \
    config \
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

touch "${TMP_FILE}"
for f in "${files[@]}"; do
  compose-config "${f}"
done

# Note: do not exec here, otherwise the cleanup trap wont run
"${DOCKER_COMPOSE_CMD[@]}" -f "${TMP_FILE}" "${args[@]}"
