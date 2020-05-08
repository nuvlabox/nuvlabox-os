#!/bin/sh

apt-get update
apt-get install -y $(echo $(cat requirements.apt))

# install docker and docker-compose 1.23+ , run in swarm mode

# might defer depending on the systemd-udev installed:
sed -i 's/PrivateMounts=yes/PrivateMounts=no/' /lib/systemd/system/systemd-udevd.service

systemctl daemon-reload
systemctl restart systemd-udevd

# Beware of the acceptable filesystem types by usbmount