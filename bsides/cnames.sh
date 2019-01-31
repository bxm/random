#!/usr/bin/env bash

while read CNAME ; do
    host -t CNAME ${CNAME} | awk '/is an al/ {print $NF}' |
    if ! host "${CNAME}" >& /dev/null; then
      echo "${CNAME} doesn't resolve (${domain})"
    fi
  done
