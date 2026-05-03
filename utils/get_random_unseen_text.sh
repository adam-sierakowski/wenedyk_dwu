#!/usr/bin/env bash

BASE_DIR="corpus"
SEEN_FILE="utils/get_random_unseen_text__seen_texts.txt"

# Collect all .wen.txt files
wen_files=()
while IFS= read -r file; do
    wen_files+=("$file")
done <<< "$(find "$BASE_DIR" -type f -name "*.wen.txt")"

if [ ${#wen_files[@]} -eq 0 ]; then
    echo "No .wen.txt files found."
    exit 1
fi

# Filter out already seen files
unseen=()
for f in "${wen_files[@]}"; do
    if ! grep -qxF "$f" "$SEEN_FILE" 2>/dev/null; then
        unseen+=("$f")
    fi
done

if [ ${#unseen[@]} -eq 0 ]; then
    echo "All texts have been seen."
    exit 0
fi

# Pick a random unseen .wen file
random_wen=$(printf "%s\n" "${unseen[@]}" | shuf -n 1)

base="${random_wen%.wen.txt}"
wen_file="${base}.wen.txt"
pol_file="${base}.pol.txt"
eng_file="${base}.eng.txt"

if [[ ! -f "$pol_file" || ! -f "$eng_file" ]]; then
    echo "Missing corresponding files for: $base"
    exit 1
fi

# Record as seen
echo "$random_wen" >> "$SEEN_FILE"

# Display
echo
echo "Source: $base"
echo

echo "========== WEN =========="
cat "$wen_file"
echo

echo "========== POL =========="
cat "$pol_file"
echo

echo "========== ENG =========="
cat "$eng_file"
