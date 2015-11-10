#!/bin/bash
cd /home/vagrant/.gobox
source temp/config.bash

LOGTITLE="----- Provisioning [root:always]"
echo "${LOGTITLE}"

echo "${LOGTITLE} Deleting vhosts"
rm -f /etc/apache2/sites-enabled/*

echo "${LOGTITLE} Creating vhosts"
cp temp/vhosts/* /etc/apache2/sites-enabled/

echo "${LOGTITLE} Creating databases"
databases=(${VAGRANT_DATABASES//,/ })
for i in "${!databases[@]}"
do
    mysql -uroot -proot -e "CREATE DATABASE IF NOT EXISTS \`${databases[i]}\` CHARACTER SET utf8 COLLATE utf8_swedish_ci"
done

service apache2 reload