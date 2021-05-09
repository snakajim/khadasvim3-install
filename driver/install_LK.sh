#!/bin/bash
#
# Ubuntu linux kernel update(under construction)
#
LK=`uname -r | awk -F'.' '{printf $1"."$2}'`
WORK_DIR=/tmp/LK$LK
URL_BASE="https://kernel.ubuntu.com/~kernel-ppa/mainline/v"$LK"/arm64"

if [ ! -d ${WORK_DIR} ]; then
  mkdir -p ${WORK_DIR}
fi

#
# see man at 
# https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.12/
#
cd ${WORK_DIR}
if [ $LK == "5.12" ]; then
#aria2c -x4 $URL_BASE/linux-headers-5.12.0-051200-generic-64k_5.12.0-051200.202104252130_arm64.deb
aria2c -x4 $URL_BASE/linux-headers-5.12.0-051200-generic_5.12.0-051200.202104252130_arm64.deb
#aria2c -x4 $URL_BASE/linux-image-unsigned-5.12.0-051200-generic-64k_5.12.0-051200.202104252130_arm64.deb
aria2c -x4 $URL_BASE/linux-image-unsigned-5.12.0-051200-generic_5.12.0-051200.202104252130_arm64.deb
#aria2c -x4 $URL_BASE/linux-modules-5.12.0-051200-generic-64k_5.12.0-051200.202104252130_arm64.deb
aria2c -x4 $URL_BASE/linux-modules-5.12.0-051200-generic_5.12.0-051200.202104252130_arm64.deb
fi

if [ $LK == "4.9" ]; then
aria2c -x4 $URL_BASE/linux-headers-4.9.0-040900_4.9.0-040900.201612111631_all.deb
aria2c -x4 $URL_BASE/linux-headers-4.9.0-040900-generic_4.9.0-040900.201612111631_arm64.deb
aria2c -x4 $URL_BASE/linux-image-4.9.0-040900-generic_4.9.0-040900.201612111631_arm64.deb
fi


#
# install all *.deb
#
sudo dpkg -i *.deb

#
# You have minfmt__misc.ko under 
# /lib/modules/5.12.0-051200-generic/kernel/fs
#
