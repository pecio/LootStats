#! /bin/sh
PROJECT=LootStats
if [ -z "${WOW_HOME}" ]
then
  if [ "`uname -s`" = "Linux" ]
  then
    WOW_HOME="/mnt/c/Program files (x86)/World of Warcraft/_retail_"
  elif [ "`uname -s`" = "Darwin" ]
  then
    WOW_HOME="/Applications/World of Warcraft/_retail_"
  fi
fi
if [ ! -d "${WOW_HOME}" ]
then
  echo "Cannot use ${WOW_HOME} as destination, please set WOW_HOME environment variable" >&2
  exit 1
fi
if [ ! -f "${PROJECT}.toc" ]
then
  echo "Run from project directory" >&2
  exit 1
fi
/usr/bin/rsync -av --exclude .git \
	--exclude .gitignore \
	--exclude deploy.sh \
	./ "${WOW_HOME}/Interface/AddOns/${PROJECT}/"
