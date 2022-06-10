#!/bin/bash
# Xion's Bash Linker
#
# Reads a bash script file searching for 'source %file%' imports annotated by '# shellcheck source=%file%'"
# and optionally '# functions=%fn1%,%fn2%...', replaces matched lines with corresponding file content,"
# and if no errors occurred, outputs the result to target file or dir."
# If no imports specified, the whole file content is inserted.
#
# Usage: Juste execute the script and follow instructions or (--help for more)
VERSION="0.7.1"

BUILD="" #%BUILD% auto-generated upon build
BUILD_TIME="" #%BUILD_TIME% auto-generated upon build

# Parameters
# -----------------------------------------------------------------------------

# Linker source/target parameters
SRC_FILE_PATH= # the source file to link imports
SRC_FILE_NAME= # auto-provisioned
SRC_FILE_DIR_PATH= # auto-provisioned
TARGET_FILE_PATH= # auto-provisioned
TARGET_FILE_NAME= # the target filename, auto-set to source filename if undefined
TARGET_FILE_DIR_PATH= # the directory path in which the target file is written

# Linker pre/post regex/replaces arrays
PRE_REGEXES=()
PRE_REPLACES=()
POST_REGEXES=()
POST_REPLACES=()

# auto parameters
TARGET_OVERWRITE= # set to 1 (or pass -o in arg) to enable overwriting of the target file if it already exists
TARGET_MKDIRS= # set to 1 (or pass -m in arg) to enable creating of target directory if it not exists
SILENT= # set to 1 (or pass -s in arg) to disable prompts and use passed arguments as parameters

# other parameters
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )" # true script dir
USER_ID="$( id -u )" # value is 0 if root
REGEXES_LIST_SEPARATOR="," # separator in lists of regexes and replaces, can be changed if ',' conflicts with a regex
ERROR_CODE= # auto-provisioned

# Functions
# -----------------------------------------------------------------------------

fnMain() {
  # handle function args
  fnHandleArgs "$@"
  if [[ $? != 0 ]]; then return 1; fi

  # print head 
  if [[ -z "$SILENT" || "$SILENT" == 0 ]]; then
    fnPrintHead
  fi
  
  # check script executed as root
  if [[ "$USER_ID" == 0 ]]; then
    echo -e "\n # \e[4m\e[1mWarning:\e[0m The Script is running as \e[4m\e[1mRoot\e[0m !\n"
  fi
  
  # prompt user
  if [[ -z "$SILENT" || "$SILENT" == 0 ]]; then
    fnPromptSourceFilePath
    if [[ $? != 0 ]]; then return 1; fi
    fnPromptTargetDirPath
    if [[ $? != 0 ]]; then return 1; fi
    SRC_FILE_NAME=$( basename "$SRC_FILE_PATH" 2> /dev/null )
    fnPromptConfirm " - Rename source file [$SRC_FILE_NAME] ?"
    if [[ $? == 0 ]]; then
      fnPromptTargetFileName
    fi
    if [[ -z "$TARGET_OVERWRITE" ]]; then
      fnPromptTargetOverwrite
    fi
    if [[ -z "$TARGET_MKDIRS" ]]; then
      fnPromptCanMkdirs
    fi
  fi
  
  # Check variables
  if [[ -z "$SRC_FILE_PATH" ]]; then
    echo " # Source file is undefined !"
    return 1
  fi
  
  SRC_FILE_PATH=$( fnGetAbsPath "$SRC_FILE_PATH" "$SCRIPT_DIR" )
  if [[ ! -f "$SRC_FILE_PATH" ]]; then
    echo " # Source file [$SRC_FILE] not found!"
    return 1
  fi
  SRC_FILE_NAME=$( basename "$SRC_FILE_PATH" 2> /dev/null )
  if [[ "$SRC_FILE_NAME" != *.sh ]]; then
    echo " # Source file [$SRC_FILE_NAME] does not match [*.sh] !"
    return 1
  fi
  SRC_FILE_DIR_PATH=$( dirname "$SRC_FILE_PATH" 2> /dev/null )
  if [[ -n "$TARGET_FILE_PATH" ]]; then
    TARGET_FILE_PATH=$( fnGetAbsPath "$TARGET_FILE_PATH" "$SCRIPT_DIR" )
    TARGET_FILE_NAME=$( basename "$TARGET_FILE_PATH" 2> /dev/null )
    TARGET_FILE_DIR_PATH=$( dirname "$TARGET_FILE_PATH" 2> /dev/null )
  fi
  if [[ -z "$TARGET_FILE_DIR_PATH" ]]; then
    echo " # Target dir path is undefined !"
    return 1
  fi
  TARGET_FILE_DIR_PATH=$( fnGetAbsPath "$TARGET_FILE_DIR_PATH" "$SCRIPT_DIR" )
  if [[ -z "$TARGET_FILE_NAME" ]]; then
    TARGET_FILE_NAME="$SRC_FILE_NAME"
  fi
  if [[ -z "$TARGET_FILE_PATH" ]]; then
    TARGET_FILE_PATH="${TARGET_FILE_DIR_PATH}/${TARGET_FILE_NAME}"
  fi
  if [[ ! -d "$TARGET_FILE_DIR_PATH" ]]; then
    echo " # Target dir [$TARGET_DIR] not found!"
    if [[ -z "$TARGET_MKDIRS" || "$TARGET_MKDIRS" == 0 ]]; then return 1; fi
    echo " # Directory will be created upon linking."
  fi
  if [[ -f "$TARGET_FILE_PATH" ]]; then
    echo " # Target file [$TARGET_FILE_PATH] already exists !"
    if [[ -z "$TARGET_OVERWRITE" || "$TARGET_OVERWRITE" == 0 ]]; then return 1; fi
    echo " # File will be overwritten upon linking."
  fi

  # prompt user confirm
  if [[ -z "$SILENT" || "$SILENT" == 0 ]]; then
    echo
    fnPromptConfirm " > Link file [$SRC_FILE_PATH] into [$TARGET_FILE_PATH] ?"
    if [[ $? != 0 ]]; then
      echo " # User Cancelled."
      return 1
    fi
  fi
  
  # save start time
  local start_time diff
  start_time=$( fnElapsedTime )
  
  # Link file
  fnLinkFile  "$SRC_FILE_PATH" "$TARGET_FILE_PATH" "$TARGET_OVERWRITE" "$TARGET_MKDIRS" \
              "PRE_REGEXES" "PRE_REPLACES" "POST_REGEXES" "POST_REPLACES"
  if [[ $? != 0 ]]; then
    echo " # Linker Error !"
    return 1
  fi
  
  # get diff time from start
  diff=$( fnElapsedTime "$start_time" )
  echo " # Done! (${diff}ms)"
}

# Handle arguments :(args)
fnHandleArgs() {
  local key
  local val
  local i=1
  shopt -s nocasematch
  for arg in "$@"; do
    if [[ "$arg" =~ ([^=]*?)\=(.*?) ]]; then
      key="${BASH_REMATCH[1]}"
      val="${BASH_REMATCH[2]}"
      if [[ "$key" == "src-path" ]]; then
        SRC_FILE_PATH="$val"
      elif [[ "$key" == "target-dir" ]]; then
        TARGET_FILE_DIR_PATH="$val"
      elif [[ "$key" == "target-name" ]]; then
        TARGET_FILE_NAME="$val"
      elif [[ "$key" == "pre-regexes" ]]; then
        fnSplitString "$val" "PRE_REGEXES" "$REGEXES_LIST_SEPARATOR"
      elif [[ "$key" == "pre-replaces" ]]; then
        fnSplitString "$val" "PRE_REPLACES" "$REGEXES_LIST_SEPARATOR"
      elif [[ "$key" == "post-regexes" ]]; then
        fnSplitString "$val" "POST_REGEXES" "$REGEXES_LIST_SEPARATOR"
      elif [[ "$key" == "post-replaces" ]]; then
        fnSplitString "$val" "POST_REPLACES" "$REGEXES_LIST_SEPARATOR"
      elif [[ "$key" == "list-separator" ]]; then
        REGEXES_LIST_SEPARATOR="$val"
      else
        echo " # Option $i:[$key:$val] is unknown or invalid."
      fi
    elif [[ "$arg" == "-o" || "$arg" == "--overwrite" ]]; then
      TARGET_OVERWRITE=1
    elif [[ "$arg" == "-m" || "$arg" == "--mkdirs" ]]; then
      TARGET_MKDIRS=1
    elif [[ "$arg" == "-s" || "$arg" == "--silent" ]]; then
      SILENT=1
    elif [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
      fnCmdHelp
      return 1
    elif [[ "$arg" == "-v" || "$arg" == "--version" ]]; then
      fnCmdVersion
      return 1
    else
      echo " # Argument $i:[$arg] is unknown."
    fi

    i=$((i+1))
  done
  shopt -u nocasematch
}

# Print head
fnPrintHead() {
  echo " Xion's Bash Linker (v$VERSION)"
  echo "====================================="
}

# Print help
fnCmdHelp() {
  fnPrintHead
  echo "# Reads a bash script source file searching for 'source %file%' imports with annotations like"
  echo "# '# shellcheck source=%file%' and optionally '# functions=%fn1%,%fn2%...', replaces matched"
  echo "# lines with corresponding file content or functions, and outputs the result to target-dir"
  echo "# in a file named like source file or target-name if defined."
  echo "# List of regex and replaces can be provided to customize source file pre and post linking."
  echo
  echo "# Usage: Juste execute the script and follow instructions, or --help for more."
  echo
  echo "Usage:"
  echo "   .\bash-linker.sh"
  echo "   .\bash-linker.sh src-path=%filepath% target-dir=%dirpath% [--mkdirs] [--overwrite] [--silent]"
  echo "   .\bash-linker.sh src-path=%filepath% target-dir=%dirpath% [-m] [-o] [-s]"
  echo "   .\bash-linker.sh src-path=%filepath% target-dir=%dirpath% target-name=%name% [-m] [-o] [-s]"
  echo "   .\bash-linker.sh src-path=%filepath% target-dir=%dirpath% pre-regexes=%r1%,%r2%,... pre-replaces=%r1%,%r2%,..."
  echo "   .\bash-linker.sh --help"
  echo "   .\bash-linker.sh [\$option=\$value] [\$option=\$value]..."
  echo
  echo "Options:"
  echo "  -h, --help          Print this screen."
  echo "  -v, --version       Print the script version."
  echo "  -m, --mkdirs        Make target directories if not found."
  echo "  -o, --overwrite     Overwrite target if already exists."
  echo "  -s, --silent        Does not prompt user parameters."
  echo
  echo "  [\$option=\$value]  Set an 'option' to 'value' from the following list:"
  echo "      (src-path, target-dir, target-name, pre-regexes, pre-replaces," 
  echo "       post-regexes, post-replaces, list-separator)"
}

# Print version
fnCmdVersion() {
  echo "version: $VERSION"
  echo "build: $BUILD"
  echo "build_time: $BUILD_TIME"
}

# Prompt user source file path
fnPromptSourceFilePath() {
  fnPromptFilePath "Source" "SRC_FILE_PATH" "$SCRIPT_DIR" "*.sh" 1 1 1
  return $?
}

# Prompt user target file dir path
fnPromptTargetDirPath() {
  fnPromptFilePath "Target Directory" "TARGET_FILE_DIR_PATH" "$SCRIPT_DIR" "" 1 0 1 1
  return $?
}

# Prompt user source file name
fnPromptTargetFileName() {
  fnPromptSetVariable "Target File Name" "TARGET_FILE_NAME" 1
  return $?
}

# Prompt user if script can overwrite target file(s)
fnPromptTargetOverwrite() {
  fnPromptConfirm " - Overwrite target if exists ?"
  if [[ $? == 0 ]]; then
    TARGET_OVERWRITE=1
  else
    TARGET_OVERWRITE=0
  fi
  return $TARGET_OVERWRITE
}

# Prompt user if script can make directories
fnPromptCanMkdirs() {
  fnPromptConfirm " - Make directories if necessary ?"
  if [[ $? == 0 ]]; then
    TARGET_MKDIRS=1
  else
    TARGET_MKDIRS=0
  fi
  return $TARGET_MKDIRS
}

# Read a src file and replace imports blocks with corresponding file content or functions
# and write result in target file. Overwrite target file and make target dirs if defined. 
# Customize source file pre and post link with array regexes and replaces if defined.
# :(src_file_path,target_file_path,target_overwrite,target_mkdirs,
# pre_regexes_arr_name,pre_replaces_arr_name,post_regexes_arr_name,post_replaces_arr_name)
fnLinkFile() {
  if [[ -z "$1" || -z "$2" ]]; then return 1; fi
  echo " -- Checking Source File [$1]..."
  if [[ ! -f "$1" ]]; then
    echo " # File [$1] does not exist !"
    return 1
  else
    echo " # File [$1] found."
  fi
  echo " -- Checking Target File [$2]..."
  # check target_file and clean if exists
  if [[ -f "$2" ]]; then
    echo " # File [$2] already exists !"
    if [[ -z "$3" || "$3" == 0 ]]; then return 1; fi
    rm "$2"
    if [[ $? != 0 ]]; then
      echo " # Error deleting File [$2]"
      return 1
    fi
    echo " # File [$2] deleted."
  fi
  # check target_dir and make if not exists
  local target_dir_path; target_dir_path=$( dirname "$2" )
  echo " -- Checking Target Dir [$target_dir_path]..."
  if [[ ! -d "$target_dir_path" ]]; then
    echo " # File directory of [$2] does not exist !"
    if [[ -z "$4" || "$4" == 0 ]]; then return 1; fi
    mkdir -p "$target_dir_path"
    if [[ $? != 0 ]]; then
      echo " # Error making dirs [$target_dir_path] !"
      return 1
    fi
    echo " # Directories of [$target_dir_path] created."
  else
    echo " # Directories path [$target_dir_path] found."
  fi
  # link import files from src file recursively
  local file_result_arr=()
  echo " -- Linking Imports from File [$1]..."
  fnLinkFileRecursive "$1" "file_result_arr" "$5" "$6" "$7" "$8"
  if [[ $? != 0 ]]; then
    echo " # Error while linking source file [$1] !"
    return 1
  fi
  # write result to target_file
  echo " -- Writing linked Source File to [$2]..."
  fnArrayToFile "file_result_arr" "$2"
  if [[ $? != 0 ]]; then
    echo " # Error while writing target file [$2] !"
    return 1
  fi
}

# Read a file and search for '# shellcheck source=%path%', '# imports=%fn1%,%fn2%,...' and
# 'source %path%' lines, then replaces them with corresponding file content or functions.
# Customize source file pre and post link with array regexes and replaces if defined.
# :(file_path,result_arr_name,
# pre_regexes_arr_name,pre_replaces_arr_name,post_regexes_arr_name,post_replaces_arr_name)
fnLinkFileRecursive() {
  if [[ -z "$1" || -z "$2" ]]; then return 1; fi
  if [[ ! "$( declare -p "$2" 2> /dev/null )" =~ "declare -a" ]]; then return 1; fi
  # load src_file in lines array
  local src_file_arr=()
  echo " > Reading File [$1]..."
  fnFileToArray "$1" "src_file_arr"
  if [[ $? != 0 ]]; then
    echo " # Error reading file [$1]!"
    return 1
  fi
  local src_file_arr2=("${src_file_arr[@]}")
  local src_dir_path; src_dir_path=$( dirname "$1" 2> /dev/null )
  # customize source file with regexes, pre link
  if [[ -n "$3" && -n "$4" ]]; then
    echo " > Applying pre-link regex/replaces to file [$1]..."
    fnArrayParseReplace "src_file_arr2" "$3" "$4" 1
  fi
  # read file and get all imports
  local imports_sources_arr=()
  local imports_functions_arr=()
  local imports_start_arr=()
  local imports_end_arr=()
  local imports_count=0
  echo " > Parsing imports..."
  fnParseFileImports  "src_file_arr" "imports_sources_arr" "imports_functions_arr" \
                      "imports_start_arr" "imports_end_arr" "imports_count"
  if [[ $? != 0 ]]; then
    echo " # Error while parsing file [$1]!"
    return 1
  fi
  if [[ $imports_count -gt 0 ]]; then
    echo " # Found [$imports_count] imports sections !"
  else
    echo " # No import section found !"
  fi
  # check imports files exist
  local i src
  for ((i=0; i<$imports_count; i++)); do
    src=$( fnGetAbsPath "${imports_sources_arr[$i]}" "$src_dir_path" )
    imports_sources_arr[$i]="$src"
    if [[ ! -f "$src" ]]; then
      echo " # Import [$((i+1))] > File [$src] in file [$1] (line:$((${imports_start_arr[$i]}+1))) not found !"
      return 1
    fi
  done
  # loop imports
  local id="$RANDOM$RANDOM$RANDOM" # necessary because we cannot re-use the same variable name
  local import_file_content_$id import_content
  local func_name func_tmp file_arr1 file_arr2 delta
  local functions_list functions_arr start end j
  for ((i=0; i<$imports_count; i++)); do
    eval "import_file_content_${id}=()"
    src="${imports_sources_arr[$i]}"
    functions_list="${imports_functions_arr[$i]}"
    start="${imports_start_arr[$i]}"
    end="${imports_end_arr[$i]}"
    echo " == Import Section (lines:[$((start+1)):$((end+1))]) =="
    echo " > Source file [$src]"
    echo " > Checking imports..."
    fnLinkFileRecursive "$src" "import_file_content_${id}"
    if [[ $? != 0 ]]; then
      echo " # Error while recursively linking file [$src]!"
      return 1
    fi
    # if functions specified, split the list, loop array and add each function to content
    if [[ -n "$functions_list" ]]; then
      functions_arr=()
      fnSplitString "$functions_list" "functions_arr" ","
      if [[ $? != 0 ]]; then
        echo " # Error splitting functions list at [$((start+1))] in [$src] !"
        return 1
      fi
      import_content=()
      for ((j=0; j<${#functions_arr[@]}; j++)); do
        func_name="${functions_arr[$j]}"
        func_tmp=()
        echo " > Extracting import function [$func_name]..."
        fnFileArrayExtractFunction "$func_name" 1 "import_file_content_${id}" "func_tmp"
        if [[ $? != 0 ]]; then
          echo " # Error extracting function [$func_name] from [$src] !"
          return 1
        fi
        echo " > Adding import function [$func_name]..."
        import_content+=("${func_tmp[@]}")
        import_content+=("")
      done
    # else add the whole file content
    else
      echo " > Adding full file content..."
      # remove shebang if present at first line
      if [[ "${import_file_content_${id}[0]}" =~ \#\!/ ]]; then
        import_content=("${import_file_content_${id}[@]:1}")
      else
        import_content=("${import_file_content_${id}[@]}")
      fi
    fi
    # calculate lines delta between modified and original files
    delta=$(( ${#src_file_arr2[@]} - ${#src_file_arr[@]} ))
    # split src file tmp before and after imports
    file_arr1=("${src_file_arr2[@]:0:$((start+delta))}")
    file_arr2=("${src_file_arr2[@]:$(($end+delta+1))}")
    # if last line from content and first line of part2 are empty, remove one
    if [[ "${#file_arr2[@]}" -gt 0 && -z "${file_arr2[0]}" \
      && "${#import_content[@]}" -gt 0 && -z "${import_content[-1]}" ]]; then
      unset "import_content[-1]"
    fi
    # set src file tmp new content
    src_file_arr2=("${file_arr1[@]}")
    src_file_arr2+=("${import_content[@]}")
    src_file_arr2+=("${file_arr2[@]}")
  done
  # customize source file with regexes, post link
  if [[ -n "$5" && -n "$6" ]]; then
    echo " > Applying post-link regex/replaces to file [$1]..."
    fnArrayParseReplace "src_file_arr2" "$5" "$6"  1
  fi
  
  # set result to output array
  eval "$2=(\"\${src_file_arr2[@]}\")"
  echo " > File [$1] ready."
}

# :(file_lines_arr_name,res_arr_sources,res_arr_functions,res_arr_start,res_arr_end,res_count)
fnParseFileImports() {
  if [[ -z "$1" || -z "$2" || -z "$3" || -z "$4" || -z "$5" || -z "$6" ]]; then return 1; fi
  if [[ ! "$( declare -p "$1" 2> /dev/null )" =~ "declare -a" ]]; then return 1; fi
  if [[ ! "$( declare -p "$2" 2> /dev/null )" =~ "declare -a" ]]; then return 1; fi
  if [[ ! "$( declare -p "$3" 2> /dev/null )" =~ "declare -a" ]]; then return 1; fi
  if [[ ! "$( declare -p "$4" 2> /dev/null )" =~ "declare -a" ]]; then return 1; fi
  if [[ ! "$( declare -p "$5" 2> /dev/null )" =~ "declare -a" ]]; then return 1; fi
  local s="[:space:]"
  local regex_annotation="^\#[$s]*shellcheck[$s]*source=[\"\']?(.*?)[\"\']?"
  local regex_functions="^\#[$s]*functions=[\"\']?(.*?)[\"\']?[$s]*$"
  local regex_source="^[$s]*source[$s]*[\"\']?(.*?)[\"\']?[$s]*$"
  
  # prepare loop
  local file_arr; eval "file_arr=(\"\${$1[@]}\")"
  local sources_arr=()
  local functions_arr=()
  local start_arr=()
  local end_arr=()
  local count=0
  local source_tmp functions_tmp
  local i j line line2
  local i_max=${#file_arr[@]}
  # loop each line of source file
  for ((i=0; i<$i_max; i++)); do
    line="${file_arr[$i]}"
    # search import annotation match '# shellcheck source=%path%'
    if [[ "$line" =~ $regex_annotation ]]; then
      source_tmp="${BASH_REMATCH[1]}"
      functions_tmp=""
      # search imports functions '# functions=fn1,fn2...'
      for ((j=$((i+1)); j<i_max; j++)); do
        line2="${file_arr[$j]}"
        if [[ "$line2" =~ $regex_functions ]]; then
          if [[ -n "$functions_tmp" ]]; then
            functions_tmp+=","
          fi
          functions_tmp+="${BASH_REMATCH[1]}"
        else
          break
        fi
      done
      # search command match 'source %path%'
      if [[ $j -lt $i_max && "${file_arr[$j]}" =~ $regex_source ]]; then
        sources_arr+=("$source_tmp")
        functions_arr+=("$functions_tmp")
        start_arr+=("$i")
        end_arr+=("$j")
        count=$((count+1))
      fi
    fi
  done
  # set result to output arrays
  eval "$2=(\"\${sources_arr[@]}\")"
  eval "$3=(\"\${functions_arr[@]}\")"
  eval "$4=(\"\${start_arr[@]}\")"
  eval "$5=(\"\${end_arr[@]}\")"
  eval "$6=$count"
}

# Helpers
# -----------------------------------------------------------------------------

# shellcheck source=./libs/array.sh
# functions=fnArrayParseReplace
source "$SCRIPT_DIR/libs/array.sh"

# shellcheck source=./libs/time.sh
# functions=fnElapsedTime,fnFormatMsDuration
source "$SCRIPT_DIR/libs/time.sh"

# shellcheck source=./libs/fs.sh
# functions=fnGetAbsPath,fnFileToArray,fnArrayToFile,fnFileArrayExtractFunction
source "$SCRIPT_DIR/libs/fs.sh"

# shellcheck source=./libs/string.sh
# functions=fnSplitString
source "$SCRIPT_DIR/libs/string.sh"

# shellcheck source=./libs/prompt.sh
# functions=fnPromptConfirm,fnPromptFilePath
source "$SCRIPT_DIR/libs/prompt.sh"

# Execute Main
# -----------------------------------------------------------------------------
fnMain "$@"
ERROR_CODE=$?
if [[ -z "$SILENT" || "$SILENT" == 0 ]]; then
  echo -e "\n # Bye! ($ERROR_CODE)"
fi
exit $ERROR_CODE
