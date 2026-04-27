#!/usr/bin/env bash

BASE_DIR="$HOME/wenedyk/corpus"



# Collect files safely without process substitution

wen_files=()

while IFS= read -r file; do

    wen_files+=("$file")

    done <<< "$(find "$BASE_DIR" -type f -name "*.wen.txt")"

# Exit if none found
if [ ${#wen_files[@]} -eq 0 ]; then
    echo "No .wen.txt files found."
        exit 1
	fi

	# Pick a random .wen file
	random_wen=$(printf "%s\n" "${wen_files[@]}" | shuf -n 1)

	# Derive base path (remove extension)
	base="${random_wen%.wen.txt}"

	wen_file="${base}.wen.txt"
	pol_file="${base}.pol.txt"
	eng_file="${base}.eng.txt"

	# Check existence
	if [[ ! -f "$pol_file" || ! -f "$eng_file" ]]; then
	    echo "Missing corresponding files for: $base"
	        exit 1
		fi

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
