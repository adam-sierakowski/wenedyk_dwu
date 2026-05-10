#!/bin/bash

num=$(shuf -i 1-353 -n1)
padded=$(printf "%03d" "$num")

echo "Generated number: $padded"

files=()
while IFS= read -r -d '' f; do
  files+=("$f")
done < <(find corpus/steenbergen/sample_texts/aphorisms -name "*$padded*" -print0)

if [ ${#files[@]} -eq 0 ]; then
  echo "No matching files found."
else
  cat "${files[@]}"
fi
