#!/bin/bash

# Purpose: This script verifies that no files in a release branch contain references to images from the previous release version.
# 
# Functionality:
# 1. Determines if the current branch is a release branch (e.g., release-4.x).
# 2. Extracts the previous version (e.g. 4.16 for release-4.17).
# 3. Checks specific files for any occurrences of the previous version.
# 4. If matches are found, it prompts the user to update references to the current release branch and exits with an error code.
# 5. Skips checks for non-release branches or missing files.

# Get the current branch name
branch_name=$(git rev-parse --abbrev-ref HEAD)

# Define the regex for release branches
release_regex="release-([0-9]+)\.([0-9]+)"

# Skip checks for non-release branches
if [[ ! $branch_name =~ $release_regex ]]; then
    echo "Branch '$branch_name' is not a release branch. Skipping checks."
    exit 0
fi

# Extract x and y from the branch name
x="${BASH_REMATCH[1]}"
y="${BASH_REMATCH[2]}"
previous_version="$x.$((y - 1))" # Example: 4.16 for branch release-4.17

# Files to check
files_to_check=(
    "cnf-tests/Dockerfile.openshift"
    # "cnf-tests/Dockerfile.konflux"
    "cnf-tests/mirror/images.json"
    "cnf-tests/testsuites/pkg/images/images.go"
    "hack/common.sh"
    "hack/run-functests.sh"
)

# Flag to track if any matches are found
match_found=false

# Search for the previous version pattern in specified files
for file in "${files_to_check[@]}"; do
    if [[ -f "$file" ]]; then
        if grep -nw "$file" -e "$previous_version"; then
            echo "Reference to $previous_version found in $file."
            match_found=true
        fi
    else
        echo "Warning: File '$file' does not exist. Skipping."
    fi
done

# If matches were found, fail the test
if $match_found; then
    echo "----------------------------------------------------------------------------------"
    echo "The following files contain references to the previous release version ($previous_version):"
    echo "Please update them to the current release branch ($branch_name) to ensure consistency."
    echo "For more details, refer to the Branching section in the project's readme.md."
    exit 1
else
    echo "All files are up-to-date. No references to $previous_version were found."
fi
