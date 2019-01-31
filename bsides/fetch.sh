#!/usr/bin/env bash

# URL="http://httpbin.org/anything"
mkdir -p out

while read URL ; do
  FILE="out/$(md5sum <<< "${URL}" | awk '{print $1}')"
  echo "${FILE} ${URL}"
  curl -vskL "${URL}" >& "${FILE}"
done
