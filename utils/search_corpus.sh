#!/usr/bin/env bash

BASE_DIR="corpus"

usage() {
    echo "Usage: $0 <lang> [-crf] -- [grep_flags...] \"regex\""
    echo "       $0 <lang> [grep_flags...] \"regex\""
    echo ""
    echo "  lang    language code to search (e.g. vn, en, pl, la, ...)"
    echo "  -c      show only vn, en, pl translations"
    echo "  -r      include review files"
    echo "  -f      show full files instead of matched lines"
    echo ""
    echo "  Script flags must come before -- to avoid ambiguity with grep flags."
    echo "  Without --, all args after lang are treated as grep flags + regex."
    exit 1
}

if [[ $# -lt 2 ]]; then
    usage
fi

lang="$1"; shift

core_only=false
include_review=false
full_mode=false

# Split args at --, if present
before_sep=()
after_sep=()
found_sep=false
for arg in "$@"; do
    if [[ "$arg" == "--" ]]; then
        found_sep=true
    elif $found_sep; then
        after_sep+=("$arg")
    else
        before_sep+=("$arg")
    fi
done

# Parse script flags only when -- was given
if $found_sep; then
    set -- "${before_sep[@]}"
    while getopts "crf" opt; do
        case "$opt" in
            c) core_only=true ;;
            r) include_review=true ;;
            f) full_mode=true ;;
            ?) usage ;;
        esac
    done
    work=("${after_sep[@]}")
else
    work=("${before_sep[@]}")
fi

if [ ${#work[@]} -lt 1 ]; then usage; fi
regex="${work[${#work[@]}-1]}"
grep_flags=("${work[@]:0:${#work[@]}-1}")

# Sorted companion files for a stem, excluding the searched lang
get_companions() {
    local base="$1"
    shopt -s nullglob
    local all=("${base}".*.txt)
    IFS=$'\n' all=($(printf '%s\n' "${all[@]}" | sort))
    unset IFS
    for f in "${all[@]}"; do
        local flang="${f%.txt}"; flang="${flang##*.}"
        [[ "$flang" == "$lang" ]] && continue
        if $core_only; then
            [[ "$flang" == "vn" || "$flang" == "en" || "$flang" == "pl" ]] \
                || { $include_review && [[ "$flang" == "review" ]]; } \
                || continue
        else
            [[ "$flang" == "review" ]] && ! $include_review && continue
        fi
        echo "$f"
    done
}

# Find all files with matches
matching_files=()
_tmp_matches=$(mktemp)
grep -rl "${grep_flags[@]}" --include="*.$lang.txt" -e "$regex" "$BASE_DIR" 2>/dev/null | sort > "$_tmp_matches"
while IFS= read -r f; do
    matching_files+=("$f")
done < "$_tmp_matches"
rm -f "$_tmp_matches"

if [ ${#matching_files[@]} -eq 0 ]; then
    echo "No matches found."
    exit 0
fi

for file in "${matching_files[@]}"; do
    base="${file%.${lang}.txt}"

    echo "=================================================="
    echo "FILE: $file"
    echo "=================================================="

    companions=()
    while IFS= read -r c; do
        [[ -n "$c" ]] && companions+=("$c")
    done <<< "$(get_companions "$base")"

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
        # Get matching line numbers without color
        line_nums=()
        while IFS= read -r n; do
            [[ -n "$n" ]] && line_nums+=("$n")
        done <<< "$(grep -n "${grep_flags[@]}" -e "$regex" "$file" | cut -d: -f1)"

        first=true
        for linenum in "${line_nums[@]}"; do
            $first || echo
            first=false

            # Show matched line with highlighting
            colored=$(sed -n "${linenum}p" "$file" | grep --color=always -E "${grep_flags[@]}" "$regex|$")
            echo "  [$lang] $linenum: $colored"

            # Show aligned line from each companion
            for companion in "${companions[@]}"; do
                clang="${companion%.txt}"; clang="${clang##*.}"
                trans_line=$(sed -n "${linenum}p" "$companion" 2>/dev/null)
                [[ -n "$trans_line" ]] && echo "  [$clang] $linenum: $trans_line"
            done
        done
        echo
    fi
done
