#!/usr/bin/env bash

# Check input
if [ $# -eq 0 ]; then
    echo "Usage: $0 path/to/file_base1 [path/to/file_base2 ...]"
    exit 1
fi

shopt -s nullglob

for base in "$@"; do

    # Find matching files
    files=( "${base}".*.txt )

    # Validate matches
    if [ ${#files[@]} -eq 0 ]; then
        echo "No matching files found for pattern: ${base}.*.txt"
        echo
        continue
    fi

    # Sort alphabetically
    IFS=$'\n' files=($(printf '%s\n' "${files[@]}" | sort))
    unset IFS

    # Display
    echo "Source: $base"
    echo

    for file in "${files[@]}"; do
        echo "========== $(basename "$file") =========="
        cat -n "$file"
        echo
    done

done