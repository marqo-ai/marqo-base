#!/bin/bash
# This script is meant to be run at buildtime. Installing decord on different platforms
#
if ! [[ "$TARGETPLATFORM" ]]; then
  echo ERROR environment var TARGETPLATFORM is undefined
  exit 1
fi

if [[ "$TARGETPLATFORM" != "linux/arm64" ]]; then
  pip3 --no-cache-dir install --upgrade decord==0.6.0
fi
# https://github.com/georgia-tech-db/eva-decord is a fork of decord that only works on macos
# And there isn't any version working for linux/arm64 for now: https://github.com/dmlc/decord/issues/297
# pip3 --no-cache-dir install --upgrade eva-decord==0.6.1


