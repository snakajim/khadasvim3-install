#!/bin/bash
# This script is only tested in Aarch64 Ubuntu 20
#
# install docker infrastructure on aarch64 Ubuntu 20puri

# remove old versions
sudo dpkg --remove --force-remove-reinstreq docker-ce docker-ce-rootless-extras
sudo apt-get remove docker docker-engine docker.io containerd runc
sudo apt -y autoremove

# set environment
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
	"deb [arch=arm64] https://download.docker.com/linux/ubuntu \
	$(lsb_release -cs) \
	stable"
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
sudo systemctl enable docker
docker images 
docker run hello-world

#
# build docker container 
#
sudo apt install subversion -y
cd ${HOME}/work
svn export  https://github.com/ARM-software/Tool-Solutions/trunk/docker/tensorflow-lite-micro-rtos-fvp
cd tensorflow-lite-micro-rtos-fvp && chmod +x -R *
./docker_build.sh -c gcc

