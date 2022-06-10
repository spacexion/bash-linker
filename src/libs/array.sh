#!/bin/bash


# Read array, search regexes and replaces on matches
# :(input_arr_name,regexes_arr_name,replaces_arr_name,log)
fnArrayParseReplace() {
  if [[ -z "$1" || -z "$2" || -z "$3" ]]; then return 1; fi
  if [[ ! "$( declare -p "$1" )" =~ "declare -a" ]]; then return 1; fi
  if [[ ! "$( declare -p "$2" )" =~ "declare -a" ]]; then return 1; fi
  if [[ ! "$( declare -p "$3" )" =~ "declare -a" ]]; then return 1; fi
  local in_arr; eval "in_arr=(\"\${${1}[@]}\")"
  local reg_arr; eval "reg_arr=(\"\${${2}[@]}\")"
  local repl_arr; eval "repl_arr=(\"\${${3}[@]}\")"
  local i j line last rematches replace
  # if regexes and replaces arrays not empty
  if [[ "${#reg_arr[@]}" -gt 0 && "${#reg_arr[@]}" == "${#repl_arr[@]}" ]]; then
    # loop input array
    for ((i=0; i<${#in_arr[@]}; i++)); do
      line="${in_arr[$i]}"
      last="$line"
      # loop regexes
      for ((j=0; j<${#reg_arr[@]}; j++)); do
        replace="${repl_arr[$j]}"
        # loop while regex matches (multiple matches on one line)
        while [[ "$line" =~ ^(.*?)(${reg_arr[$j]})(.*?)$ ]]; do
          rematches="${#BASH_REMATCH[@]}"
          if [[ -n "$replace" ]]; then
            line="${BASH_REMATCH[1]}${replace}${BASH_REMATCH[$((rematches-1))]}"
            in_arr[$i]="$line"
            if [[ -n $4 && "$4" != 0 ]]; then
              echo " # Match [${reg_arr[$j]}] line [$i]: [$line]"
            fi
          fi
          if [[ "$last" == "$line" ]]; then break; fi # needed if no changes
          last="$line"
        done
      done
    done
  fi
  
  # set output array result
  eval "$1=(\"\${in_arr[@]}\")"
}
