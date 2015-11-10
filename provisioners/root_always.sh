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
for i in "${VAGRANT_DATABASES[@]}"
do
    mysql -uroot -proot -e "CREATE DATABASE IF NOT EXISTS \`$i\` CHARACTER SET utf8 COLLATE utf8_swedish_ci"
done

service apache2 reload