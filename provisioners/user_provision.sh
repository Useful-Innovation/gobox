#!/bin/bash
cd /home/vagrant/.gobox
source temp/config.bash

LOGTITLE="----- Provisioning [user:provision]"
echo "${LOGTITLE}"

# source /home/vagrant/code/.provision/config

# Include our bash scripts
grep -q -F 'source ~/.gobox/resources/bash' ~/.bashrc || echo 'source ~/.gobox/resources/bash' >> ~/.bashrc

echo "${LOGTITLE} Update composer..."
composer -q self-update

echo "${LOGTITLE} Add github RSA key..."
ssh-keyscan github.com >> ~/.ssh/known_hosts
