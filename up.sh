#!/bin/bash
set -e

DIR=$(dirname $0)
DEVELOP=false
WATCH=false

while getopts "wd" opt; do
  case $opt in
    d)
      DEVELOP=true
      ;;
    w)
      WATCH=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

pushd "${DIR}"

if [ $WATCH = true ]; then 
  if [ $DEVELOP = true ]; then
    docker-compose up nginx-http jekyll &
  else
    docker-compose up &
  fi
  while inotifywait -q -e modify -r "${DIR}"; do (docker-compose up jekyll &); done
else
  if [ $DEVELOP = true ]; then
    docker-compose up nginx-http jekyll
  else
    docker-compose up
  fi
fi

docker-compose down
