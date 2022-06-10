#!/bin/bash

# Return elapsed time in ms (call it and get result, make your task, then call result as var) :(timestamp)
fnElapsedTime() {
  local start end
  if [[ -z "$1" ]]; then
    date +%s%3N
    return
  fi
  start="$1"
  end="$( date +%s%3N )"
  echo "$(( end - start ))"
}

# Format a ms duration string to 00h00m00s000ms :(str, keep_zeros)
fnFormatMsDuration() {
  if [[ -z "$1" ]]; then
    if [[ -n "$2" ]]; then
      echo "00h00m00s000ms"
    fi
    return
  fi
  local time="$1"
  local r=(1000 60 60 60)
  local c=('ms' 's' 'm' 'h')
  local val ri diff str
  local i=0
  while [[ $time != 0 ]]; do
    ri=${r[$i]}
    if [[ $i -ge ${#r[@]} || $time -lt $ri ]]; then
      val="$time"
      time=0
    else
      val=$(( time % ri ))
      time=$(( (time-val) / ri ))
    fi
    if [[ -n "$2" ]]; then
      ri=$(( ${r[$i]} - 1 ))
      diff=$(( ${#ri} - ${#val} ))
      for (( j=0; j<diff; j++ )); do
        val="0${val}"
      done
    fi
    str="${val}${c[$i]}${str}"
    i=$((i+1))
  done
  
  echo "$str"
}