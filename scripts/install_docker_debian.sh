#!/bin/bash
# This script is only tested in Aarch64 Debian 5.x
#
# install docker infrastructure on aarch64 debian 5.x

# remove old versions
sudo dpkg --remove --force-remove-reinstreq docker-ce docker-ce-rootless-extras
sudo apt-get remove docker docker-engine docker.io containerd runc

# set environment
sudo apt install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg2 \
    software-properties-common
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=arm64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
sudo apt-cache policy docker-ce

sudo apt-get update
# install docker-ce
sudo apt install -y --no-install-recommends docker-ce

