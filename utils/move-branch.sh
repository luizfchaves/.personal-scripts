#!/bin/bash

ORIGINAL_DIR=${1}
if [ -z "$ORIGINAL_DIR" ]; then
    echo "Usage: $0 <original_directory> [branch_name]"
    exit 1
fi
cd "$ORIGINAL_DIR" || { echo "Failed to change directory to $ORIGINAL_DIR"; exit 1; }

projects=($(ls -d */ | sed 's#/##'))
BRANCH=${2:-main}


# Loop through each project directory
for project in "${projects[@]}"; do
    # echo "Processing $project..."

    cd "$project" || { echo "Failed to change directory to $project"; exit 1; }
    
    if [ ! -d .git ]; then
        echo "$project is not a git repository, skipping"
        cd "$ORIGINAL_DIR"
        continue
    fi

    if [ -n "$(git status --porcelain)" ]; then
        echo "WARNING: Uncommitted changes in $project. Do you want to throw them away? (y/N)"
        read -r answer
        if [[ ! "$answer" =~ ^[Yy]$ ]]; then
            echo "Stopping script due to uncommitted changes in $project."
            cd "$ORIGINAL_DIR"
            exit 1
        fi
        echo "Discarding uncommitted changes in $project."
        git reset --hard >/dev/null 2>&1 || { echo "Failed to reset in $project"; cd "$ORIGINAL_DIR"; continue; }

        # cd "$ORIGINAL_DIR"
        #continue
    fi

    git fetch origin >/dev/null 2>&1  || { echo "Failed to fetch in $project"; cd "$ORIGINAL_DIR"; continue; }
    
    if git show-ref --quiet refs/heads/$BRANCH >/dev/null 2>&1; then
        echo "['$BRANCH'] - $project."
        git checkout $BRANCH >/dev/null 2>&1
    else
        echo "['main'] - $project."
        git checkout main >/dev/null 2>&1
    fi


    cd ..
    
    # Print success message
done

echo "All projects updated."