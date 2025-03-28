#!/bin/bash

NON_GIT_REPO=()
NON_MASTER_BRANCH=()

for folder in */; do
  if [[ -e "$folder/.git" ]]; then
    branch="$(git -C "$folder" rev-parse --abbrev-ref HEAD)"

    if [[ "$branch" != "master" && "$branch" != "main" ]]; then
      NON_MASTER_BRANCH+=("$folder")
      continue
    fi

    echo "$folder"
    git -C "$folder" pull --rebase
  else
    NON_GIT_REPO+=("$folder")
  fi
done

if [[ ${#NON_GIT_REPO[@]} -ne 0 ]]; then
    echo "These are not GIT repositories: ${NON_GIT_REPO[*]}"
fi

if [[ ${#NON_MASTER_BRANCH[@]} -ne 0 ]]; then
    echo "These are not on master/main branch: ${NON_MASTER_BRANCH[*]}"
fi
