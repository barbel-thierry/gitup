#!/bin/bash

SIMPLE_FOLDER=()

for folder in */
do
  if [ -e "$folder/.git" ]; then
    echo "$folder"
    git -C "$folder" pull --rebase
  else
    SIMPLE_FOLDER+=("$folder")
  fi
done

echo "These are not GIT repositories: ${SIMPLE_FOLDER[*]}"
