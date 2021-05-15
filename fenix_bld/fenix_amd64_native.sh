#!/bin/bash
#
# REFERENCE
# https://github.com/khadas/fenix
# git clone https://github.com/khadas/fenix
#
today=`date +%F_%H_%M`
mkdir -p ${HOME}/work
cd ${HOME}/work
if [ ! -d ${HOME}/work/fenix ]; then
  git clone --depth 1 https://github.com/khadas/fenix
fi
cd ${HOME}/work/fenix
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
make -j`nproc` > ${HOME}/work/make_$today.log 2>&1 &