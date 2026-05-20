#!/usr/bin/env bash

BASE_DIR="corpus"
SEEN_FILE="utils/.seen_texts"

usage() {
    echo "Usage: $0 [-c] [-r] [-u]"
    echo "  -c  show only vn, en, pl versions"
    echo "  -r  include review files"
    echo "  -u  pick only from unseen texts (tracked in $SEEN_FILE)"
    exit 1
}

core_only=false
include_review=false
unseen_only=false

while getopts "cru" opt; do
    case "$opt" in
        c) core_only=true ;;
        r) include_review=true ;;
        u) unseen_only=true ;;
        *) usage ;;
    esac
done

# Collect all .vn.txt files, pre-sorted (required by comm below)
vn_files=()
_tmp_vn=$(mktemp)
find "$BASE_DIR" -type f -name "*.vn.txt" | sort > "$_tmp_vn"
while IFS= read -r file; do
    vn_files+=("$file")
done < "$_tmp_vn"
rm -f "$_tmp_vn"

if [ ${#vn_files[@]} -eq 0 ]; then
    echo "No .vn.txt files found."
    exit 1
fi

# Filter to unseen: use comm instead of per-file grep (much faster on iSH)
if $unseen_only; then
    unseen=()
    _tmp_all=$(mktemp)
    _tmp_seen=$(mktemp)
    _tmp_unseen=$(mktemp)
    printf '%s\n' "${vn_files[@]}" > "$_tmp_all"
    sort "$SEEN_FILE" 2>/dev/null > "$_tmp_seen"
    comm -23 "$_tmp_all" "$_tmp_seen" > "$_tmp_unseen"
    while IFS= read -r f; do
        [[ -n "$f" ]] && unseen+=("$f")
    done < "$_tmp_unseen"
    rm -f "$_tmp_all" "$_tmp_seen" "$_tmp_unseen"
    if [ ${#unseen[@]} -eq 0 ]; then
        echo "All texts have been seen."
        exit 0
    fi
    vn_files=("${unseen[@]}")
fi

# Pick a random .vn.txt
random_vn=$(printf "%s\n" "${vn_files[@]}" | shuf -n 1)
base="${random_vn%.vn.txt}"

# Mark as seen
if $unseen_only; then
    echo "$random_vn" >> "$SEEN_FILE"
fi

# Collect and filter files to display
shopt -s nullglob
all_files=("${base}".*.txt)
IFS=$'\n' all_files=($(printf '%s\n' "${all_files[@]}" | sort))
unset IFS

files_to_show=()
for f in "${all_files[@]}"; do
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
    echo "No files to display for: $base"
    exit 1
fi

echo
echo "Source: $base"
echo

for file in "${files_to_show[@]}"; do
    echo "========== $(basename "$file") =========="
    cat -n "$file"
    echo
done
