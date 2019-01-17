#!/usr/bin/env bash

verdict() {
  S=s
  while true ; do
    [ "${1}" -ge 1000 ] && echo "Er that's a popular one." && break
    [ "${1}" -ge 50   ] && echo "Pretty bad that." && break
    [ "${1}" -ge 10   ] && echo "Could be worse." && break
    [ "${1}" -ge 2    ] && echo "OK but not OK." && break
    [ "${1}" -eq 1    ] && echo "You NEARLY got away with that." && S='' && break
    [ "${1}" -eq 0    ] && echo "Lucky lucky!  Gold star for you!" && break
    [ "${1}" -lt 0    ] && echo "Is the site down?" && return
    break
  done
  echo -e "Pwned ${1} time${S}"
}

api_query () {
  RESPONSE=$(curl https://api.pwnedpasswords.com/range/${1} --silent --connect-timeout 5 || echo FAIL)
  [ "${RESPONSE}" = "FAIL" ] && echo "-1" && return
  tr '\r' '\n' <<< "${RESPONSE}" | grep -i "^${2}:" || echo -n "0"
}

main() {
  SUM=$(sha1sum < <(echo -n "${*}"))
  SUM="${SUM// *}"
  local PREFIX=${SUM:0:5}
  local SUFFIX=${SUM:5}

  local PWNED=$(api_query "${PREFIX}" "${SUFFIX}")
  PWNED="${PWNED//*:}"

  verdict "${PWNED}"
}

main "${@}"

