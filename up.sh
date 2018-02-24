#!/usr/bin/env bash
set -e

DIR=$(dirname $0)
DEVELOP=false

while getopts "dh" opt; do
  case $opt in
    d)
      DEVELOP=true
      ;;
    h)
      cat<<EOF
$0: run the blog

Options:
  -h    print this help
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

if [ $DEVELOP = true ]; then
    docker-compose up jekyll-dev nginx-http "${@}"
else
    docker-compose up "${@}"
fi
