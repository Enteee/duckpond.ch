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
# Containers paused by this run. Global (not a `main` local) so the EXIT trap
# can always see it, whatever point we bail out from.
containers_to_pause=()

main(){
  read -r -a containers_to_pause <<< "$(get_all_other_unpaused_containers)"

  # Always unpause, even if a step below fails. Without this, `set -e` aborts
  # between pause_containers and unpause_containers and leaves the whole stack
  # paused indefinitely -- e.g. a stale borg lock makes init_repo exit 2, and
  # every later run then fails the same way with the containers still paused.
  trap 'unpause_containers "${containers_to_pause[@]}"' EXIT INT TERM

  pause_containers "${containers_to_pause[@]}"
  init_repo
  create_backup
  check_repo
  prune_repo
  create_backup_list
  chown_backup
}
main
