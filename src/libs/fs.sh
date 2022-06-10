#!/bin/bash


# Print absolute path from provided path and base path :(path,base_path)
fnGetAbsPath() {
  if [[ -z "$1" ]]; then return 1; fi
  local res
  if [[ ! "$1" = /* && -n "$2" ]]; then
    res=$( realpath "$2/$1" 2> /dev/null )
    if [[ $? != 0 ]]; then
      res="$2/$1"
    fi
  else
    res=$( realpath "$1" 2> /dev/null )
    if [[ $? != 0 ]]; then
      res="$1"
    fi
  fi
  echo "$res"
}

# Read files and append lines in array :(file_path,arr_name)
fnFileToArray() {
  if [[ -z "$1" || -z "$2" ]]; then return 1; fi
  if [[ ! -f "$1" ]]; then return 1; fi
  if [[ ! "$( declare -p "$2" )" =~ "declare -a" ]]; then return 1; fi
  local line
  # read file lines
  while IFS= read -r line || [ -n "$line" ]; do
    eval "$2+=(\"\$line\")"
  done < "$1"
  eval "$2+=(\"\")"
}

# Read array and write each element per line in a file
# :(arr_name,file_path)
fnArrayToFile() {
  if [[ -z "$1" || -z "$2" ]]; then return 1; fi
  if [[ ! "$( declare -p "$1" )" =~ "declare -a" ]]; then return 1; fi
  if [[ -f "$2" ]]; then echo -n "" > "$2"; fi
  local arr; eval "arr=(\"\${$1[@]}\")"
  local i line
  for ((i=0; i<"${#arr[@]}"; i++)) do
    line="${arr[$i]}"
    if [[ $i != "$((${#arr[@]}-1))" || -n "$line" ]]; then
      echo "$line" >> "$2" 
    fi
  done
}

# Search and print a multi line function from a file lines array
# :(func_name,keep_doc,file_arr_name,res_arr_name)
fnFileArrayExtractFunction() {
  if [[ -z "$1" || -z "$3" || -z "$4" ]]; then return 1; fi
  if [[ ! "$(declare -p "$3" )" =~ "declare -a" ]]; then return 1; fi
  local keep_doc="$2"
  local arr line line2 indent indent2 tmp i j
  eval "arr=(\"\${$3[@]}\")"
  local res=()
  local s="[:space:]"
  # loop file lines
  for ((i=0; i<"${#arr[@]}"; i++)) do
    line="${arr[$i]}"
    # match function start 'fn_name() {'
    if [[ "$line" =~ ^([$s]*?)$1\(\)[$s]*\{ ]]; then
      indent=${#BASH_REMATCH[1]}
      if [[ -n "$keep_doc" ]]; then
        tmp=()
        # loop prev lines searching comments
        for ((j=i-1; j>=0; j--)) do
          line2="${arr[$j]}"
          if [[ "$line2" =~ ^([$s]*?)\#(.*?) ]]; then
            tmp+=("$line2")
          fi
          if [[ "$line2" =~ ^([$s]*?)\}([$s]*?)$ || -z "$line2" ]]; then break; fi
        done
        # invert result comments
        for ((j=${#tmp[@]}-1; j>=0; j--)) do
          res+=("${tmp[$j]}")
        done
      fi
      res+=("$line")
      # loop next lines searching function end
      for ((j=i+1; j<"${#arr[@]}"; j++)) do
        line2="${arr[$j]}"
        res+=("$line2")
        # match function end '}'
        if [[ "$line2" =~ ^([$s]*?)\}([$s]*?)$ ]]; then
          indent2=${#BASH_REMATCH[1]}
          if [[ "$indent" == "$indent2" ]]; then
            break
          fi
        fi
      done
      break
    fi
  done
  # set result
  eval "$4=(\"\${res[@]}\")"
}
