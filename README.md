# Xion's Bash Linker
- Author: Spacexion
- Url: https://www.github.com/spacexion/bash-linker

It's a bash tool written in bash which allows building bash script files with imported content from annotated 'source %file%' commands.

### Description

Reads a bash script source file searching for 'source %file%' imports annotated by '# shellcheck source=%file%' and 
adjacent '# functions=%fn1%,%fn2%...' lines, giving the path of the library file and the lists of required functions.

It then replaces each import blocks matched lines with corresponding full file content, or only the required functions
if '# functions' annotation(s) defined.

If no errors occurred, it then outputs the result to a target directory named as the original source file or renamed.

A list of regex rules and a list of corresponding replaces can be provided to manually adjust the input file before being parsed.

A list of regex rules and a list of corresponding replaces can be provided to manually adjust the output file before being written.

### Infos

The scripts need to be space indented for the parsers to work.

The regex and replaces lists arguments must be strings separated by ',' per default.

If a regex or replace contain a ',' it can be changed by setting the 'list-separator' argument.

The linker does not check already imported files or functions.

The linker does not check if imported functions work or meet dependencies requirements, it only returns an error when a file or a function is not found, and on read/write error.

### Usage

The script can be executed from src directly but if you want a portable version, use the build version.

Help message:
```bash
# More infos
./bash-linker.sh --help
./bash-linker.sh -h
```

Example build script:
```bash
#!/bin/bash

# Set regexes list with 'BUILD_TIME=' and 'VERSION=' rules
PRE_REGEXES="^BUILD_TIME=[^#]*?#%BUILD_TIME%,^VERSION=[^#]*?#%VERSION%"
# Set replaces list with 'BUILD_TIME' as a formatted date and 'VERSION' as a version string
PRE_REPLACES="BUILD_TIME=\"$( date +%Y-%m-%d_%H:%M:%S )\" #,VERSION=\"0.0.1\" #"

# Link source file into target dir, optionally renamed and with pre-link regexes/replaces lists
./bash-linker.sh  "src-path=../src/my-script.sh" "target-dir=../build" "target-name=my-script-built.sh" \
                  "pre-regexes=$PRE_REGEXES" "pre-replaces=$PRE_REPLACES"

```

Example 'my-script.sh':
```bash
#!/bin/bash

BUILD="" #%BUILD% auto-generated upon build
BUILD_TIME="" #%BUILD_TIME% auto-generated upon build

SCRIPT_DIR="$( cd - )" # basic way to get the script base path (eg. not full proof)

# Define the main
#-------------------
fnMain() {
  echo "Hello this is the Main !"
  fnMyFunction1
  fnMyFunction2
}

# Import 'my-lib.sh'
#-------------------
# shellcheck source=./libs/my-lib.sh
# functions=fnMyFunction1,fnMyFunction2
source "$SCRIPT_DIR/libs/prompt.sh"

# Execute the main
#-------------------
fnMain

```

Example './libs/my-lib.sh':
```bash
#!/bin/bash

# Define function 1
fnMyFunction1() {
  echo "Hello this is the Function1 !"
}

# Define function 2
fnMyFunction2() {
  echo "Hello this is the Function2 !"
}

# Define function 3
fnMyFunction3() {
  echo "Hello this is the Function3 !"
}

```

Example result build '../build/my-script-built.sh':
```bash
#!/bin/bash

BUILD="2d56amx8" # auto-generated upon build
BUILD_TIME="2022-05-29_09:25:37" # auto-generated upon build

SCRIPT_DIR="$( cd - )" # basic way to get the script base path (eg. not full proof)

# Define the main
#-------------------
fnMain() {
  echo "Hello this is the Main !"
  fnMyFunction1
  fnMyFunction2
}

# Import 'my-lib.sh'
#-------------------
# Define function 1
fnMyFunction1() {
  echo "Hello this is the Function1 !"
}

# Define function 2
fnMyFunction2() {
  echo "Hello this is the Function2 !"
}

# Execute the main
#-------------------
fnMain

```

### Build

The bash-linker script in src is used to build bash-linker.

Just execute the build script './script/build.sh' and if no errors, the output file should be in './build/' directory.

```bash
./script/build.sh
```

### TODO

- add checks for already imported files or functions.