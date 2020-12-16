#!/bin/bash

echo
echo -------------------------------
echo Starting my VM made with Packer
echo -------------------------------

echo Adding firewall rule...

PUMA=$(gcloud compute firewall-rules list 2>/dev/null | grep -c default-puma)

if [ "$PUMA" -ne 1 ]; then

  gcloud compute firewall-rules create default-puma-server \
    --allow='tcp:9292' \
    --target-tags='puma-server' \
    --source-ranges='0.0.0.0/0' \
    --direction='INGRESS' \
    --network='default'
else
  echo "Firewall already exist."
fi

echo Creating VM...

gcloud compute instances create reddit-app\
  --boot-disk-size=20GB \
  --image=reddit-full-1608151595 \
  --machine-type=f1-micro \
  --tags=puma-server \
  --restart-on-failure \
  --zone=europe-west1-b

RC=$?

if [ "$RC" -eq 0 ]; then
  echo "Application started successfully!"
  exit 0;
else
  echo "Startup was not successful! Please read the output."
  exit 1;
fi
