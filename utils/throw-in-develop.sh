#!/bin/bash

ORIGINAL_DIR=${1}
if [ -z "$ORIGINAL_DIR" ]; then
    echo "Usage: $0 <original_directory> [branch_name] [--reset (optional)]"
    exit 1
fi
cd "$ORIGINAL_DIR" || { echo "Failed to change directory to $ORIGINAL_DIR"; exit 1; }

projects=($(ls -d */ | sed 's#/##'))
BRANCH=${2}
if [ -z "$BRANCH" ]; then
    echo "No branch specified."
    exit 1
fi


# The user can send --reset
withReset=false
if [[ " $* " == *" --reset "* ]]; then
  withReset=true
fi

echo -e "❇️ Project Name \t\tMerged\tReseted\tEnvDiff"

# Loop through each project directory
for project in "${projects[@]}"; do

    cd "$project" || { echo "Failed to change directory to $project"; exit 1; }
    
    if [ ! -d .git ]; then
        # echo "$project is not a git repository, skipping"
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
        git reset --hard >/dev/null 2>&1 || { echo "Failed to reset in $project"; exit 1; }

        # cd "$ORIGINAL_DIR"
        #continue
    fi

    git checkout main >/dev/null 2>&1 || { echo "Failed to checkout main in $project"; exit 1; }
    git pull origin main >/dev/null 2>&1 || { echo "Failed to pull main in $project"; exit 1; }
    git checkout develop >/dev/null 2>&1 || { echo "Failed to checkout develop in $project"; exit 1; }
    git reset --hard origin/develop >/dev/null 2>&1 || { echo "Failed to reset develop in $project"; exit 1; }

    reseted=false
    if $withReset; then
        #check if has diff with main
        if ! git diff --quiet main; then
            reseted=true
            git reset --hard origin/main >/dev/null 2>&1 || { echo "Failed to reset in $project"; exit 1; }
            git push origin develop --force >/dev/null 2>&1 || { echo "Failed to force push develop in $project"; exit 1; }
        fi

    else
        git merge main >/dev/null 2>&1 || { echo "Failed to merge main into develop in $project"; exit 1; }
    fi

    # check if the branch exists
    merged=false
    if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
        merged=true
        git merge --no-ff "$BRANCH" >/dev/null 2>&1 || { echo "Failed to merge $BRANCH into develop in $project"; exit 1; }
    fi

    hasEnvDiff=false
    # check diff between $BRANCH and main and check if .env-sample is different
    if ${merged}; then
        envFiles=(".env-sample" ".env.local.sample")
        for envFile in "${envFiles[@]}"; do
            if [ ! -f "$envFile" ]; then
                continue
            fi

            if ! git diff --quiet "$BRANCH" main -- "$envFile"; then
                hasEnvDiff=true
                break
            fi
        done
    fi

    git push origin develop >/dev/null 2>&1 || { echo "Failed to push develop in $project"; exit 1; }

    textOk="✅ "
    textProject="$project"
    textProject=$(printf "%-29s" "$textProject")
    textMerged="\t"
    if $merged; then
        textMerged="  ✅\t"
    fi
    textReseted="\t"
    if $reseted; then
        textReseted="  ✅\t"
    fi
    textHasEnvDiff="\t"
    if $hasEnvDiff; then
        textHasEnvDiff="  ❗\t"
    fi
    # # OK - PROJECTNAME - MERGED - RESETTED - HAS_ENV_DIFF
    echo -e "$textOk$textProject$textMerged$textReseted$textHasEnvDiff"

    cd ..
done

echo "All projects updated."