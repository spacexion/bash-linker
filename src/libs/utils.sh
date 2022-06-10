#!/bin/bash

# Check if function exists
# :(name)
fnCheckFn() {
  declare -F "$1" > /dev/null
  return $?
}

# Return a rand alpha numeric uid-type string of given length, default to 8
# :(length,no_uppercase,no_lowercase,no_number)
fnGenUid() {
  local length="$1"
  if [[ -z "$length" ]]; then
    length=8
  fi
  local chars=()
  if [[ -z "$2" || "$2" == 0 ]]; then chars+=("ABCDEFGHIJKLMNOPQRSTUVWXYZ"); fi
  if [[ -z "$3" || "$3" == 0 ]]; then chars+=("abcdefghijklmnopqrstuvwxyz"); fi
  if [[ -z "$4" || "$4" == 0 ]]; then chars+=("0123456789"); fi
  local size="${#chars[@]}"
  local uid rand1 rand2 str
  for (( i=0; i<length; i++ )); do
    rand1=$(( RANDOM % size ))
    str="${chars[$rand1]}"
    rand2=$(( RANDOM % ${#str} ))
    uid+="${str:$rand2:1}"
  done
  echo "$uid"
}