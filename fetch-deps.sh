#!/bin/bash

# ---- Whats happening ---- #

# This fetches the dependencies listed in the "libs" variable and saves them in the targetFolder

set -e

libs=(
    "TestSuite-lib"
    "TurtleEmulator-lib"
    "turtleController-lib"
    "ccClass-lib"
    "miningClient-lib"
    "helperFunctions-lib"
    "eventHandler-lib"
    "config-lib"
)

# Basic setup variables
repo="mc-cc-scripts"
branch="master"
targetFolderName=libs


# fetch files.txt and save each file into the targetFolder
fetch() {
    files_txt=$(curl -fsSL "https://raw.githubusercontent.com/$repo/$1/$branch/files.txt")
    if [ -z "$files_txt" ]; then
        echo "Could not load files.txt for $1"
        exit 1
    fi
    while IFS= read -r FILE; do
        url="https://raw.githubusercontent.com/$repo/$1/$branch/$FILE"

        mkdir -p "$(dirname "$targetFolderName/$FILE")" # create the folder (and subfolders specified in the files.txt)
        rm -f $targetFolderName/$FILE.lua # rm existing file
        if ! curl -s -o "$targetFolderName/$FILE" "$url"; then
            echo "could not get / write the file $i: '$FILE' to the folder '$targetFolderName'"
            exit 1
        fi
        # echo "saved $1: '$FILE' in '$targetFolderName'"
    done < <(echo  "$files_txt")
}

if [[ $# -eq 0 ]]; then
    # No arguments given, fetch all
    for i in "${libs[@]}"; do
        fetch "$i"
    done
else
    # Argument given, fetch arguemt
    fetch "$1"
fi