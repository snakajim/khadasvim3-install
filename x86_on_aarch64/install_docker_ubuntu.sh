#!/bin/bash
# This script is only tested in Aarch64 Ubuntu 20.04 LTS(LK)
# 
# SYNOPSYS:
# Install docker infrastructure to run x86 container on aarch64
#

# -------------------------------------
# remove old docker versions
# -------------------------------------
sudo dpkg --remove --force-remove-reinstreq docker-ce docker-ce-rootless-extras
sudo apt-get remove docker docker-engine docker.io containerd runc
sudo apt -y autoremove

# -------------------------------------
# set environment and install docker-ce
# -------------------------------------
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
	"deb [arch=arm64] https://download.docker.com/linux/ubuntu \
	$(lsb_release -cs) \
	stable"
sudo apt update
sudo apt-cache policy docker-ce
sudo apt-get install -y --no-install-recommends docker-ce docker-ce-cli containerd.io

# -------------------------------------
# add users and systemctl
# -------------------------------------
sudo systemctl start docker
sudo systemctl enable docker
sudo gpasswd -a $USER docker
sudo chmod 666 /var/run/docker.sock
docker images -aq | xargs docker rmi
docker images 
docker run hello-world

# -------------------------------------
# set docker buildx
# this is optional, you can skip it.
# -------------------------------------

mkdir -p ${HOME}/.docker/cli-plugins && cd ${HOME}/.docker/cli-plugins && \
 aria2c -x8 https://github.com/docker/buildx/releases/download/v0.5.1/buildx-v0.5.1.linux-arm64 -o docker-buildx && \
 chmod a+x ${HOME}/.docker/cli-plugins/docker-buildx

if [ -z "${DOCKER_CLI_EXPERIMENTAL}" ]; then
  export DOCKER_CLI_EXPERIMENTAL=enabled
  echo "# set docker buildx" >> ${HOME}/.bashrc 
  echo "export DOCKER_CLI_EXPERIMENTAL=enabled" >> ${HOME}/.bashrc
fi

cd ${HOME}/tmp && rm -rf buildx && git clone git://github.com/docker/buildx && cd buildx && make install


# -------------------------------------
# Enable docker multi arch
# -------------------------------------
sudo apt install qemu-user-static
docker run --rm --privileged multiarch/qemu-user-static:register

# -------------------------------------
# Dynamic Binary Hardware Injection (DBHI) qemu-user-static (qus)
# https://github.com/dbhi/qus
# -------------------------------------

# pull images
# Ubuntu 16.04 LTS
docker pull multiarch/ubuntu-core:amd64-xenial
docker pull multiarch/ubuntu-core:arm64v8-xenial
# Ubuntu 18.04 LTS
docker pull multiarch/ubuntu-core:amd64-bionic
docker pull multiarch/ubuntu-core:arm64v8-bionic
# test
docker system prune -f
echo `docker run --rm -t amd64/ubuntu uname -m` | grep x86_64
echo `docker run --rm -t arm64v8/ubuntu uname -m` | grep aarch64


# -------------------------------------
# build x86_64 docker container on aarch64 linux 
# -------------------------------------
docker system prune -f
sudo apt install subversion -y
cd ${HOME}/work && svn export  https://github.com/ARM-software/Tool-Solutions/trunk/docker/tensorflow-lite-micro-rtos-fvp
# use Ubuntu 16.04 LTS(xenial) instead to avoid libc-bin issue
sed -i 's/FROM ubuntu:18.04/FROM multiarch\/ubuntu-core:amd64-xenial/' ${HOME}/work/tensorflow-lite-micro-rtos-fvp/docker/*.Dockerfile
#sed -i 's/FROM ubuntu:18.04/FROM multiarch\/ubuntu-core:amd64-bionic/' ${HOME}/work/tensorflow-lite-micro-rtos-fvp/docker/*.Dockerfile
chmod +x -R ${HOME}/work/tensorflow-lite-micro-rtos-fvp/*
cd ${HOME}/work/tensorflow-lite-micro-rtos-fvp && ./docker_build.sh -c gcc

