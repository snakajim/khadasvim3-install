#!/bin/bash
# SYNOPSYS
#
#
# REFERENCE
# https://github.com/khadas/fenix
# git clone https://github.com/khadas/fenix

uname -r | grep x86_64
RET=$?
if [ $RET -eq 0 ]; then
  ARCH=x86_64
fi

uname -r | grep -e arm64 -e tegra
RET=$?
if [ $RET -eq 0 ]; then
  ARCH=arm64
fi

#
# Step.1 Build container
#
if [ $ARCH == "arm64" ]; then
  sudo apt install -y qemu-user-static
  docker run --rm --privileged aptman/qus -- -r
  docker run --rm --privileged aptman/qus -s -- -p x86_64
fi

docker system prune -f 
docker build -t fenix_bld:latest .

if [ ! -d ${PWD}/fenix ]; then
  git clone -b v1.0.5 --depth 1 https://github.com/khadas/fenix.git
fi

#
# Step.2 start container
#
cd fenix
docker run -it --rm --name fenix \
    -v $(pwd):/home/khadas/fenix \
    --privileged \
    --device=/dev/loop-control:/dev/loop-control \
    --device=/dev/loop0:/dev/loop0 \
    --cap-add SYS_ADMIN \
    fenix_bld:latest