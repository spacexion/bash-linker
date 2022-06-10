#!/bin/bash

# Split a string by a string separator into an array :(str,arr_name,separator=",")
fnSplitString() {
  if [[ -z "$1" || -z "$2" ]]; then return 1; fi
  if [[ ! "$(declare -p "$2" )" =~ "declare -a" ]]; then return 1; fi
  local str="$1"
  local sep="$3"
  if [[ -z "$3" ]]; then
    sep=','
  fi
  str+="$sep"
  local arr
  # match separator and loop on the rest
  while [[ "$str" ]]; do
    arr+=( "${str%%$sep*}" )
    str="${str#*$sep}"
  done
  # set result
  eval "$2=(\"\${arr[@]}\")"
}
