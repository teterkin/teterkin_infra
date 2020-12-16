#!/bin/bash

echo
echo -----------------------------------------------------
echo Installing Dependancies and Deploying the Application
echo -----------------------------------------------------

CHECK=$(ps -ef | grep -v grep | grep -c puma)
if [ "$CHECK" -ge 1 ]; then
  echo "Puma is running already. Exiting..."
  exit 0
fi

git clone -b monolith https://github.com/express42/reddit.git && \
whoami && \
pwd && \
cd reddit && \
mkdir log && \
ls && \
bundle install && \
ls && \
mv /home/appuser/production.rb /home/appuser/reddit/config/deploy/ && \
sudo mv /home/appuser/puma.service /etc/systemd/system/ && \
sudo systemctl daemon-reload && \
sudo systemctl enable puma && \
sudo service puma start && \
echo "Waiting 3 seconds for service stabilization..." && \
sleep 3 && \
sudo systemctl status puma --no-pager && \
PUMA=$(ps -ef | grep -v grep | grep puma)
RC=$?

if [ "$RC" -eq 0 ]; then
  echo "Checking if Puma server is running:"
  echo ${PUMA}
  echo "Puma server port number is [9292]."
  echo -----------------------------------------------------
  echo "Application is deployed!"
  exit 0;
else
  echo -----------------------------------------------------
  echo "Deployment was not successful! Please read the output."
  exit 1;
fi
