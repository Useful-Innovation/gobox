#!/bin/bash
cd /home/vagrant/config
source config.bash

LOGTITLE="----- Provisioning [root:always]"
echo "${LOGTITLE}"

echo "${LOGTITLE} Deleting vhosts"
rm -f /etc/apache2/sites-enabled/*

echo "${LOGTITLE} Creating vhosts"
cp vhosts/* /etc/apache2/sites-enabled/

service apache2 reload