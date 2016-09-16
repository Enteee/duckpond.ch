#!/bin/bash
set -e
SRC="/src/"

TMP_WWW_DEV="/tmp/www-dev"
TMP_WWW="/tmp/www"

OUT_WWW_DEV="/www-dev"
OUT_WWW="/www"

# build www-dev
cp -r "${SRC}" "${TMP_WWW_DEV}"
chown jekyll:jekyll "${OUT_WWW_DEV}"
jekyll build --drafts -s "${TMP_WWW_DEV}" -d "${OUT_WWW_DEV}"
rm -rf "${TMP_WWW_DEV}"


#build www
git clone "${SRC}" "${TMP_WWW}"
chown jekyll:jekyll "${OUT_WWW}"
jekyll build -s "${TMP_WWW}" -d "${OUT_WWW}"
rm -rf "${TMP_WWW}"
