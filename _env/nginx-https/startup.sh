#!/bin/bash
set -e
cmd="$@"

echo "CMD: $cmd"

CERT="/certs/duckpond.ch/cert.pem"
KEY="/certs/duckpond.ch/privkey.pem"
ISSO="isso"

until stat ${CERT} ${KEY} && ping -c1 ${ISSO}; do
  >&2 echo "sleeping"
  sleep 1
done

>&2 echo "ready"
nginx -g 'daemon off;'
