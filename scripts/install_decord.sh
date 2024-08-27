#!/bin/bash
# This script is meant to be run at buildtime. Installing decord on different platforms
#
if ! [[ "$TARGETPLATFORM" ]]; then
  echo ERROR environment var TARGETPLATFORM is undefined
  exit 1
fi

if [[ "$TARGETPLATFORM" != "linux/arm64" ]]; then
  # https://github.com/georgia-tech-db/eva-decord is a fork of decord that works on arm platform
  pip3 --no-cache-dir install --upgrade eva-decord==0.6.1
else
  pip3 --no-cache-dir install --upgrade decord==0.6.0
fi

