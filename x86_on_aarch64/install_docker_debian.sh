#!/bin/bash
# This script is only tested in Aarch64 Debian 10 LTS(LK5.)
# 
# SYNOPSYS:
# Install docker infrastructure to run x86 container on aarch64
#

pushd ./

# -------------------------------------
# remove old docker versions
# -------------------------------------
sudo dpkg --remove --force-remove-reinstreq docker-ce docker-ce-rootless-extras
sudo apt-get remove docker docker-engine docker.io containerd runc
sudo apt -y autoremove

#
# extra trick to enable bitfmt_misc module
# http://wizardyhnr.blogspot.com/2016/04/how-to-build-cross-compliatio.html
#
# see if you have bitfmt_misc.ko module
#  /lib/modules/5.12.0/kernel/fs/

# -------------------------------------
# set environment and install docker-ce
# -------------------------------------
sudo apt-get update
sudo apt-get install apt-transport-https ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=arm64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# For Debian 10
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io
sudo groupadd docker
sudo usermod -aG docker $USER
sudo chmod 666 /var/run/docker.sock
sudo systemctl enable docker
sudo systemctl start docker

# clean up all local images and hello world
docker images -aq | xargs docker rmi
docker images 
docker run hello-world

