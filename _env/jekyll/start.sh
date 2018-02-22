#!/usr/bin/env bash
set -ex
SRC="/src/"

TMP_WWW="/tmp/www"

OUT_WWW_DEV="/www-dev"
OUT_WWW="/www"

# copy to writable location
cp -r "${SRC}" "${TMP_WWW}"

chown -R jekyll:jekyll "${OUT_WWW_DEV}"
jekyll build --drafts -s "${TMP_WWW}" -d "${OUT_WWW_DEV}"

chown -R jekyll:jekyll "${OUT_WWW}"
jekyll build -s "${TMP_WWW}" -d "${OUT_WWW}"

