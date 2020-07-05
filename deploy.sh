#!/bin/bash
WOW="/Applications/World of Warcraft"
ADDON="$(basename "$PWD")"
/usr/bin/rsync -av . --exclude=.git "${WOW}/Interface/AddOns/${ADDON}/"
