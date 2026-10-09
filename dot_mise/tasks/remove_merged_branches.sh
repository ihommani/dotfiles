#!/usr/bin/env bash
set -uo pipefail

# Get the git root directory
# If git works from current directory, use it; otherwise exit with error
if ! git_root=$(git rev-parse --show-toplevel 2>/dev/null); then
    echo "Error: Not in a git repository or its subdirectory"
    echo "Please run this command from within a git repository"
    exit 1
fi

# Change to the git root
cd "$git_root"

# Get the default branch (typically main or master)
default_branch=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's|.*/||')

echo "Default branch: $default_branch"
echo "Fetching latest branch info..."
git fetch origin --prune

# Get list of merged LOCAL branches (exclude the default branch)
local_merged=$(git branch --merged "$default_branch" | grep -v "^\* " | grep -v "^\s*$default_branch\s*$" | sed 's/^[[:space:]]*//g' | sort)

# Get list of merged REMOTE branches (exclude the default branch and HEAD)
remote_merged=$(git branch -r --merged "origin/$default_branch" | grep -v "origin/$default_branch" | grep -v "origin/HEAD" | sed 's|origin/||' | sort)

# Combine both lists and remove duplicates
all_merged=$(printf "%s\n%s\n" "$local_merged" "$remote_merged" | grep -v "^$" | sort -u)

if [ -z "$all_merged" ]; then
    echo "No merged branches found."
    exit 0
fi

echo "Found merged branches:"
echo "$all_merged"
echo ""

# Confirm deletion
read -p "Delete these merged branches? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# Delete branches
echo "Deleting merged branches..."
echo "$all_merged" | while read -r branch; do
    deleted_any=0

    # Delete remote branch if it exists on remote
    if git ls-remote --heads origin "$branch" | grep -q "$branch"; then
        echo "  Deleting origin/$branch..."
        if git push origin --delete "$branch" 2>&1; then
            echo "    ✓ Deleted from remote"
            deleted_any=1
        else
            echo "    ✗ Failed to delete origin/$branch"
        fi
    fi

    # Delete local branch if it exists locally
    if git show-ref --quiet "refs/heads/$branch"; then
        echo "  Deleting local $branch..."
        if git branch -d "$branch" 2>&1; then
            echo "    ✓ Deleted locally"
            deleted_any=1
        else
            echo "    ✗ Cannot delete (in use by worktree or has unmerged changes)"
        fi
    fi

    if [ $deleted_any -eq 0 ]; then
        echo "  ✗ Branch $branch not found locally or remotely"
    fi
done

echo "Done!"
