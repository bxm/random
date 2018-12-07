#!/usr/bin/env bash
#
rot13() {
  ${FLAG[${FUNCNAME[0]}]} && tr "[a-z][A-Z]" "[n-za-m][N-ZA-M]" || cat
}

invcase() {
  ${FLAG[${FUNCNAME[0]}]} && tr "[a-z][A-Z]" "[A-Z][a-z]" || cat
}

numerics() {
  ${FLAG[${FUNCNAME[0]}]} && tr "[0-9][{}()'\"#|/=]" "[{}()'\"#|/=][0-9]" || cat
}

punctuation() {
  ${FLAG[${FUNCNAME[0]}]} && tr "[\!\@\$\&\*\_\+\-\:\<\>\,\.\?\`\~]" "[\:\<\>\,\.\?\`\~\!\@\$\&\*\_\+\-]" || cat
}

tricky() {
  ${FLAG[${FUNCNAME[0]}]} && tr "[\\\\\^]" "[\^\\\\]" || cat
}

collapse_space() { # destructive
  ${FLAG[${FUNCNAME[0]}]} && sed -r 's/^\s+//' || cat
}

linewrap() {
  ${FLAG[${FUNCNAME[0]}]} && tr "[\n][;]" "[;][\n]" || cat
}

obf() {
  rot13 | invcase | numerics | punctuation | tricky | collapse_space | linewrap
}

main() {
  declare -A FLAG=([rot13]= [invcase]= [numerics]= [punctuation]= [tricky]= [collapse_space]= [linewrap]=)

  for ITEM in "${!FLAG[@]}" ; do
    FLAG[${ITEM}]=true
  done

  while [ $# -gt 0 ] ; do
    case "${1}" in
      ( --no-* ) [ -n "${FLAG[${1#--no-}]}" ] && FLAG[${1#--no-}]=false ;;
      ( --* )    : ;; # ignore any malformed items
      ( -[A-Z])  PARAM="${1#-}" ; PARAM="${PARAM,,}" ; SET_FLAG="$(grep -oE "(^| )${PARAM}[^ ]+( |$)" <<< "${!FLAG[@]}" | tr -d ' ')"
                 [ -n "${SET_FLAG}" ] && FLAG[${SET_FLAG}]=false
                 ;;
    esac
    shift
  done

  cat | obf
}

main "${@}"

