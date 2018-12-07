#!/usr/bin/env bash

action() {
  : $((LAYER++))
  if [ ${LAYER} -le ${LAYERS} ] ; then
    if ${WRAP} ; then
      gzip -c - 2>/dev/null | base64 -w0 2>/dev/null | action || return 1
    else
      base64 -i -d 2>/dev/null | gunzip -c - 2>/dev/null | action || return 1
    fi
    return 0
  else
    cat
    echo >&2
  fi

}

usage() {

cat << EOF >&2
Usage: ${0} [-u|--unwrap] [-l|--layers <INT>] [-q|--quiet]

Add arbitrary number of gzip / base64 layers to input
... for no good reason.

Provide input via pipeline/redirection methods, or in-line (ending with ^D)

EOF
exit 0

}

main() {
  set -o pipefail
  WRAP=true
  LAYER=0
  LAYERS=10
  STUPID=false
  QUIET=false

  while [ $# -gt 0 ] ; do
    case "${1}" in
      ( -u | --unwrap ) WRAP=false ;;
      ( -s | --stupid ) STUPID=true ;;
      ( -l | --layers ) LAYERS="${2}" ;;
      ( -q | --quiet  ) QUIET=true ;;
      ( -h | --help   ) usage ;;
    esac
    shift
  done

  ! ${STUPID} && [ "${LAYERS}" -gt 100 ] && echo "${LAYERS} layers? That's just stupid (use --stupid if you really are that stupid)" >&2 && return 1

  action || return

  ! ${QUIET} && echo -e "\n${LAYERS} layer(s) deep" >&2
}

main "${@}"

