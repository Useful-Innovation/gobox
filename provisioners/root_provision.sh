#!/bin/bash
cd /home/vagrant/.gobox
source temp/config.bash

LOGTITLE="----- Provisioning [root:provision]"
echo "${LOGTITLE}"

apt-get update
apt-get install libapache2-mod-php
