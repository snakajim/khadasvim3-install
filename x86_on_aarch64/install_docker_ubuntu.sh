#!/bin/bash
# This script is only tested in Aarch64 Ubuntu 20.04 LTS(LK)
# 
# SYNOPSYS:
# Install docker infrastructure to run x86 container on aarch64
#

# -----
# remove old docker versions
# -----
sudo dpkg --remove --force-remove-reinstreq docker-ce docker-ce-rootless-extras
sudo apt-get remove docker docker-engine docker.io containerd runc
sudo apt -y autoremove

# -----
# set environment and install docker-ce
# -----
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
	"deb [arch=arm64] https://download.docker.com/linux/ubuntu \
	$(lsb_release -cs) \
	stable"
sudo apt update
sudo apt-cache policy docker-ce
sudo apt-get install -y --no-install-recommends docker-ce docker-ce-cli containerd.io

# -----
# add users and systemctl
# -----
sudo gpasswd -a $USER docker
sudo chmod 666 /var/run/docker.sock
sudo systemctl start docker
sudo systemctl enable docker
docker images 
docker run hello-world

#
# set docker buildx
#

mkdir -p ${HOME}/.docker/cli-plugins && cd ${HOME}/.docker/cli-plugins && \
 aria2c -x8 https://github.com/docker/buildx/releases/download/v0.5.1/buildx-v0.5.1.linux-arm64 -o docker-buildx && \
 chmod a+x ${HOME}/.docker/cli-plugins/docker-buildx

if [ -z "${DOCKER_CLI_EXPERIMENTAL}" ]; then
  export DOCKER_CLI_EXPERIMENTAL=enabled
  echo "# set docker buildx" >> ${HOME}/.bashrc 
  echo "export DOCKER_CLI_EXPERIMENTAL=enabled" >> ${HOME}/.bashrc
fi

cd ${HOME}/tmp && git clone git://github.com/docker/buildx && cd buildx && make install


# -----
# Dynamic Binary Hardware Injection (DBHI) qemu-user-static (qus)
# https://github.com/dbhi/qus
# -----
sudo apt install qemu-user-static

# pull images
docker pull amd64/ubuntu
docker pull arm64v8/ubuntu
# test
docker system prune -f
docker run --rm --privileged aptman/qus -s -- -p amd64
echo `docker run --rm -t amd64/ubuntu uname -m` | grep x86_64
echo `docker run --rm -t arm64v8/ubuntu uname -m` | grep aarch64


# -----------
# build x86_64 docker container on aarch64 linux 
# -----------
sudo apt install subversion -y
cd ${HOME}/work && svn export  https://github.com/ARM-software/Tool-Solutions/trunk/docker/tensorflow-lite-micro-rtos-fvp
sed -i 's/FROM ubuntu/FROM amd64\/ubuntu/' ${HOME}/work/tensorflow-lite-micro-rtos-fvp/docker/*.Dockerfile
cd ${HOME}/work/tensorflow-lite-micro-rtos-fvp && chmod +x -R * && ./docker_build.sh -c gcc

