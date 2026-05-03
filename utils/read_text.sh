#!/usr/bin/env bash

# Check input
if [ -z "$1" ]; then
    echo "Usage: $0 path/to/file_base (without .wen/.pol/.eng)"
        exit 1
	fi

	base="$1"

	wen_file="${base}.wen.txt"
	pol_file="${base}.pol.txt"
	eng_file="${base}.eng.txt"

	# Validate files
	missing=0

	if [ ! -f "$wen_file" ]; then
	    echo "Missing: $wen_file"
	        missing=1
		fi

		if [ ! -f "$pol_file" ]; then
		    echo "Missing: $pol_file"
		        missing=1
			fi

			if [ ! -f "$eng_file" ]; then
			    echo "Missing: $eng_file"
			        missing=1
				fi

				if [ "$missing" -ne 0 ]; then
				    exit 1
				    fi

				    # Display
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
