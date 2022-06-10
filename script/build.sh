#!/bin/bash

# Get the real absolute path of this script directory
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )";

# Import libs

# shellcheck source=../src/libs/utils.sh
source "$SCRIPT_DIR/../src/libs/utils.sh"

# Get the real absolute path of linker script
LINKER_PATH="$( realpath "${SCRIPT_DIR}/../src/bash-linker.sh" )"

# Set source and target
SRC_PATH="../src/bash-linker.sh"
TARGET_DIR="../build"

# Set regexes and replaces arrays
REGEXES="^BUILD_TIME=[^#]*?#%BUILD_TIME%,^BUILD=[^#]*?#%BUILD%"
REPLACES="BUILD_TIME=\"$( date +%Y-%m-%d_%H:%M:%S )\" #,BUILD=\"$( fnGenUid 8 1 )\" #"

echo -e " - Building [$SRC_PATH] in [$TARGET_DIR]...\n"

# Start building
$LINKER_PATH "src-path=$SRC_PATH" "target-dir=$TARGET_DIR" "pre-regexes=$REGEXES" "pre-replaces=$REPLACES" -m -o -s
ERROR_CODE=$?

# Check errors
if [[ $ERROR_CODE != 0 ]]; then
  echo " # Ended with Error !"
fi

echo -e "\n - Build Done !"
