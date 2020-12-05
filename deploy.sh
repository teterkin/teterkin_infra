#!/bin/bash

echo -----------------------------------------------------
echo Installing Dependancies and Deploying the Application
echo -----------------------------------------------------

CHECK=$(ps -ef | grep -v grep | grep -c puma)
if [ "$CHECK" -ge 1 ]; then
  echo "Puma is running already. Exiting..."
  exit 0
fi

git clone -b monolith https://github.com/express42/reddit.git && \
cd reddit && \
ls && \
bundle install && \
ls && \
puma -d && \
PUMA=$(ps -ef | grep -v grep | grep puma) && \
PORT=$(echo $PUMA | awk -F: '{ print substr($6,1,4) }')
RC=$?

echo "Checking if Puma server is running:"
echo ${PUMA}
echo "Puma server port number is [${PORT}]."

echo -----------------------------------------------------

if [ "$RC" -eq 0 ]; then
  echo "Application is deployed!"
  exit 0;
else
  echo "Deployment was not successful! Please read the output."
  exit 1;
fi
