#!/usr/bin/env bash

usage() {
    echo "Usage: $0 [-c] [-r] path/to/file_base1 [path/to/file_base2 ...]"
    echo "  -c  show only vn, en, pl versions"
    echo "  -r  include review files"
    exit 1
}

if [ $# -eq 0 ]; then
    usage
fi

core_only=false
include_review=false

while getopts "cr" opt; do
    case "$opt" in
        c) core_only=true ;;
        r) include_review=true ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))

if [ $# -eq 0 ]; then
    usage
fi

shopt -s nullglob

for base in "$@"; do

    files=("${base}".*.txt)

    if [ ${#files[@]} -eq 0 ]; then
        echo "No matching files found for pattern: ${base}.*.txt"
        echo
        continue
    fi

    IFS=$'\n' files=($(printf '%s\n' "${files[@]}" | sort))
    unset IFS

    # Filter by flags
    files_to_show=()
    for f in "${files[@]}"; do
        lang="${f%.txt}"; lang="${lang##*.}"
        if $core_only; then
            [[ "$lang" == "vn" || "$lang" == "en" || "$lang" == "pl" ]] \
                || { $include_review && [[ "$lang" == "review" ]]; } \
                || continue
        else
            [[ "$lang" == "review" ]] && ! $include_review && continue
        fi
        files_to_show+=("$f")
    done

    if [ ${#files_to_show[@]} -eq 0 ]; then
        echo "No matching files to display for: $base"
        echo
        continue
    fi

    echo "Source: $base"
    echo

    for file in "${files_to_show[@]}"; do
        echo "========== $(basename "$file") =========="
        cat -n "$file"
        echo
    done

done
