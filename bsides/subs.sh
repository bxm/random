#!/usr/bin/env bash
DOMAIN="${1}"

while read SUB ; do
  FQDN="${SUB}.${DOMAIN}"
  if dig +short "${FQDN}" | grep . -q ; then
    echo "${FQDN}"
  fi
done
