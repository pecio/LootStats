#! /bin/sh
PROJECT=LootStats
if [ -z "${WOW_HOME}" ]
then
  WOW_HOME="/mnt/c/Program files (x86)/World of Warcraft/_retail_"
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
