#!/usr/bin/env bash

decode() {
  echo -e "${1//%/\\x}"
}

from_stdin() {
  while read ITEM ; do
    decode "${ITEM}"
  done
}

from_param() {
  for ITEM in "${@}" ; do
    decode "${ITEM}"
  done
}

main() {
  _debug -f "${@}"
  if ! tty &>/dev/null || [ $# -le 0 ]; then
    from_stdin
  else
    from_param "${@}"
  fi
}

main "${@}"

