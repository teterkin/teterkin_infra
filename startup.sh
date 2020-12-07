#!/bin/bash

echo
wget https://gist.githubusercontent.com/teterkin/60e28fc2842a32b73eda06b42a0f83f3/raw/6ea0adf082200ad97a9a0bd94b7c039686950c06/install_ruby.sh && \
chmod +x install_ruby.sh && \
./install_ruby.sh && \
wget https://gist.githubusercontent.com/teterkin/25d0dcd2390bb8d216577f50c83c1403/raw/2be2b3d3a37af1b32c2afb2b9ecf4f7fa675f182/install_mongodb.sh && \
chmod +x install_mongodb.sh && \
./install_mongodb.sh && \
wget https://gist.githubusercontent.com/teterkin/e397b5fe355da5887d3c42c9a0bf1576/raw/c32747597f8dfa40b076b96c97ca684b553308a8/deploy.sh && \
chmod +x deploy.sh && \
./deploy.sh
RC=$?

if [ "$RC" -eq 0 ]; then
  echo "Deployment is complete. Done."
  exit 0;
else
  echo "ERROR. Exiting..."
  exit 1;
fi
