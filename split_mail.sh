#!/usr/bin/env bash

trap 'kill_child_procs' INT
trap 'tidy' EXIT

get_dates() {
  echo -n "Reading message dates from ${MAIL_FILE}..."
  while read D ; do
    DATES+=("${D}")
  done < <(grep ^Date: "${MAIL_FILE}" | cut -d" " -f2- | cut -d":" -f1 | uniq)
  echo " Done (${#DATES[@]} found)"
}

generate_procmail_rc() {
  echo -n "Generating procmail script ${PROCMAIL_RC} and creating empty directory structure... "
  for DATE in "${DATES[@]}" ; do
    DIR="${OUT_DIR}/$(date -d"${DATE}:00" +%Y/%m/%d_%a/%H)"
    mkdir -p "${DIR}"
    printf ':0\n* ^Date:[ \t]*%s\n%s/.\n' \
      "${DATE}" "${DIR}"
  done > "${PROCMAIL_RC}"
  echo "Done"
}

is_foreground() {
  case $(ps -o stat= -p $$) in
    (*+*) true  ;;
    (*)   false ;;
  esac
}

count_files() {
  find "${OUT_DIR}" -type f | wc -l
}

split_status() {
  echo -ne "\rMessages processed: $(count_files)/${COUNT}"
}

split_file() {
  echo "Splitting ${MAIL_FILE} with formail in background"
  formail -s <"${MAIL_FILE}" procmail "${PROCMAIL_RC}" &

  COUNT=$(grep -c ^Date: "${MAIL_FILE}")
  while [ -n "$(jobs -rp)" ] ; do
    sleep 2
    is_foreground && split_status
  done
  split_status
  echo
}

fix_dates() {
  I=0
  TOTAL=$(count_files)
  while read line ; do
    : $((I++))
    [ $((I % 100)) -eq 0 ] && is_foreground && echo -en "Fixing file dates... ${I}/${TOTAL}\r"
    f="${line/:*}"
    d="${line/*, }"
    touch "${f}" -d"$(date -d"${d}" '+%F %T')"
  done < <(grep -R ^Date: "${OUT_DIR}"/)
  echo -e "Fixing file dates... ${I}/${TOTAL}"
}

kill_child_procs() {
  echo -e "\nCaught INT, tidying up..."
  JOBS="$(jobs -rp)"
  [ -n "${JOBS}" ] && kill ${JOBS}
  sleep 1
  exit
}

tidy() {
  echo "Removing ${PROCMAIL_RC}"
  rm -f "${PROCMAIL_RC}"
  exit
}

check_space() {
  if   [ -d "${OUT_DIR}" ] ; then
    FS_CHECK="${OUT_DIR}"
  else
    FS_CHECK="."
  fi

  FILE_SIZE=$(stat "${MAIL_FILE}" -c %s)
  FS_SPACE=$(df ${FS_CHECK} -B1 --output=avail | awk 'END{print}')
  FS_SPACE_90=$(((FS_SPACE * 90) / 100))

  [ ${FILE_SIZE} -ge ${FS_SPACE_90} ] && echo "Refusing to run due to insufficient space at destination" && return 1
  echo "Free space looks OK"

}

check_time() {
  local MINUTE="$((60 - $(date +%_M)))"
  [ "${FORCE}" = "1" ] && echo "Ignoring time lock" && return 0
  if [ "${MINUTE}" -le 15 ] ; then
    date
cat << EOF
You might want to wait a while ($((MINUTE)) minutes, specifially); race conditions and all that.

If you want to live dangerously

  FORCE=1 ${0} ${*}

Otherwise:

  sleep $((60 * (MINUTE))) && ${0} ${*}

EOF
    return 1
  fi
  return 0
}

compress_and_delete() {
  echo "Creating ${OUT_DIR}.tgz"
  tar czf "${OUT_DIR}.tgz" "${OUT_DIR}" || return 1
  rm -rf "${OUT_DIR}"
}

declare MAIL_FILE="${1:-/var/spool/mail/${USER}}"
declare OUT_DIR="${2:-mail_split_$(date +%F_%H-%M)}"
declare -a DATES=()
declare COUNT=undef
declare PROCMAIL_RC="$(mktemp /tmp/procmail_rc_XXXXX)"
declare FORCE="${FORCE:-0}"

[ -f "${MAIL_FILE}" ] || { echo "Not found: ${MAIL_FILE}" ; exit 1 ; }
# seems a bit risky, also really hard to figure out free space
grep -E "/" <<< "${OUT_DIR}" && { echo "Absolute paths/path traversal are not supported" ; exit 1 ; }

check_time "${@}" || exit 1
check_space || exit 1

echo "Source file:      ${MAIL_FILE}"
echo "Target directory: ${OUT_DIR}"

get_dates
generate_procmail_rc
split_file || exit 1
true > "${MAIL_FILE}"
fix_dates
compress_and_delete