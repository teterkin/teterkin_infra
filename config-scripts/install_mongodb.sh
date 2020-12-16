#!/bin/bash

echo
echo -------------------------------
echo Installing and Starting MongoDB
echo -------------------------------

sudo rm /etc/apt/sources.list.d/mongodb*.list
sudo apt install apt-transport-https
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv D68FA50FEA312927 && \
echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.2.list && \
sudo apt update && \
sudo apt install -y mongodb-org && \
sudo systemctl start mongod && \
sudo systemctl enable mongod && \
sudo systemctl status mongod
RC=$?

echo -------------------------------

if [ "$RC" -eq 0 ]; then
  echo "MongoDB is installed, started and it's service is enabled!"
  exit 0;
else
  echo "Installation was not successful! Please read the output."
  exit 1;
fi
