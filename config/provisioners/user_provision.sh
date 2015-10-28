#!/bin/bash
cd /home/vagrant/config
source config.bash

LOGTITLE="----- Provisioning [user:provision]"
echo "${LOGTITLE}"

# source /home/vagrant/code/.provision/config

# Include our bash scripts
grep -q -F 'source ~/config/bash' ~/.bashrc || echo 'source ~/config/bash' >> ~/.bashrc

echo "${LOGTITLE} Update composer..."
composer -q self-update

echo "${LOGTITLE} Add github RSA key..."
ssh-keyscan github.com >> ~/.ssh/known_hosts
