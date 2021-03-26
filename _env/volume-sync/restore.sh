#!/usr/bin/env bash
set -exuo pipefail

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# shellcheck source=./lib.sh
source "${DIR}/lib.sh"

usage(){
  echo "usage: restore.sh backup_to_restore" >&2
}

#
# Main
#
main(){
  local containers_to_pause
  read -r -a containers_to_pause <<< "$(get_all_other_containers)"

  list_backups
  if [ "${#}" -eq 0 ]; then
    echo "Missing backup to restore"
    usage
    exit 1
  fi

  local backup_to_restore="${1}" && shift

  pause_containers "${containers_to_pause[@]}"
  init_repo
  check_repo
  chown_backup
  restore_backup "${backup_to_restore}"
  unpause_containers "${containers_to_pause[@]}"
}
main "${@}"
