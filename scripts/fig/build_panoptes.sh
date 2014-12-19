#!/bin/bash -ex
SCRIPT_DIR="`dirname \"$0\"`"
cp -f Dockerfile Dockerfile.orig
cp -f $SCRIPT_DIR/Dockerfile .
fig build
mv -f Dockerfile.orig Dockerfile
