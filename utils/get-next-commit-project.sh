#!/bin/bash

CURRENT_DIR=$(pwd)

ORIGINAL_DIR=${1}
if [ -z "$ORIGINAL_DIR" ]; then
    echo "Usage: $0 <original_directory>"
    exit 1
fi


cd "$ORIGINAL_DIR" || { echo "Failed to change directory to $ORIGINAL_DIR"; exit 1; }

projects=($(ls -d */ | sed 's#/##'))


# Loop through each project directory
for project in "${projects[@]}"; do
    cd "$project" || { echo "Failed to change directory to $project"; exit 1; }
    
    if [ ! -d .git ]; then
        cd "$ORIGINAL_DIR"
        continue
    fi


    if [ -n "$(git status --porcelain)" ]; then
        clear
        echo "You have changes on $project. Moving you there." 
        cd "$ORIGINAL_DIR/$project"  &> /dev/null
        git status
        return 0
    fi

    # now checking if has unpushed commits
    #if [ -n "$(git log origin/main..HEAD)" ]; then
    #    clear
    #    echo "You have unpushed commits on $project. Moving you there."
    #     cd "$ORIGINAL_DIR/$project" &> /dev/null
    #     git log origin/main..HEAD --oneline
    #     return 0
    # fi

    cd ..
done

clear
echo "All projects updated."
cd "$CURRENT_DIR" || { echo "Failed to change back to $CURRENT_DIR"; exit 1; }