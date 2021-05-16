#!/bin/bash
#
# KHADAS VIM3 Image build script. 
#
# REFERENCE
# https://github.com/khadas/fenix
# git clone https://github.com/khadas/fenix
#
# SYNOPSYS
# Build Ubuntu Focal LK4.9 server img with PCI-e enable patch.
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

#
# patch in kvim3_linux.dts &pcie_A.
# https://forum.khadas.com/t/vim3-ubuntu-kernel-pcie-driver-not-load/6070/7
# ./build/linux/arch/arm64/boot/dts/amlogic/kvim3_linux.dts
#
if [ -f $WORK_DIR/fenix/build/linux/arch/arm64/boot/dts/amlogic/kvim3_linux.dts ]; then
  sed -i -e '1398 s/status = "disabled"/status = "okay"/' \
    $WORK_DIR/fenix/build/linux/arch/arm64/boot/dts/amlogic/kvim3_linux.dts
  echo ""
  echo "##################################"
  echo "Applying patch at $WORK_DIR/fenix/build/linux/arch/arm64/boot/dts/amlogic/kvim3_linux.dts"
  echo "before running make."
  echo "This is for enable PCIe M2."
  echo ""
  sed -n 1396,1400p $WORK_DIR/fenix/build/linux/arch/arm64/boot/dts/amlogic/kvim3_linux.dts
  echo ""
  echo "##################################"
  echo ""
else
  echo ""
  echo "File $WORK_DIR/fenix/build/linux/arch/arm64/boot/dts/amlogic/kvim3_linux.dts does not exit."
  echo "Program exit."
  exit
fi

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
echo ""
echo "see image under $WORK_DIR/fenix/build/images"
echo "fenix_amd64_native.sh script done."