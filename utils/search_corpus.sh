#!/usr/bin/env bash

BASE_DIR="corpus"

usage() {
    echo "Usage: $0 <lang> [-c|--core] [-r] [-f|--full] [grep_flags...] \"regex\""
    echo "  lang         language code to search (e.g. vn, en, pl, la, ...)"
    echo "  -c/--core    show only vn, en, pl translations"
    echo "  -r           include review files"
    echo "  -f/--full    show full files instead of matched lines"
    exit 1
}

if [[ $# -lt 2 ]]; then
    usage
fi

lang="$1"
shift

core_only=false
include_review=false
full_mode=false
grep_flags=()

while [[ $# -gt 1 ]]; do
    case "$1" in
        -c|--core)  core_only=true ;;
        -r)         include_review=true ;;
        -f|--full)  full_mode=true ;;
        *)          grep_flags+=("$1") ;;
    esac
    shift
done
regex="$1"

if [[ -z "$lang" || -z "$regex" ]]; then
    usage
fi

# Get sorted companion files for a base path (excluding the searched lang)
get_companions() {
    local base="$1"
    local companions=()
    shopt -s nullglob
    local all=("${base}".*.txt)
    IFS=$'\n' all=($(printf '%s\n' "${all[@]}" | sort))
    unset IFS
    for f in "${all[@]}"; do
        local flang="${f%.txt}"; flang="${flang##*.}"
        [[ "$flang" == "$lang" ]] && continue
        [[ "$flang" == "review" ]] && ! $include_review && continue
        if $core_only; then
            [[ "$flang" != "vn" && "$flang" != "en" && "$flang" != "pl" ]] && \
                { $include_review && [[ "$flang" == "review" ]] || continue; }
        fi
        companions+=("$f")
    done
    printf '%s\n' "${companions[@]}"
}

# Find all files with matches
matching_files=()
while IFS= read -r f; do
    matching_files+=("$f")
done < <(grep -rl "${grep_flags[@]}" --include="*.$lang.txt" -e "$regex" "$BASE_DIR" 2>/dev/null | sort)

if [ ${#matching_files[@]} -eq 0 ]; then
    echo "No matches found."
    exit 0
fi

for file in "${matching_files[@]}"; do
    base="${file%.${lang}.txt}"

    echo "=================================================="
    echo "FILE: $file"
    echo "=================================================="

    # Get companion files
    companions=()
    while IFS= read -r c; do
        [[ -n "$c" ]] && companions+=("$c")
    done < <(get_companions "$base")

    if $full_mode; then
        echo "----- [$lang] $(basename "$file") -----"
        nl -ba "$file" | grep --color=always -E "${grep_flags[@]}" "$regex|$"
        echo
        for companion in "${companions[@]}"; do
            clang="${companion%.txt}"; clang="${clang##*.}"
            echo "----- [$clang] $(basename "$companion") -----"
            nl -ba "$companion"
            echo
        done
    else
        # Matched line numbers (no color, for indexing)
        line_nums=()
        while IFS= read -r n; do
            line_nums+=("$n")
        done < <(grep -n "${grep_flags[@]}" -e "$regex" "$file" | cut -d: -f1)

        first=true
        for linenum in "${line_nums[@]}"; do
            $first || echo
            first=false

            # Highlighted match line
            colored=$(sed -n "${linenum}p" "$file" | grep --color=always -E "${grep_flags[@]}" "$regex|$")
            echo "  [$lang] $linenum: $colored"

            # Aligned translation lines
            for companion in "${companions[@]}"; do
                clang="${companion%.txt}"; clang="${clang##*.}"
                trans_line=$(sed -n "${linenum}p" "$companion" 2>/dev/null)
                [[ -n "$trans_line" ]] && echo "  [$clang] $linenum: $trans_line"
            done
        done
        echo
    fi
done
