#!/bin/bash

mkdir -p "$1"
# shellcheck disable=SC2164
cd "$1"
rm -rf python
mkdir python
cat "$2"
pip3 install -r "$2" -t python/
zip -r ../"$3" python