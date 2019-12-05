#!/usr/bin/env bash
#

get_tty() {
  local TTY COMM COMMAND CASE
  while read TTY COMM COMMAND; do
    if ${REGEX} ; then
      [ "${1,,}" = "${1}" ] && CASE=i || CASE=''
      # FIXME: this is slow, can we do with [[ =~ ]] ?
      grep -Eq${CASE} "${1}" <<< "${COMM}" && print_if_tty "${TTY}" && continue
      grep -Eq${CASE} "${1}" <<< "${COMMAND}" && print_if_tty "${TTY}" && continue
    else
      [ "${1,,}" = "${COMM,,}" ] && print_if_tty "${TTY}"
    fi
  done < <(ps -o "tty=,comm=,command=") | sort -u
}

print_if_tty() {
  local tty
  [[ "${1}" =~ ^p?ttys?[0-9] ]] || return 1

  tty="/dev/${1}"
  [ -c "${tty}" ] && echo "${tty}"
  return 0
}

display_intent() {
  local SL=''
  local SEP=', '
  local PAR="${!PARAMS[*]}"
  ${REGEX} && SEP='|' && SL='/'
  echo "Locating terminals running: ${SL}${PAR// /${SEP}}${SL}"
}

usage() {
cat << EOF

Usage: ${0##*/} [options] [search terms]

Locate running proceses matching the search terms and send a BEL to their tty
Processes not running on a tty will be ignored.
By default, the search terms are exact matches on running commands (not their params).
Without any search terms, defaults to "vim" and "ssh" (because that's useful to me)

  +[TERM]       given terms will be appended to defaults (instead of replacing)
  -q | --quiet  do not notify
  -r | --regex  all search terms are regex and will match against the full command

  -h | --help   this

EOF
exit
}

set_defaults() {
  if [ "${#PARAMS[@]}" -gt 0 ] && ! ${APPEND} ; then
    DEFAULTS=()
  fi

  for ITEM in "${DEFAULTS[@]}" ; do
    PARAMS["${ITEM}"]=1
  done
}

main() {
  declare -A PARAMS=()
  declare -A TTY_LIST=()
  declare REGEX=false
  declare APPEND=false
  declare QUIET=false
  declare -a DEFAULTS=(vim ssh)
  while [ $# -gt 0 ] ; do
    case "${1}" in
      ( -h | --help  ) usage ;;
      ( -q | --quiet ) QUIET=true ;;
      ( -r | --regex ) REGEX=true ;;
      ( +  ) APPEND=true ;;
      ( +* ) APPEND=true ; PARAMS["${1#+}"]=1 ;;
      ( *  ) PARAMS["${1}"]=1 ;;
    esac
    shift
  done

  set_defaults
  display_intent

  for P in "${!PARAMS[@]}" ; do
    for T in $(get_tty "${P}") ; do
      TTY_LIST[${T}]+="${TTY_LIST[${T}]:+ }${P}" # magic space ... MAGIC
    done
  done

  THIS_TTY="$(tty)"
  for TTY in "${!TTY_LIST[@]}" ; do
    echo -n "Found ${TTY} (matched on: ${TTY_LIST[${TTY}]// /, })"
    if [ "${THIS_TTY}" = "${TTY}" ] ; then
      echo " **this TTY**"
    else
      echo
      ! ${QUIET} && echo -en '\007'> "${TTY}"
    fi
  done | sort

}

main "${@}"

