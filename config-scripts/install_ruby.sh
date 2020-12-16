#!/bin/bash

echo
echo ---------------------------
echo Installing Ruby and Bundler
echo ---------------------------

sudo apt update && \
sudo apt install -y ruby-full ruby-bundler build-essential && \
ruby -v && \
bundler -v
RC=$?

echo ---------------------------

if [ "$RC" -eq 0 ]; then
  echo "Ruby and Bundler are installed!"
  exit 0;
else
  echo "Installation is not successful! Please read the output."
  exit 1;
fi
