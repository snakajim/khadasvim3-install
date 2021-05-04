#!/bin/bash
# This script is only tested in Aarch64 Ubuntu 20.04 LTS(LK4.7)
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

# -------------------------------------
# set environment and install docker-ce
# -------------------------------------
sudo apt-get update
sudo apt-get install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
	"deb [arch=arm64] https://download.docker.com/linux/ubuntu \
	$(lsb_release -cs) \
	stable"
# For Ubuntu 20.04
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

# -------------------------------------
# set docker buildx
# this is optional, you can skip it.
# -------------------------------------

#mkdir -p ${HOME}/.docker/cli-plugins && cd ${HOME}/.docker/cli-plugins && \
# aria2c -x8 https://github.com/docker/buildx/releases/download/v0.5.1/buildx-v0.5.1.linux-arm64 -o docker-buildx && \
# chmod a+x ${HOME}/.docker/cli-plugins/docker-buildx
#if [ -z "${DOCKER_CLI_EXPERIMENTAL}" ]; then
#  export DOCKER_CLI_EXPERIMENTAL=enabled
#  echo "# set docker buildx" >> ${HOME}/.bashrc 
#  echo "export DOCKER_CLI_EXPERIMENTAL=enabled" >> ${HOME}/.bashrc
#fi
#cd ${HOME}/tmp && rm -rf buildx && git clone git://github.com/docker/buildx && cd buildx && make install


# -------------------------------------
# Docker multiarch/qemu-user-static
# https://hub.docker.com/r/multiarch/qemu-user-static
#
# Known issue: 
# Segmentation Fault at libc-bin installation at 
# Ubuntu 18.04 and 20.04 on x86_64.
# To avoid errors, use DBHI qus instead.             
# -------------------------------------
#sudo apt install -y qemu-user-static
#docker run --rm --privileged multiarch/qemu-user-static:register --reset
#docker run --rm --privileged multiarch/qemu-user-static:register

# -------------------------------------
# Dynamic Binary Hardware Injection (DBHI) qemu-user-static (qus)
# https://github.com/dbhi/qus
#
# This is alternative way to emulate x86_64 on aarch64. 
# If docker multiarch does not work properly, use this instead. 
# -------------------------------------
sudo apt install -y qemu-user-static
docker run --rm --privileged aptman/qus -- -r
docker run --rm --privileged aptman/qus -s -- -p x86_64

# pull images
# Ubuntu 16.04 LTS
docker pull multiarch/ubuntu-core:amd64-xenial
docker pull multiarch/ubuntu-core:arm64-xenial
# Ubuntu 18.04 LTS
docker pull multiarch/ubuntu-core:amd64-bionic
docker pull multiarch/ubuntu-core:arm64-bionic
# Ubuntu 20.04 LTS
docker pull multiarch/ubuntu-core:amd64-focal
docker pull multiarch/ubuntu-core:arm64-focal
# test
docker system prune -f
docker run --rm -t multiarch/ubuntu-core:amd64-bionic uname -m
sleep 10
docker run --rm -t multiarch/ubuntu-core:arm64-bionic uname -m
sleep 10


# -------------------------------------
# build x86_64 docker container on aarch64 linux 
# -------------------------------------
docker system prune -f
sudo apt install subversion -y
if [ -d ${HOME}/work/tensorflow-lite-micro-rtos-fvp ]; then
  echo "tensorflow-lite-micro-rtos-fvp already exists."
else
  cd ${HOME}/work && svn export  https://github.com/ARM-software/Tool-Solutions/trunk/docker/tensorflow-lite-micro-rtos-fvp
fi
# use Ubuntu 16.04 LTS(xenial) if you face libc-bin issue
sed -i 's/FROM ubuntu:18.04/FROM multiarch\/ubuntu-core:amd64-bionic/' ${HOME}/work/tensorflow-lite-micro-rtos-fvp/docker/*.Dockerfile
sed -i 's/apt-get -y update/apt-get -y update \&\& apt-get install -y software-properties-common/' ${HOME}/work/tensorflow-lite-micro-rtos-fvp/docker/*.Dockerfile 
chmod +x -R ${HOME}/work/tensorflow-lite-micro-rtos-fvp/*
cd ${HOME}/work/tensorflow-lite-micro-rtos-fvp && ./docker_build.sh -c gcc

