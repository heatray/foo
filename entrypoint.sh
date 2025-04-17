#!/usr/bin/env bash

git clone --depth 1 git@github.com:ONLYOFFICE/build_tools.git
git clone --depth 1 git@github.com:ONLYOFFICE/onlyoffice.git
cd build_tools
./configure.py \
  --module "core" \
  --platform linux_64 \
  --update true \
  --clean true \
  --branding onlyoffice
./make.py
