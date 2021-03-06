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
sudo apt-get -y remove docker docker-engine docker.io containerd runc
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
sudo apt-get -y update
sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
	"deb [arch=arm64] https://download.docker.com/linux/ubuntu \
	$(lsb_release -cs) \
	stable"
# For Ubuntu 20.04
sudo apt-get -y update
sudo apt-get -y install docker-ce docker-ce-cli containerd.io
sudo groupadd docker
sudo usermod -aG docker $USER
sudo chmod 666 /var/run/docker.sock
sudo systemctl enable docker
sudo systemctl start docker
sudo mount -n -o remount,suid /var/lib/docker

# clean up all local images and hello world
docker images -aq | xargs docker rmi
docker images 
docker run hello-world

mount | grep binfmt_misc
RET=$?
if [ $RET eq 1 ]; then
	echo "binfmt_misc is not mounted."
	echo "See also, $> sudo systemctl status proc-sys-fs-binfmt_misc.mount"
	echo "Maybe you cannot load module, try $> sudo modprobe binfmt_misc"
	echo "Kernel module binfmt_misc.ko is missing under /lib/modules."
	echo "Once you copy the module from somewhere. copy or link under kernel/fs then"
	echo "$> sudo depmod -a"
	echo "$> sudo modprobe binfmt_misc "
	echo "So that aptman/qus may fail. Program exit."
	sleep 5
	exit
fi

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
echo "Docker install completed. Reboot in 10 sec."
sudo reboot