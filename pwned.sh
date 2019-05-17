#!/usr/bin/env bash

verdict() {
  S=s
  while true ; do
    [ "${1}" -ge 10000 ] && echo "Hahaha good one.  No, seriously -- change that." && break
    [ "${1}" -ge 1000  ] && echo "Er that's a popular one." && break
    [ "${1}" -ge 50    ] && echo "Pretty bad that." && break
    [ "${1}" -ge 10    ] && echo "Could be worse." && break
    [ "${1}" -ge 2     ] && echo "OK but not OK." && break
    [ "${1}" -eq 1     ] && echo "You NEARLY got away with that." && S='' && break
    [ "${1}" -eq 0     ] && echo "Lucky lucky!  Gold star for you!" && break
    [ "${1}" -lt 0     ] && echo "Is the site down?" && return
    break
  done
  echo -e "Pwned ${1} time${S}"
  # [ "${1}" -gt 0 ] && echo " >>${2}<<" || echo
}

api_query () {
  RESPONSE=$(curl https://api.pwnedpasswords.com/range/${1} --silent --connect-timeout 5 || echo FAIL)
  [ "${RESPONSE}" = "FAIL" ] && echo "-1" && return
  tr '\r' '\n' <<< "${RESPONSE}" | grep -i "^${2}:" || echo -n "0"
}

validate() {
  local WARN=false
  [ -z "${1}" ] && echo "FATAL: Got empty string" && return 2
  [ $(wc -l <<< "${1}") -gt 1 ] && echo "WARNING: Removing New Line(s)" && WARN=true
  grep -Eq "\r" <<< "${1}" && echo "WARNING: Removing Carriage Return(s)" && WARN=true
  grep -Eq "\t" <<< "${1}" && echo "WARNING: Removing Tab(s)" && WARN=true
  ${WARN} && return 1
  return 0
}

stream() {
  IFS_WAS="${IFS}"
  IFS=''
  # TODO: maybe we should take multiple passwords and do some looping stuff, echoing the bad passwords, as they're bad anyway
  while read LINE ; do
    echo "${LINE}"
  done
  IFS="${IFS_WAS}"
}

main() {
  local PASSWORD
  # check we aren't the subject of a pipe...
  if tty >/dev/null ; then
    if [ $# -eq 0 ] ; then
      read -s -p "Enter password: " PASSWORD
      echo
    else
      PASSWORD="${*}"
    fi
  else
    PASSWORD="$(stream)"
  fi

  validate "${PASSWORD}"

  case "$?" in
    (0) true ;;
    (1) PASSWORD="$(tr -d '[\n\r\t]' <<<"${PASSWORD}")" ;;
    (*) return 1 ;;
  esac

  SUM=$(sha1sum < <(echo -n "${PASSWORD}"))
  SUM="${SUM// *}"
  local PREFIX=${SUM:0:5}
  local SUFFIX=${SUM:5}
  echo "${PREFIX} ${SUFFIX}"

  local PWNED=$(api_query "${PREFIX}" "${SUFFIX}")
  PWNED="${PWNED//*:}"

  verdict "${PWNED}" "${PASSWORD}"
}

main "${@}"

