#!/bin/bash

# Usage: ./script.sh lang [grep_flags...] "regex"
# Example: ./script.sh wen -i "potrze"

lang="$1"
regex="${@: -1}"
grep_flags=("${@:2:$#-2}")

base_dir="corpus"

if [[ $# -lt 2 || -z "$lang" || -z "$regex" ]]; then
  echo "Usage: $0 [wen|pol|eng] [grep_flags...] \"regex\""
    exit 1
    fi

    # Determine extensions
    search_ext="$lang.txt"

    # Always show all 3, but order depends on search language
    if [[ "$lang" == "wen" ]]; then
      other_langs=("pol" "eng")
      else
        other_langs=("wen")
	  for l in pol eng; do
	      [[ "$l" != "$lang" ]] && other_langs+=("$l")
	        done
		fi

		# Find matching files
		grep -rl "${grep_flags[@]}" --include="*.$search_ext" -e "$regex" "$base_dir" | while read -r file; do
		  echo "=================================================="
		    echo "MATCH FILE: $file"
		      echo "=================================================="

		        # Show full file with highlighted matches + line numbers
			  grep -n --color=always "${grep_flags[@]}" -e "$regex" "$file" | sed 's/^/MATCH: /'
			    echo

			      echo "----- FULL FILE (with highlights) -----"
			        nl -ba "$file" | GREP_COLOR='01;31' grep --color=always -E "$regex|$"
				  echo

				    # Extract base name (remove language suffix)
				      base="${file%.*.*}"

				        # Show translations
					  for l in "${other_langs[@]}"; do
					      trans_file="$base.$l.txt"
					          echo "----- TRANSLATION: $trans_file -----"

						      if [[ -f "$trans_file" ]]; then
						            nl -ba "$trans_file"
							        else
								      echo "[missing]"
								          fi
									      echo
									        done

										done
