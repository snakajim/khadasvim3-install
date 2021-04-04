#!/bin/bash
# This script is only tested in Aarch64 Debian 5.x
#
# install docker infrastructure on aarch64 debian 5.x

# remove old versions
sudo dpkg --remove --force-remove-reinstreq docker-ce docker-ce-rootless-extras
sudo apt-get remove docker docker-engine docker.io containerd runc
sudo apt -y autoremove

# set environment
sudo apt install -y\
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg2 \
    software-properties-common
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=arm64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt-cache policy docker-ce

#
#install docker-ce
#
#sudo apt-get install -y docker-ce=5:19.03.15~3-0~debian-buster docker-ce-cli=5:19.03.15~3-0~debian-buster containerd.io
#sudo apt-get install -y docker-ce=5:18.09.9~3-0~debian-buster docker-ce-cli=5:18.09.9~3-0~debian-buster containerd.io
#sudo apt-get install -y docker-ce= docker-ce-cli= containerd.io
sudo apt-get install -y --no-install-recommends docker-ce docker-ce-cli containerd.io
#sudo apt install -y --no-install-recommends docker-ce

#
#before run
#
sudo gpasswd -a $USER docker
sudo chmod 666 /var/run/docker.sock

#
# test run
#
docker -v
sudo systemctl start docker
docker images 
docker run hello-world