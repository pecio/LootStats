#!/bin/bash
if [[ -x "/usr/bin/realpath" -a -x "/usr/bin/basename" ]]
then
  PROJECT="$(/usr/bin/basename "$(/usr/bin/realpath .)")"
else
  PROJECT=LootStats
fi
if [[ -z "${WOW_HOME}" ]]
then
  if [[ "$(uname -s)" = "Linux" -a "$(uname -r | awk -F- '{ print $NF; }')" = "WSL2" ]] 
  then
    WOW_HOME="/mnt/c/Program Files (x86)/World of Warcraft/_retail_"
  elif [[ "$(uname -s)" = "Darwin" ]]
  then
    WOW_HOME="/Applications/World of Warcraft/_retail_"
  fi
fi
if [[ ! -d "${WOW_HOME}" ]]
then
  echo "Cannot use ${WOW_HOME} as destination, please set WOW_HOME environment variable" >&2
  exit 1
fi
TARGET="${WOW_HOME}/Interface/AddOns/${PROJECT}"

if [[ ! -f "${PROJECT}.toc" ]]
then
  echo "Run from project directory" >&2
  exit 1
fi

if [[ -x "/usr/bin/realpath" -a "$(/usr/bin/realpath .)" = "${TARGET}" ]]
then
  echo "Nothing to do, already at ${TARGET}" >&2
  exit 0
fi

/usr/bin/rsync -av --exclude .git \
	--exclude .gitignore \
	--exclude deploy.sh \
	./ "${TARGET}/"
