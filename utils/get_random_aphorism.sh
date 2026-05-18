#!/bin/bash

num=$(shuf -i 1-353 -n1)
padded=$(printf "%03d" "$num")

echo "Generated number: $padded"

shopt -s nullglob
files=( corpus/steenbergen/sample_texts/aphorisms/*"$padded"* )

if [ ${#files[@]} -eq 0 ]; then
  echo "No matching files found."
else
  cat "${files[@]}"
fi
