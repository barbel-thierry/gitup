#!/bin/bash

NON_GIT_REPO=()
NON_MASTER_BRANCH=()
ERRORS=()
UPDATED_REPOS=0
TOTAL_REPOS=0
ALREADY_UP_TO_DATE=0
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NO_COLOR='\033[0m'

for folder in */; do
  if [[ -e "$folder/.git" ]]; then
    ((TOTAL_REPOS++))
    echo "$folder"
    branch="$(git -C "$folder" rev-parse --abbrev-ref HEAD)"

    if [[ "$branch" != "master" && "$branch" != "main" ]]; then
      NON_MASTER_BRANCH+=("$folder")
      continue
    fi

    result=$(git -C "$folder" pull --rebase 2>&1)

    if [[ $result == *"Already up to date."* ]]; then
      ((ALREADY_UP_TO_DATE++))
    elif [[ $result == *"Updating"* ]]; then
      echo -e "${GREEN}$result${NO_COLOR}"
      ((UPDATED_REPOS++))
    elif [[ $result == *"error"* || $result == *"fatal"* ]]; then
      echo -e "${RED}$result${NO_COLOR}"
      ERRORS+=("$folder")
    else
      echo "$result"
    fi
  else
    NON_GIT_REPO+=("$folder")
  fi
done

if [[ ${#NON_GIT_REPO[@]} -ne 0 ]]; then
  printf "\n"
  echo -e "${YELLOW}Not GIT repositories:${NO_COLOR} ${NON_GIT_REPO[*]}"
fi

if [[ ${#NON_MASTER_BRANCH[@]} -ne 0 ]]; then
  printf "\n"
  echo -e "${YELLOW}Not on branch master/main:${NO_COLOR} ${NON_MASTER_BRANCH[*]}"
fi

if [[ ${#ERRORS[@]} -ne 0 ]]; then
  printf "\n"
  echo -e "${RED}Not updatable:${NO_COLOR} ${ERRORS[*]}"
fi

printf "\n%s repositories:\n${GREEN}%s updated\n%s already up-to-date${NO_COLOR}\n" "$TOTAL_REPOS" "$UPDATED_REPOS" "$ALREADY_UP_TO_DATE"
