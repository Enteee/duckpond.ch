#!/bin/bash
set -e

DIR=$(dirname $0)
DEVELOP=false
WATCH=false

while getopts "wdh" opt; do
  case $opt in
    d)
      DEVELOP=true
      ;;
    w)
      WATCH=true
      ;;
    h)
      cat<<EOF
$0: run the blog

Options:
  -h    print this help
  -w    watch dir & update automatically
  -d    develop mode
EOF
      exit
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
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
