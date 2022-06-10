#!/bin/bash

# Prompt set variable :(message, var_name, loop_on_null, auto)
fnPromptSetVariable() {
  local res
  if [[ -z "$4" || $4 == 0  ]]; then
    read -p " $1 [${!2}]: " res
    if [[ -n "$res" ]]; then
      printf -v "$2" "%s" "$res"
    fi
  else
    echo " $1: [${!2}]"
  fi
  if [[ -z "${!2}" && -n "$3" ]]; then
    fnPromptSetVariable "$1" "$2" "$3"
  fi
}

# Prompt confirm message and return 1 on false
# :(msg, loop, auto, auto_value)
fnPromptConfirm() {
  local confirm
  if [[ -z "$3" || $3 == 0 ]]; then
    read -p "$1 (y|n) " confirm
  else
    confirm="$4"
    if [[ -z "$confirm" ]]; then
      confirm="y"
    fi
    echo "$1 $confirm"
  fi
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    if [[ -n "$2" && "$2" != 0 ]]; then
      fnPromptConfirm "$1" "$2" "$3"
    else
      return 1
    fi
  fi
}

# Helper to enter a file path (print ls on dirs)
# :(name, var_name, base_path, regex, loop_on_null, loop_on_not_found, loop_on_not_match, is_dir, auto)
fnPromptFilePath() {
  if [[ -z "$1" || -z "$2" ]]; then return 1; fi
  declare -p "$2" >/dev/null 2>&1
  if [[ $? != 0 ]]; then return 1; fi
  local var_value="${!2}"
  local msg="- File [$1] path [$var_value]"
  local base_path; base_path=$( realpath "$3" 2> /dev/null )
  local error_code result
  local run=1
  while [[ $run != 0 ]]; do
    result=""
    if [[ -n "$9" && "$9" != 0 ]]; then
      echo " ${msg}: "
    else
      read -p " $msg: " result
    fi
    msg=">"
    if [[ -z "$result" && -n "$var_value" ]]; then
      result="$var_value"
    fi
    if [[ -n "$result" ]]; then
      if [[ ! "$result" = /* ]]; then
        result=$( realpath "$base_path/$result" 2> /dev/null )
      else
        result=$( realpath "$result" 2> /dev/null )
      fi
      if [[ -d "$result" ]]; then
        if [[ -n "$8" && "$8" != 0 ]]; then
          fnPromptConfirm " # Select path [$result] ?" 1 $9
          if [[ $? == 0 ]]; then run=0; fi
        else
          ls -la "$result"
        fi
      elif [[ -f "$result" ]]; then
        echo " # File [$1] found at [$result]"
        if [[ -n $4 && "$4" != 0 && "$result" != $4 ]]; then
          echo " # File [$1] does not match [$4]"
          if [[ -n "$9" && "$9" != 0 ]]; then error_code=3; run=0; fi
          if [[ -z "$7" || "$7" == 0 ]]; then run=0; fi
        else
          run=0
        fi
      else
        echo " # File [$1] NOT found at [$result]"
        if [[ -n "$9" && "$9" != 0 ]]; then error_code=2; run=0; fi
        if [[ -z "$6" || "$6" == 0 ]]; then run=0; fi
      fi
    else
      echo " # File path is null."
      if [[ -n "$9" && "$9" != 0 ]]; then error_code=1; run=0; fi
      if [[ -z "$5" || "$5" == 0 ]]; then run=0; fi
    fi
  done

  printf -v "$2" "%s" "$result"
  return $error_code
}

