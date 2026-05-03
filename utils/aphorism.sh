#!/bin/bash

num=$(shuf -i 1-353 -n1)
padded=$(printf "%03d" "$num")

echo "Generated number: $padded"

files=$(find corpus/steenbergen/sample_texts/aphorisms -name "*$padded*")

if [ -z "$files" ]; then
  echo "No matching files found."
  else
    echo "$files" | xargs cat
    fi
