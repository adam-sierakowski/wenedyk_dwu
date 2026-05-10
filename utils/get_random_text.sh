#!/usr/bin/env bash

BASE_DIR="corpus"
SEEN_FILE="utils/.seen_texts"

usage() {
    echo "Usage: $0 [-c|--core] [-r] [-u|--unseen]"
    echo "  -c/--core    show only vn, en, pl versions"
    echo "  -r           include review files"
    echo "  -u/--unseen  pick only from unseen texts (tracked in $SEEN_FILE)"
    exit 1
}

core_only=false
include_review=false
unseen_only=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -c|--core)   core_only=true ;;
        -r)          include_review=true ;;
        -u|--unseen) unseen_only=true ;;
        -h|--help)   usage ;;
        *) echo "Unknown flag: $1"; usage ;;
    esac
    shift
done

# Collect all .vn.txt files
vn_files=()
while IFS= read -r file; do
    vn_files+=("$file")
done < <(find "$BASE_DIR" -type f -name "*.vn.txt" | sort)

if [ ${#vn_files[@]} -eq 0 ]; then
    echo "No .vn.txt files found."
    exit 1
fi

# Filter to unseen if requested
if $unseen_only; then
    unseen=()
    for f in "${vn_files[@]}"; do
        if ! grep -qxF "$f" "$SEEN_FILE" 2>/dev/null; then
            unseen+=("$f")
        fi
    done
    if [ ${#unseen[@]} -eq 0 ]; then
        echo "All texts have been seen."
        exit 0
    fi
    vn_files=("${unseen[@]}")
fi

# Pick a random .vn.txt
random_vn=$(printf "%s\n" "${vn_files[@]}" | shuf -n 1)
base="${random_vn%.vn.txt}"

# Mark as seen if -u
if $unseen_only; then
    echo "$random_vn" >> "$SEEN_FILE"
fi

# Collect files to display
shopt -s nullglob
all_files=("${base}".*.txt)
IFS=$'\n' all_files=($(printf '%s\n' "${all_files[@]}" | sort))
unset IFS

files_to_show=()
for f in "${all_files[@]}"; do
    lang="${f%.txt}"; lang="${lang##*.}"
    [[ "$lang" == "review" ]] && ! $include_review && continue
    if $core_only; then
        [[ "$lang" != "vn" && "$lang" != "en" && "$lang" != "pl" && "$lang" != "review" ]] && continue
        [[ "$lang" == "review" ]] && ! $include_review && continue
    fi
    files_to_show+=("$f")
done

if [ ${#files_to_show[@]} -eq 0 ]; then
    echo "No files to display for: $base"
    exit 1
fi

echo
echo "Source: $base"
echo

for file in "${files_to_show[@]}"; do
    echo "========== $(basename "$file") =========="
    cat "$file"
    echo
done
