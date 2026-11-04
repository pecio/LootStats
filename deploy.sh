#!/bin/bash
if [[ -x "/usr/bin/realpath" && -x "/usr/bin/basename" ]]
then
  PROJECT="$(/usr/bin/basename "$(/usr/bin/realpath .)")"
else
  PROJECT=LootStats
fi
if [[ -z "${WOW_HOME}" ]]
then
  if [[ "$(uname -s)" = "Linux" && "$(uname -r | awk -F- '{ print $NF; }')" = "WSL2" ]] 
  then
    WOW_HOME="/mnt/c/Program Files (x86)/World of Warcraft"
  elif [[ "$(uname -s)" = "Darwin" ]]
  then
    WOW_HOME="/Applications/World of Warcraft"
  fi
fi
if [[ ! -d "${WOW_HOME}" ]]
then
  echo "Cannot use ${WOW_HOME} as destination, please set WOW_HOME environment variable" >&2
  exit 1
fi

for EDITION in "${WOW_HOME}"/_*_; do
  if [[ -d "${EDITION}/Interface/AddOns" ]]
  then
    TARGET="${EDITION}/Interface/AddOns/${PROJECT}"


    if [[ ! -f "${PROJECT}.toc" ]]
    then
      echo "Run from project directory" >&2
      exit 1
    fi

    if [[ -x "/usr/bin/realpath" && "$(/usr/bin/realpath .)" = "${TARGET}" ]]
    then
      echo "Nothing to do, already at ${TARGET}" >&2
      continue
    fi

    /usr/bin/rsync -rti --exclude .git \
      --exclude .gitignore \
      --exclude deploy.sh \
      --delete \
      ./ "${TARGET}/" | sed -e "s!^[>.c][a-z.+]* !${TARGET}/!"
  else
   echo "No AddOns directory found in ${EDITION}" >&2
  fi
done
