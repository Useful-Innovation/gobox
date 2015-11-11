#!/bin/bash
cd /home/vagrant/.gobox
source temp/config.bash

LOGTITLE="----- Provisioning [root:provision]"
echo "${LOGTITLE}"

apt-get install -yqq debconf-utils

echo "${LOGTITLE} Install server components"

if ! hash php5 2>/dev/null; then
    # Set these to prevent mysql-server installation from prompting for root password.
    export DEBIAN_FRONTEND=noninteractive
    sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
    sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'

    apt-get update
    apt-get install -yqq \
        apache2=${VAGRANT_APACHE_VERSION} \
        php5=${VAGRANT_PHP_VERSION} \
        mysql-server=${VAGRANT_MYSQL_VERSION} \
        php5-mysql \
        php5-curl \
        php5-gd \
        php5-xdebug

        # Set up xdebug
        PHP_INI=/etc/php5/apache2/php.ini
        grep -q -F 'zend_extension=xdebug.so' $PHP_INI || echo -e '\n\nzend_extension=xdebug.so' >> $PHP_INI

        a2enmod rewrite
fi

echo "${LOGTITLE} Install server tools"
if ! hash git 2>/dev/null; then
    apt-get install -yqq \
        git
fi

echo "${LOGTITLE} Install node packages"
if ! hash node 2>/dev/null; then
    curl -sL https://deb.nodesource.com/setup_4.x | sudo -E bash -
    sudo apt-get install -yqq nodejs
    npm install -g grunt-cli --silent
    npm install -g bower --silent
fi

echo "${LOGTITLE} Install locales"
locale-gen en_US en_US.UTF-8 sv_SE sv_SE.UTF-8
dpkg-reconfigure locales

echo "${LOGTITLE} Install composer"
if ! hash /usr/local/bin/composer 2>/dev/null; then
    curl -sS https://getcomposer.org/installer | php
    mv composer.phar /usr/local/bin/composer
    chmod +x /usr/local/bin/composer
fi
