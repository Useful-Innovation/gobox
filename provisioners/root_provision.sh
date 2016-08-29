#!/bin/bash
cd /home/vagrant/.gobox
source temp/config.bash

LOGTITLE="----- Provisioning [root:provision]"
echo "${LOGTITLE}"

apt-get install -yqq debconf-utils


if ! [ -f /usr/bin/php5 ]; then
    echo "${LOGTITLE} Install server components"
    # Set these to prevent mysql-server installation from prompting for root password.
    export DEBIAN_FRONTEND=noninteractive
    sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
    sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'

    apt-get update
fi

apt-get install -yqq \
    apache2 \
    php5 \
    mysql-server-${VAGRANT_MYSQL_VERSION} \
    php5-mysql \
    php5-curl \
    php5-gd \
    php5-xdebug \
    php5-mcrypt \

    # Set up xdebug
    PHP_INI=/etc/php5/apache2/php.ini
    grep -q -F 'zend_extension=xdebug.so' $PHP_INI || echo -e '\n\nzend_extension=xdebug.so' >> $PHP_INI

    a2enmod rewrite
    php5enmod mcrypt

echo "${LOGTITLE} Setting xdebug.max_nesting_level"
grep -q -F 'xdebug.max_nesting_level=500' /etc/php5/mods-available/xdebug.ini || echo 'xdebug.max_nesting_level=500' >> /etc/php5/mods-available/xdebug.ini

echo "${LOGTITLE} Setting xdebug.remote_enable"
grep -q -F 'xdebug.remote_enable=on' /etc/php5/mods-available/xdebug.ini || echo 'xdebug.remote_enable=on' >> /etc/php5/mods-available/xdebug.ini

echo "${LOGTITLE} Setting xdebug.remote_connect_back"
grep -q -F 'xdebug.remote_connect_back=on' /etc/php5/mods-available/xdebug.ini || echo 'xdebug.remote_connect_back=on' >> /etc/php5/mods-available/xdebug.ini

echo "${LOGTITLE} Setting xdebug.idekey"
grep -q -F 'xdebug.idekey="vagrant"' /etc/php5/mods-available/xdebug.ini || echo 'xdebug.idekey="vagrant"' >> /etc/php5/mods-available/xdebug.ini

if ! [ -f /usr/bin/git ]; then
    echo "${LOGTITLE} Install server tools"
    apt-get install -yqq \
        git
fi

if ! [ -f /usr/bin/node ]; then
    echo "${LOGTITLE} Install node packages"
    curl -sL https://deb.nodesource.com/setup_4.x | sudo -E bash -
    sudo apt-get install -yqq nodejs
    npm install -g grunt-cli --silent
    npm install -g bower --silent
fi

echo "${LOGTITLE} Install locales"
locale-gen en_US en_US.UTF-8 sv_SE sv_SE.UTF-8
dpkg-reconfigure locales

if ! [ -f /usr/local/bin/composer ]; then
    echo "${LOGTITLE} Install composer"
    curl -sS https://getcomposer.org/installer | php
    mv composer.phar /usr/local/bin/composer
    chmod +x /usr/local/bin/composer
fi
