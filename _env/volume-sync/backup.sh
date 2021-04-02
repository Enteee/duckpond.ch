#!/usr/bin/env bash
set -exuo pipefail

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# shellcheck source=./lib.sh
source "${DIR}/lib.sh"

#
# Main
#
main(){
  local containers_to_pause
  read -r -a containers_to_pause <<< "$(get_all_other_unpaused_containers)"

  pause_containers "${containers_to_pause[@]}"
  init_repo
  create_backup
  check_repo
  prune_repo
  timestamp_backup
  chown_backup
  unpause_containers "${containers_to_pause[@]}"
}
main
