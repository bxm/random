#!/usr/bin/env bash
#

get_tty() {
  local TTY COMM COMMAND CASE
  while read TTY COMM COMMAND; do
    if ${REGEX} ; then
      [ "${1,,}" = "${1}" ] && CASE=i || CASE=''
      grep -Eq${CASE} "${1}" <<< "${COMM}" && print_if_tty "${TTY}"
      grep -Eq${CASE} "${1}" <<< "${COMMAND}" && print_if_tty "${TTY}"
      continue
    else
      [ "${1,,}" = "${COMM,,}" ] && print_if_tty "${TTY}"
    fi
  done < <(ps -o tty=,comm=) | sort -u
}

print_if_tty() {
  [[ "${1}" =~ ^p?ttys?[0-9] ]] || return 0

  tty="/dev/${1}"
  [ -c "${tty}" ] && echo "${tty}"
  return 0
}

display_intent() {
  local SL=''
  local SEP=', '
  ${REGEX} && SEP='|' && SL='/'
  PAR="${!PARAMS[*]}"
  echo "Locating terminals running: ${SL}${PAR// /${SEP}}${SL}"
}

main() {
  declare -A PARAMS=()
  declare -A TTY_LIST=()
  declare REGEX=false
  declare LOOP=false
  while [ $# -gt 0 ] ; do
    case "${1}" in
      ( -r | --regex ) REGEX=true ;;
      ( -l | --loop  ) LOOP=true ;;
      ( *            ) PARAMS["${1}"]=1 ;;
    esac
    shift
  done

  [ ${#PARAMS[@]} -le 0 ] && PARAMS=([vim]=1 [ssh]=1)

  display_intent

  for P in "${!PARAMS[@]}" ; do
    for T in $(get_tty "${P}") ; do
      TTY_LIST[${T}]+="${TTY_LIST[${T}]:+ }${P}" # magic space ... MAGIC
    done
  done

  for TTY in "${!TTY_LIST[@]}" ; do
    echo "Notifiying ${TTY} (matched on: ${TTY_LIST[${TTY}]// /, })"
    echo -en '\007'> "${TTY}"
  done | sort

}

main "${@}"

