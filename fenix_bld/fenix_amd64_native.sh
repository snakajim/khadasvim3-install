#!/bin/bash
#
# REFERENCE
# https://github.com/khadas/fenix
# git clone https://github.com/khadas/fenix
#


#
# This script is only for focal_amd64
#
cat /etc/lsb-release | grep focal
RET=$?

if [ $? -eq 1 ]; then
  echo "You need to choose Ubuntu 20.04(focal) for the host machine."
  echo "Program exit."
  sleep 10
  exit
fi

uname -a | grep x86_64
RET=$?

if [ $? -eq 1 ]; then
  echo "You need to choose x86_64(amd64) for the host machine."
  echo "Program exit."
  sleep 10
  exit
else
  sudo apt -y update && sudo apt -y upgrade
  sudo apt-get -y install git make lsb-release qemu-user-static build-essential
fi

#
# start script
#
today=`date +%F_%H_%M`
WORK_DIR=${HOME}/work3
if [ ! -d $WORK_DIR ]; then
  mkdir -p $WORK_DIR
fi

#
# git clone fenix env
#
cd $WORK_DIR
if [ ! -d $WORK_DIR/fenix ]; then
  git clone --depth 1 https://github.com/khadas/fenix
  cd $WORK_DIR/fenix
else
  cd $WORK_DIR/fenix
  make clean
  ccache -C  
fi

#
# config and run in background
#
cd $WORK_DIR/fenix
#sed -i -e "s/KHADAS_BOARD=VIM1/KHADAS_BOARD=VIM3/" config-template.conf
source env/setenv.sh -q -s  \
  KHADAS_BOARD=VIM3 \
  LINUX=4.9 \
  UBOOT=2015.01 \
  DISTRIBUTION=Ubuntu \
  DISTRIB_RELEASE=focal \
  DISTRIB_TYPE=server \
  DISTRIB_ARCH=arm64 \
  INSTALL_TYPE=EMMC \
  COMPRESS_IMAGE=no \
  INSTALL_TYPE_RAW=yes
# patch in PCIe source?
# https://forum.khadas.com/t/vim3-ubuntu-kernel-pcie-driver-not-load/6070/7
nohup make -j`nproc` > $WORK_DIR/make_$today.log 2>&1 &

echo -n "Process monitor: make -j`nproc` is running with nohup."

while : 
  do
    ps aux | grep -E -q "make -j`nproc`$"
    RET=$?
    if [ $RET -eq 1 ]; then
      echo "make -j`nproc` is completed."
      break
    else
      sleep 30
      echo -n "."
    fi
  done

echo "fenix_amd64_native.sh script done."