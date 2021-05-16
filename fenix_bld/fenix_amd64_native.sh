#!/bin/bash
#
# REFERENCE
# https://github.com/khadas/fenix
# git clone https://github.com/khadas/fenix
#
today=`date +%F_%H_%M`
WORK_DIR=${HOME}/work
if [ ! -d $WORK_DIR ]; then
  mkdir -p $WORK_DIR
fi

#
# git clone fenix env
#
cd $WORK_DIR
if [ ! -d $WORK_DIR/fenix ]; then
  git clone --depth 1 https://github.com/khadas/fenix
fi

#
# config and run
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
make -j`nproc` > $WORK_DIR/make_$today.log 2>&1
ccache -C